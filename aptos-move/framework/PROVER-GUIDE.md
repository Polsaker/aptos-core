This guide collects links to the prover documents and gives some hints to troubleshoot issues when using the prover. 

## Installation

Please refer to the [doc](https://aptos.dev/cli-tools/install-move-prover/).

## Specification 

The specification for Move contracts are written in the Move Specification Language. 
Please refer to this [doc](https://github.com/aptos-labs/aptos-core/blob/main/third_party/move/move-prover/doc/user/spec-lang.md) 
for detailed introduction.

## Troubleshooting

### Internal errors

Bugs in the prover often lead to `boogie internal errors`. When it happens, you could try to locate the specs that causes this issue and comment them out. 
If the error is caused by the Move code, e.g., `foo.move`, You could add the following code in `foo.spec.move` (create one if it does not exist):

```move
spec module {
   pragma verify = false;
}
```

After making these changes, please submit a Github issue for the prover team to fix. 

### Timeout

When the prover cannot finish the verification job within a specified time (by default 40s), it will exit and generate an error message.
In this case, users should add a pragma `pragma verify = false` to the specification
that causes the timeout with a comment `TODO: set to false because of timeout` for the prover developer to debug. The prover team will look into 
timeout issues later.

### Disabling prover tests

Prover tests are land-blockers for PRs which change the Move code and/or specifications in the `framework` directory. To disable them locally for efficiency,
you could use the command `cargo test --release -p aptos-framework -- --skip prover`.