// Copyright © Aptos Foundation
// SPDX-License-Identifier: Apache-2.0

//! The ability processor checks conformance to Move's ability system as well as transforms
//! the bytecode inserting ability related operations of copy and drop.
//!
//! The transformation does the following:
//!
//! - It infers the `AssignKind` in the assign statement. This will be `Move` if
//!   the source is not used after the assignment and is not borrowed. It will
//!   be Copy otherwise.
//! - It inserts a `Copy` assignment for every function argument which is used later or borrowed
//!   (same condition as above)
//! - It inserts a `Drop` instruction for values which go out of scope and are not
//!   consumed by any call and no longer borrowed.
//!
//! For the checking part, consider the transformation to have happened,
//! then:
//!
//! - Every copied value must have the `copy` ability
//! - Every dropped value must have the `drop` ability
//! - Every type used in storage operations must have the `key` ability (TODO(#12036): this check should
//!   go the the frontend where also `store` is checked)
//! - All type instantiations in the program must satisfy ability constraints (TODO: also frontend)
//!
//! Precondition: LiveVarAnnotation, LifetimeAnnotation, ExitStateAnnotation

use crate::pipeline::{
    exit_state_analysis::ExitStateAnnotation, livevar_analysis_processor::LiveVarAnnotation,
    reference_safety_processor::LifetimeAnnotation,
};
use abstract_domain_derive::AbstractDomain;
use codespan_reporting::diagnostic::Severity;
use move_binary_format::file_format::{Ability, AbilitySet, CodeOffset};
use move_model::{
    ast::TempIndex,
    exp_generator::ExpGenerator,
    model::{FunId, FunctionEnv, GlobalEnv, Loc, ModuleId, StructId, TypeParameterKind},
    ty,
    ty::{gen_get_ty_param_kinds, Type},
};
use move_stackless_bytecode::{
    dataflow_analysis::{DataflowAnalysis, TransferFunctions},
    dataflow_domains::{AbstractDomain, JoinResult, SetDomain},
    function_data_builder::FunctionDataBuilder,
    function_target::{FunctionData, FunctionTarget},
    function_target_pipeline::{FunctionTargetProcessor, FunctionTargetsHolder},
    stackless_bytecode::{AssignKind, AttrId, Bytecode, Operation},
    stackless_control_flow_graph::StacklessControlFlowGraph,
};
use std::{collections::BTreeMap, iter};

// =================================================================================================
// Processor

pub struct AbilityProcessor {}

impl FunctionTargetProcessor for AbilityProcessor {
    /// Processing happens in two steps:
    /// 1. Run a dataflow analysis to compute, for each program point, which copies are inserted before this
    ///    point and drops after. Moreover, the analysis computes which values have been _moved_.
    /// 2. Based on the former analysis, transform the code to insert copies and drops, while checking
    ///    ability conformance.
    fn process(
        &self,
        _targets: &mut FunctionTargetsHolder,
        fun_env: &FunctionEnv,
        mut data: FunctionData,
        _scc_opt: Option<&[FunctionEnv]>,
    ) -> FunctionData {
        if fun_env.is_native() {
            return data;
        }

        let code = std::mem::take(&mut data.code);
        let mut builder = FunctionDataBuilder::new(fun_env, data);

        // Extract annotations for live-var and lifetime. Those are also cleared
        // as they are not valid any longer after this processor has run.
        let live_var = &*builder
            .get_annotations_mut()
            .remove::<LiveVarAnnotation>()
            .expect("livevar annotation");
        let lifetime = &*builder
            .get_annotations_mut()
            .remove::<LifetimeAnnotation>()
            .expect("lifetime annotation");
        let exit_state = &*builder
            .get_annotations_mut()
            .remove::<ExitStateAnnotation>()
            .expect("exit state annotation");

        // Run copy-drop analysis
        let cfg = StacklessControlFlowGraph::new_forward(&code);
        let target = &builder.get_target();
        let analyzer = CopyDropAnalysis {
            target,
            live_var,
            lifetime,
            exit_state,
        };
        let state_map = analyzer.analyze_function(CopyDropState::default(), &code, &cfg);
        let copy_drop =
            analyzer.state_per_instruction_with_default(state_map, &code, &cfg, |_, after| {
                after.clone()
            });

        // Run transformation
        let mut transformer = Transformer {
            builder,
            live_var,
            lifetime,
            copy_drop,
        };
        transformer.run(code);
        transformer.builder.data
    }

    fn name(&self) -> String {
        "AbilityProcessor".to_owned()
    }
}

// =================================================================================================
// Copy/Drop Analysis

#[derive(AbstractDomain, Debug, Clone, Default)]
struct CopyDropState {
    /// Those temps which need to be copied before this program point.
    needs_copy: SetDomain<TempIndex>,
    /// Those temps which need to be dropped after this program point.
    needs_drop: SetDomain<TempIndex>,
    /// Those temps which are consumed by the instruction but need to be checked for the drop ability
    /// since they internally drop the value. These are currently equalities.
    check_drop: SetDomain<TempIndex>,
    /// Those temps which have been moved (that is consumed).
    moved: SetDomain<TempIndex>,
}

struct CopyDropAnalysis<'a> {
    target: &'a FunctionTarget<'a>,
    live_var: &'a LiveVarAnnotation,
    lifetime: &'a LifetimeAnnotation,
    exit_state: &'a ExitStateAnnotation,
}

impl<'a> DataflowAnalysis for CopyDropAnalysis<'a> {}

impl<'a> TransferFunctions for CopyDropAnalysis<'a> {
    type State = CopyDropState;

    const BACKWARD: bool = false;

    fn execute(&self, state: &mut Self::State, instr: &Bytecode, offset: CodeOffset) {
        use Bytecode::*;
        // Clear local state info
        state.needs_copy.clear();
        state.needs_drop.clear();
        let live_var = self.live_var.get_info_at(offset);
        let lifetime = self.lifetime.get_info_at(offset);
        let exit_state = self.exit_state.get_state_at(offset);
        // Only non-primitive types need a copy
        let type_needs_copy = |temp: &TempIndex| {
            let ty = self.target.get_local_type(*temp);
            !ty.is_primitive()
        };
        // Only temps which are used after or borrowed need a copy
        let temp_needs_copy =
            |temp| live_var.after.contains_key(temp) || lifetime.before.is_borrowed(*temp);
        // References always need to be dropped to satisfy bytecode verifier borrow analysis, other values
        // only if this execution path can return.
        let temp_needs_drop = |temp: &TempIndex| {
            self.target.get_local_type(*temp).is_reference() || exit_state.may_return()
        };
        match instr {
            Assign(_, _, src, AssignKind::Inferred) => {
                if temp_needs_copy(src) {
                    state.needs_copy.insert(*src);
                } else {
                    state.moved.insert(*src);
                }
            },
            Assign(_, _, src, AssignKind::Move) => {
                state.moved.insert(*src);
            },
            Call(_, _, Operation::BorrowLoc, _, _) => {
                // Operation does not consume operands.
            },
            Call(_, _, op, srcs, ..) => {
                // If this is an equality we need to check drop for the operands, even though we do not need
                // to emit a drop.
                if matches!(op, Operation::Eq | Operation::Neq) {
                    state.check_drop.extend(srcs.iter().cloned())
                }
                // For arguments, we also need to check the case that a src, even if not used after this program
                // point, is again used in the argument list. Also, in difference to assign inference, we only need
                // to copy the argument if its not primitive.
                for (i, src) in srcs.iter().enumerate() {
                    if (temp_needs_copy(src) || srcs[i + 1..].contains(src)) && type_needs_copy(src)
                    {
                        state.needs_copy.insert(*src);
                    } else {
                        state.moved.insert(*src);
                    }
                }
            },
            Ret(_, srcs) => state.moved.extend(srcs.iter().cloned()),
            _ => {},
        }

        // Clear information about re-assigned locals
        let dests = instr.dests();
        for dest in dests {
            state.moved.remove(&dest);
        }

        // Now drop any temps which are released. Only need to do this for non-branching instructions, because
        // there is no code executed 'after' the branch.
        if !instr.is_always_branching() {
            for temp in live_var.released_and_unused_temps(instr) {
                if !state.moved.contains(&temp) && temp_needs_drop(&temp) {
                    state.needs_drop.insert(temp);
                    state.moved.insert(temp);
                }
            }
        }
    }
}

// =================================================================================================
// Transformation

/// Represents run for one function.
struct Transformer<'a> {
    /// A function data builder which owns the `FunctionData` which is worked on.
    builder: FunctionDataBuilder<'a>,
    /// The live-var information for the function.
    live_var: &'a LiveVarAnnotation,
    /// The live-var information for the function.
    lifetime: &'a LifetimeAnnotation,
    /// The result of the copy-drop analysis
    copy_drop: BTreeMap<CodeOffset, CopyDropState>,
}

impl<'a> Transformer<'a> {
    fn run(&mut self, code: Vec<Bytecode>) {
        for (offset, bc) in code.into_iter().enumerate() {
            self.transform_bytecode(offset as CodeOffset, bc)
        }
    }

    /// Transforms and checks a bytecode. See the file documentation for an overview
    /// of what this function does.
    fn transform_bytecode(&mut self, code_offset: CodeOffset, bc: Bytecode) {
        use Bytecode::*;
        // Transform and check bytecode
        match bc.clone() {
            Assign(id, dst, src, kind) => match kind {
                AssignKind::Inferred => {
                    let copy_drop_at = self.copy_drop.get(&code_offset).expect("copy_drop");
                    if copy_drop_at.needs_copy.contains(&src) {
                        self.check_implicit_copy(code_offset, id, src);
                        self.builder.emit(Assign(id, dst, src, AssignKind::Copy))
                    } else {
                        self.builder.emit(Assign(id, dst, src, AssignKind::Move))
                    }
                },
                AssignKind::Copy | AssignKind::Store => {
                    self.check_explicit_copy(id, src);
                    self.builder.emit(Assign(id, dst, src, AssignKind::Copy))
                },
                AssignKind::Move => {
                    self.check_explicit_move(code_offset, id, src);
                    self.builder.emit(Assign(id, dst, src, AssignKind::Move))
                },
            },
            Call(id, dests, op, srcs, ai) => {
                use Operation::*;
                match &op {
                    Function(mod_id, fun_id, insts) => {
                        self.check_fun_inst(id, *mod_id, *fun_id, insts);
                        let new_srcs = self.copy_args_if_needed(code_offset, id, srcs);
                        self.check_and_emit_bytecode(code_offset, Call(id, dests, op, new_srcs, ai))
                    },
                    _ => self.check_and_emit_bytecode(code_offset, bc.clone()),
                }
            },
            _ => self.check_and_emit_bytecode(code_offset, bc.clone()),
        }
        // Insert/check any drops needed after this program point
        self.check_and_add_implicit_drops(code_offset, &bc)
    }

    fn check_and_emit_bytecode(&mut self, _code_offset: CodeOffset, bc: Bytecode) {
        use Bytecode::*;
        #[allow(clippy::single_match)] // For handling of future cases
        match &bc {
            Call(id, _, op, srcs, _) => {
                use Operation::*;
                match &op {
                    Function(mod_id, fun_id, insts) => {
                        self.check_fun_inst(*id, *mod_id, *fun_id, insts);
                    },
                    Unpack(mod_id, struct_id, insts) | Pack(mod_id, struct_id, insts) => {
                        self.check_struct_inst(*id, *mod_id, *struct_id, insts);
                    },
                    BorrowGlobal(mod_id, struct_id, insts)
                    | Exists(mod_id, struct_id, insts)
                    | MoveFrom(mod_id, struct_id, insts)
                    | MoveTo(mod_id, struct_id, insts) => {
                        self.check_key_for_struct(*id, *mod_id, *struct_id, insts)
                    },
                    Drop => self.check_drop(*id, srcs[0], || {
                        ("explicitly dropped here".to_string(), vec![])
                    }),
                    ReadRef => {
                        let ty = self.builder.get_local_type(srcs[0]);
                        self.check_copy_for_type(
                            *id,
                            srcs[0],
                            ty.get_target_type().expect("reference type"),
                            || ("reference content copied here".to_string(), vec![]),
                        );
                    },
                    WriteRef => {
                        let ty = self.builder.get_local_type(srcs[0]);
                        self.check_drop_for_type(
                            *id,
                            srcs[0],
                            ty.get_target_type().expect("reference type"),
                            || ("reference content dropped here".to_string(), vec![]),
                        );
                    },
                    _ => (),
                }
            },
            _ => {},
        }
        self.builder.emit(bc)
    }
}

// ---------------------------------------------------------------------------------------------------------
// Copy and Move

impl<'a> Transformer<'a> {
    fn check_implicit_copy(&self, code_offset: CodeOffset, id: AttrId, src: TempIndex) {
        self.check_copy(id, src, || {
            (
                "copy needed here because value is still in use".to_string(),
                self.make_hints_from_usage(code_offset, src),
            )
        });
    }

    fn check_explicit_copy(&self, id: AttrId, src: TempIndex) {
        self.check_copy(id, src, || ("explicitly copied here".to_string(), vec![]));
    }

    /// Walks over the argument list and inserts copies if needed.
    fn copy_args_if_needed(
        &mut self,
        code_offset: CodeOffset,
        id: AttrId,
        srcs: Vec<TempIndex>,
    ) -> Vec<TempIndex> {
        use Bytecode::*;
        let copy_drop_at = self.copy_drop.get(&code_offset).expect("copy drop");
        let mut new_srcs = vec![];
        for src in srcs.iter() {
            if copy_drop_at.needs_copy.contains(src) {
                self.check_implicit_copy(code_offset, id, *src);
                let ty = self.builder.get_local_type(*src);
                let temp = self.builder.new_temp(ty);
                self.builder.emit(Assign(id, temp, *src, AssignKind::Copy));
                new_srcs.push(temp)
            } else {
                new_srcs.push(*src)
            }
        }
        new_srcs
    }

    /// Checks whether the given temp has copy ability, add diagnostics if not
    fn check_copy(&self, id: AttrId, temp: TempIndex, describe: impl FnOnce() -> Description) {
        self.check_copy_for_type(id, temp, &self.ty(temp), describe)
    }

    /// Checks whether the given temp wrt type has copy ability, add diagnostics if not
    fn check_copy_for_type(
        &self,
        id: AttrId,
        temp: TempIndex,
        ty: &Type,
        describe: impl FnOnce() -> Description,
    ) {
        self.check_ability_for_type(id, Some(temp), ty, Ability::Copy, describe)
    }

    /// Checks whether an explicit move is allowed.
    fn check_explicit_move(&self, code_offset: CodeOffset, id: AttrId, temp: TempIndex) {
        let alive = self.live_var.get_info_at(code_offset);
        if alive.after.contains_key(&temp) {
            let target = self.builder.get_target();
            self.error_with_hints(
                target.get_bytecode_loc(id),
                format!(
                    "cannot move {} since it is still in use",
                    target.get_local_name_for_error_message(temp)
                ),
                "attempted to move here",
                self.make_hints_from_usage(code_offset, temp).into_iter(),
            );
        }
    }
}

// ---------------------------------------------------------------------------------------------------------
// Drop

impl<'a> Transformer<'a> {
    /// Add implicit drops at the given code offset.
    fn check_and_add_implicit_drops(&mut self, code_offset: CodeOffset, bytecode: &Bytecode) {
        // No drop after terminators
        if !bytecode.is_always_branching() {
            let copy_drop_at = self.copy_drop.get(&code_offset).expect("copy_drop");
            let id = bytecode.get_attr_id();
            for temp in copy_drop_at.check_drop.iter() {
                self.check_drop(bytecode.get_attr_id(), *temp, || {
                    (
                        "operator drops value here (consider to borrow the argument)".to_string(),
                        vec![],
                    )
                });
            }
            for temp in copy_drop_at.needs_drop.iter() {
                // Give a better error message if we know its borrowed
                let is_borrowed = self
                    .lifetime
                    .get_info_at(code_offset)
                    .after
                    .is_borrowed(*temp);
                self.check_drop(bytecode.get_attr_id(), *temp, || {
                    (
                        if is_borrowed {
                            "still borrowed but will be implicitly \
                            dropped later since it is no longer used"
                                .to_string()
                        } else {
                            "implicitly dropped here since it is \
                            no longer used"
                                .to_string()
                        },
                        vec![],
                    )
                });
                // Only for references we need to generate a Drop instruction

                if self.ty(*temp).is_reference() {
                    self.builder.emit(Bytecode::Call(
                        id,
                        vec![],
                        Operation::Drop,
                        vec![*temp],
                        None,
                    ));
                }
            }
        }
    }

    fn check_drop(&self, id: AttrId, temp: TempIndex, describe: impl FnOnce() -> Description) {
        self.check_ability_for_type(id, Some(temp), &self.ty(temp), Ability::Drop, describe)
    }

    fn check_drop_for_type(
        &self,
        id: AttrId,
        temp: TempIndex,
        ty: &Type,
        describe: impl FnOnce() -> Description,
    ) {
        self.check_ability_for_type(id, Some(temp), ty, Ability::Drop, describe)
    }
}

// ---------------------------------------------------------------------------------------------------------
// Abilities in Types

// TODO(#12036): this functionality should be moved to the frontend

impl<'a> Transformer<'a> {
    /// Check whether a function has a valid type instantiation.
    fn check_fun_inst(&self, id: AttrId, mid: ModuleId, fid: FunId, inst: &[Type]) {
        let ty_params = self.builder.fun_env.get_type_parameters();
        let fun_env = self.env().get_function(mid.qualified(fid));
        let err_handler = |loc: &Loc, ty: &Type, msg: &str| {
            self.error(
                loc,
                format!("type `{}` is {}", self.display_ty(ty), msg),
                format!(
                    "in instantiation of function `{}` here",
                    fun_env.get_full_name_str()
                ),
            )
        };
        let loc = self.loc(id);
        for (param, ty) in fun_env.get_type_parameters().iter().zip(inst.iter()) {
            let required_abilities = param.1.abilities;
            let given_abilities = ty::infer_and_check_abilities(
                ty,
                gen_get_ty_param_kinds(&ty_params),
                self.gen_get_struct_sig(),
                &loc,
                err_handler,
            );
            ty::check_type_arg_abilities(
                ty::gen_get_ty_param_kinds(&ty_params),
                ty,
                required_abilities,
                false,
                given_abilities,
                &loc,
                err_handler,
            )
        }
    }

    /// Check whether a struct has a valid type instantiation.
    fn check_struct_inst(
        &self,
        id: AttrId,
        mid: ModuleId,
        sid: StructId,
        inst: &[Type],
    ) -> AbilitySet {
        let ty_params = self.builder.fun_env.get_type_parameters();
        let struct_env = self.env().get_struct(mid.qualified(sid));
        ty::check_struct_inst(
            mid,
            sid,
            inst,
            ty::gen_get_ty_param_kinds(&ty_params),
            self.gen_get_struct_sig(),
            Some((&self.loc(id), |loc: &Loc, ty: &Type, msg: &str| {
                self.error(
                    loc,
                    format!("type `{}` is {}", self.display_ty(ty), msg),
                    format!(
                        "in instantiation of struct `{}` here",
                        struct_env.get_full_name_str()
                    ),
                )
            })),
        )
    }

    /// Check whether a struct has a valid type instantiation and has the `key` ability.
    fn check_key_for_struct(&self, id: AttrId, mid: ModuleId, sid: StructId, inst: &[Type]) {
        self.check_struct_inst(id, mid, sid, inst);
        let ty = mid.qualified_inst(sid, inst.to_vec()).to_type();
        self.check_ability_for_type(id, None, &ty, Ability::Key, || {
            (
                "required because of storage operation here".to_string(),
                vec![],
            )
        })
    }

    /// Generates a function that given module id and struct id, returns the struct signature
    /// as it is expected by the ability functions in `ty`.
    fn gen_get_struct_sig(
        &'a self,
    ) -> impl Fn(ModuleId, StructId) -> (Vec<TypeParameterKind>, AbilitySet) + Copy + 'a {
        self.env().gen_get_struct_sig()
    }
}

// ---------------------------------------------------------------------------------------------------------
// Helpers

/// A description for an error. The 1st string is used as the secondary message (the one printed
/// at the arrow to the location), the 2nd vector is a list of location-based additional hints.
type Description = (String, Vec<(Loc, String)>);

impl<'a> Transformer<'a> {
    /// Checks whether the type as the ability and if not reports an error. An optional temp is
    /// provided in the case the type is associated with a value. A function to describe
    /// the reason and possible a list of hints is provided as well.
    fn check_ability_for_type(
        &self,
        id: AttrId,
        temp: Option<TempIndex>,
        ty: &Type,
        ability: Ability,
        describe: impl FnOnce() -> Description,
    ) {
        if !self.has_ability(ty, ability) {
            let (message, hints) = describe();
            self.error_with_hints(
                self.loc(id),
                format!(
                    "{}type `{}` does not have the `{}` ability",
                    if let Some(t) = temp {
                        format!("{} of ", self.display_temp(t))
                    } else {
                        "".to_string()
                    },
                    self.display_ty(ty),
                    ability
                ),
                message,
                hints.into_iter(),
            )
        }
    }

    /// Gets the global env.
    fn env(&self) -> &GlobalEnv {
        self.builder.global_env()
    }

    /// Gets the type of a local.
    fn ty(&self, temp: TempIndex) -> Type {
        self.builder.get_local_type(temp)
    }

    /// Gets the location associated with an attribute id
    fn loc(&self, id: AttrId) -> Loc {
        self.builder.get_loc(id)
    }

    /// Determines if the given type has the given ability
    fn has_ability(&self, ty: &Type, ability: Ability) -> bool {
        let target = self.builder.get_target();
        let ty_params = target.get_type_parameters();
        self.env()
            .type_abilities(ty, &ty_params)
            .has_ability(ability)
    }

    /// Produces an error with primary message and secondary hints.
    fn error_with_hints(
        &self,
        loc: impl AsRef<Loc>,
        msg: impl AsRef<str>,
        primary: impl AsRef<str>,
        hints: impl Iterator<Item = (Loc, String)>,
    ) {
        self.env().diag_with_primary_and_labels(
            Severity::Error,
            loc.as_ref(),
            msg.as_ref(),
            primary.as_ref(),
            hints.collect(),
        )
    }

    /// Shortcut if hints are empty
    fn error(&self, loc: impl AsRef<Loc>, msg: impl AsRef<str>, primary: impl AsRef<str>) {
        self.error_with_hints(loc, msg, primary, iter::empty())
    }

    /// Create a display string for temps. If the temp is printable, this will be 'local `x`'. Otherwise
    /// it will be just 'local'.
    fn display_temp(&self, temp: TempIndex) -> String {
        self.builder
            .get_target()
            .get_local_name_for_error_message(temp)
    }

    /// Creates a display string for a type.
    fn display_ty(&self, ty: &Type) -> String {
        ty.display(&self.builder.fun_env.get_type_display_ctx())
            .to_string()
    }

    /// Creates a list of hints where a temporary is used after this code point.
    fn make_hints_from_usage(
        &self,
        code_offset: CodeOffset,
        temp: TempIndex,
    ) -> Vec<(Loc, String)> {
        if let Some(info) = self.live_var.get_info_at(code_offset).after.get(&temp) {
            info.usages
                .iter()
                .map(|loc| (loc.clone(), "used here".to_owned()))
                .collect()
        } else {
            vec![]
        }
    }
}
