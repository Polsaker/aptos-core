/// This module defines marker types, constants and test cases for working with BLS12-381 curves
/// using generic API defined in `algebra.move`.
///
/// Below are the BLS12-381 structures currently supported.
/// - Field `Fq12`.
/// - Group `G1Affine`.
/// - Group `G2Affine`.
/// - Group `Gt`.
/// - Field `Fr`.
module aptos_std::algebra_bls12381 {
    // Marker types (and their serialization schemes) begin.

    /// The finite field $F_q$ used in BLS12-381 curves.
    /// It has a prime order $q$ equal to 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab.
    ///
    /// NOTE: currently information-only and no operations are implemented for this structure.
    struct Fq {}

    /// A serialization format for `Fq` elements,
    /// where an element is represented by a byte array `b[]` of size 48 with the least signature byte coming first.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381fq_lsb(): vector<u8> { x"01" }

    /// A serialization format for `Fq` elements,
    /// where an element is represented by a byte array `b[]` of size 48 with the most significant byte coming first.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381fq_msb(): vector<u8> { x"0101" }

    /// The finite field $F_{q^2}$ used in BLS12-381 curves.
    /// It is an extension field of `Fq`, constructed as $F_{q^2}=F_q[u]/(u^2+1)$.
    ///
    /// NOTE: currently information-only and no operations are implemented for this structure.
    struct Fq2 {}

    /// A serialization format for `Fq2` elements.
    /// where an element in the form $(c_0+c_1\cdot u)$ is represented by a byte array `b[]` of size 96
    /// with the following rules.
    /// - `b[0..48]` is $c_0$ serialized using `format_bls12381fq_lsb()`.
    /// - `b[48..96]` is $c_1$ serialized using `format_bls12381fq_lsb()`.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381fq2_lsc_lsb(): vector<u8> { x"02" }

    /// A serialization format for `Fq2` elements,
    /// where an element in the form $(c_1\cdot u+c_0)$ is represented by a byte array `b[]` of size 96,
    /// with the following rules.
    /// - `b[0..48]` is $c_1$ serialized using `format_bls12381fq_msb()`.
    /// - `b[48..96]` is $c_0$ serialized using `format_bls12381fq_msb()`.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381fq2_msc_msb(): vector<u8> { x"0201" }

    /// The finite field $F_{q^6}$ used in BLS12-381 curves.
    /// It is an extension field of `Fq2`, constructed as $F_{q^6}=F_{q^2}[v]/(v^3-u-1)$.
    ///
    /// NOTE: currently information-only and no operations are implemented for this structure.
    struct Fq6 {}

    /// A serialization scheme for `Fq6` elements,
    /// where an element $(c_0+c_1\cdot v+c_2\cdot v^2)$ is represented by a byte array `b[]` of size 288,
    /// with the following rules.
    /// - `b[0..96]` is $c_0$ serialized using `format_bls12381fq2_lsc_lsb()`.
    /// - `b[96..192]` is $c_1$ serialized using `format_bls12381fq2_lsc_lsb()`.
    /// - `b[192..288]` is $c_2$ serialized using `format_bls12381fq2_lsc_lsb()`.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381fq6_lsc_lsc_lsb(): vector<u8> { x"03" }

    /// The finite field $F_{q^12}$ used in BLS12-381 curves.
    /// It is an extension field of `Fq6`, constructed as $F_{q^12}=F_{q^6}[w]/(w^2-v)$.
    struct Fq12 {}

    /// A serialization scheme for `Fq12` elements,
    /// where an element $(c_0+c_1\cdot w)$ is represented by a byte array `b[]` of size 576.
    /// `b[0..288]` is $c_0$ serialized using `format_bls12381fq6_lsc_lsc_lsb()`.
    /// `b[288..576]` is $c_1$ serialized using `format_bls12381fq6_lsc_lsc_lsb()`.
    ///
    /// NOTE: the same scheme is also used in other implementations (e.g. ark-bls12-381-0.4.0).
    public fun format_bls12381fq12_lsc_lsc_lsc_lsb(): vector<u8> { x"04" }

    /// A group constructed by the points on the BLS12-381 curve $E(F_q): y^2=x^3+4$ and the point at inifinity,
    /// under the elliptic curve point addition.
    /// It contains the prime-order subgroup $G_1$ used in pairing.
    /// The identity is the point at infinity.
    ///
    /// NOTE: currently information-only and no operations are implemented for this structure.
    struct G1AffineParent {}

    /// A serialization scheme for `G1AffineParent` elements,
    /// where an element is represented by a byte array `b[]` of size 96,
    /// with the following rules deseribed from the perspective of deserialization.
    /// 1. Read `b[0] & 0x80` as the compression flag. Abort if it is 1.
    /// 1. Read `b[0] & 0x40` as the infinity flag.
    /// 1. Read `b[0] & 0x20` as the lexicographical flag. This is ignored.
    /// 1. If the infinity flag is 1, return the point at infinity.
    /// 1. Deserialize $x$ from `[b[0] & 0x1f, ..., b[47]]` using `format_bls12381fq_msb()`. Abort if this failed.
    /// 1. Deserialize $y$ from `[b[48], ..., b[95]]` using `format_bls12381fq_msb()`. Abort if this failed.
    /// 1. Abort if point $(x,y)$ is not on curve $E(F_q)$.
    /// 1. Return $(x,y)$.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381g1_affine_parent_uncompressed(): vector<u8> { x"05" }

    /// A serialization scheme for `G1AffineParent` elements,
    /// where an element is represented by a byte array `b[]` of size 48,
    /// with the following rules deseribed from the perspective of deserialization.
    /// 1. Read `b[0] & 0x80` as the compression flag. Abort if it is 0.
    /// 1. Read `b[0] & 0x40` as the infinity flag.
    /// 1. Read `b[0] & 0x20` as the lexicographical flag.
    /// 1. If the infinity flag is 1, return the point at infinity.
    /// 1. Deserialize $x$ from `[b[0] & 0x1f, ..., b[47]]` using `format_bls12381fq_msb()`. Abort if this failed.
    /// 1. Try computing $y$ such that point $(x,y)$ is on the curve $E(F_q)$. Abort if there is no such $y$.
    /// 1. Let $\overline{y}=-y$.
    /// 1. Set $y$ as $\min(y,\overline{y})$ if the the lexicographical flag is 0, or $\max(y,\overline{y})$ otherwise.
    /// 1. Return $(x,y)$.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381g1_affine_parent_compressed(): vector<u8> { x"0501" }

    /// The group $G_1$ in BLS12-381-based pairing $G_1 \times G_2 \rightarrow G_t$.
    /// It is subgroup of `G1AffineParent`.
    /// It has a prime order $r$ equal to 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001.
    /// (so `Fr` is the scalar field).
    struct G1Affine {}

    /// A serialization format for `G1Affine` elements,
    /// essentially the format represented by `format_bls12381g1_affine_parent_uncompressed()`
    /// but only applicable to `G1Affine` elements.
    ///
    /// NOTE: the same scheme is also used in other implementations (e.g. ark-bls12-381-0.4.0).
    public fun format_bls12381g1_affine_uncompressed(): vector<u8> { x"06" }

    /// A serialization format for `G1Affine` elements,
    /// essentially the format represented by `format_bls12381g1_affine_parent_compressed()`
    /// but only applicable to `G1Affine` elements.
    ///
    /// NOTE: the same scheme is also used in other implementations (e.g. ark-bls12-381-0.4.0).
    public fun format_bls12381g1_affine_compressed(): vector<u8> { x"0601" }

    /// A group constructed by the points on a curve $E'(F_{q^2})$ and the point at inifinity under the elliptic curve point addition.
    /// $E'(F_{q^2})$ is an elliptic curve $y^2=x^3+4(u+1)$ defined over $F_{q^2}$.
    /// The identity of `G2Affine` is the point at infinity.
    ///
    /// NOTE: currently information-only and no operations are implemented for this structure.
    struct G2AffineParent {}

    /// A serialization scheme for `G2AffineParent` elements.
    /// where an element is represented by a byte array `b[]` of size 192,
    /// with the following rules deseribed from the perspective of deserialization.
    /// 1. Read `b[0] & 0x80` as the compression flag. Abort if it is 1.
    /// 1. Read `b[0] & 0x40` as the infinity flag.
    /// 1. Read `b[0] & 0x20` as the lexicographical flag. This is ignored.
    /// 1. If the infinity flag is 1, return the point at infinity.
    /// 1. Deserialize $x$ from `[b[0] & 0x1f, ..., b[95]]` using `format_bls12381fq2_msc_msb()`. Abort if this failed.
    /// 1. Deserialize $y$ from `[b[96], ..., b[191]]` using `format_bls12381fq2_msc_msb()`. Abort if this failed.
    /// 1. Abort if point $(x,y)$ is not on curve $E'(F_{q^2})$.
    /// 1. Return $(x,y)$.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381g2_affine_parent_uncompressed(): vector<u8> { x"07" }

    /// A serialization scheme for `G1AffineParent` elements,
    /// where an element is represented by a byte array `b[]` of size 96,
    /// with the following rules deseribed from the perspective of deserialization.
    /// 1. Read `b[0] & 0x80` as the compression flag. Abort if it is 0.
    /// 1. Read `b[0] & 0x40` as the infinity flag.
    /// 1. Read `b[0] & 0x20` as the lexicographical flag.
    /// 1. If the infinity flag is 1, return the point at infinity.
    /// 1. Deserialize $x$ from `[b[0] & 0x1f, ..., b[96]]` using `format_bls12381fq2_msc_msb()`. Abort if this failed.
    /// 1. Try computing $y$ such that point $(x,y)$ is on the curve $E(F_{q^2})$. Abort if there is no such $y$.
    /// 1. Let $\overline{y}=-y$.
    /// 1. Set $y$ as $\min(y,\overline{y})$ if the the lexicographical flag is 0, or $\max(y,\overline{y})$ otherwise.
    /// 1. Return $(x,y)$.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381g2_affine_parent_compressed(): vector<u8> { x"0701" }

    /// The group $G_2$ in BLS12-381-based pairing $G_1 \times G_2 \rightarrow G_t$.
    /// It is a subgroup of `G2AffineParent`.
    /// It has a prime order $r$ equal to 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001.
    /// (so `Fr` is the scalar field).
    struct G2Affine {}

    /// A serialization scheme for `G2Affine` elements,
    /// essentially `format_bls12381g2_affine_parent_uncompressed()` but only applicable to `G2Affine` elements.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381g2_affine_uncompressed(): vector<u8> { x"08" }

    /// A serialization scheme for `G2Affine` elements,
    /// essentially `format_bls12381g2_affine_parent_compressed()` but only applicable to `G2Affine` elements.
    ///
    /// NOTE: currently information-only, not implemented.
    public fun format_bls12381g2_affine_compressed(): vector<u8> { x"0801" }

    /// The group $G_t$ in BLS12-381-based pairing $G_1 \times G_2 \rightarrow G_t$.
    /// It is a multiplicative subgroup of `Fq12`.
    /// It has a prime order $r$ equal to 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001.
    /// (so `Fr` is the scalar field).
    /// The identity of `Gt` is 1.
    struct Gt {}

    /// A serialization scheme for `Gt` elements,
    /// essentially `format_bls12381fq12_lsc_lsc_lsc_lsb()` but only applicable to `Gt` elements.
    ///
    /// NOTE: the same scheme is also used in other implementations (e.g. ark-bls12-381-0.4.0).
    public fun format_bls12381gt(): vector<u8> { x"09" }

    /// The finite field $F_r$ that can be used as the scalar fields
    /// for the groups $G_1$, $G_2$, $G_t$ in BLS12-381-based pairing.
    struct Fr {}

    /// A serialization scheme for `Fr` elements,
    /// where an element is represented by a byte array `b[]` of size 32 with the least significant byte coming first.
    ///
    /// NOTE: the same scheme is also used in other implementations (e.g., ark-bls12-381-0.4.0, blst-0.3.7).
    public fun format_bls12381fr_lsb(): vector<u8> { x"0a" }

    /// A serialization scheme for `Fr` elements,
    /// where an element is represented by a byte array `b[]` of size 32 with the most significant byte coming first.
    ///
    /// NOTE: the same scheme is also used in other implementations (e.g., ark-bls12-381-0.4.0, blst-0.3.7).
    public fun format_bls12381fr_msb(): vector<u8> { x"0a01" }

    // Marker types (and their serialization schemes) end.

    // Hash-to-structure suites begin.

    /// The hash-to-curve suite `BLS12381G1_XMD:SHA-256_SSWU_RO_`
    /// defined in https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-16#name-bls12-381-g1.
    public fun h2s_suite_bls12381g1_xmd_sha_256_sswu_ro(): vector<u8> { x"0001" }

    /// The hash-to-curve suite `BLS12381G2_XMD:SHA-256_SSWU_RO_`
    /// defined in https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-16#name-bls12-381-g2.
    public fun h2s_suite_bls12381g2_xmd_sha_256_sswu_ro(): vector<u8> { x"0002" }

    // Hash-to-structure suites end.

    // Private functions begin.

    #[test_only]
    fun enable_bls12_381_structures(fx: &signer) {
        std::features::change_feature_flags(fx, vector[std::features::get_bls12_381_strutures_feature()], vector[]);
    }

    // Private functions end.

    // Tests begin.
    #[test_only]
    const BLS12_381_FQ12_VAL_7_SERIALIZED: vector<u8> = x"070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    #[test_only]
    const BLS12_381_FQ12_VAL_7_NEG_SERIALIZED: vector<u8> = x"a4aafffffffffeb9ffff53b1feffab1e24f6b0f6a0d23067bf1285f3844b7764d7ac4b43b6a71b4b9ae67f39ea11011a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    #[test(fx = @std)]
    fun test_bls12_381_fq12(fx: signer) {
        enable_initial_generic_algebraic_operations(&fx);
        enable_bls12_381_structures(&fx);

        // Special elements and checks.
        let val_0 = field_zero<Fq12>();
        let val_1 = field_one<Fq12>();
        assert!(field_is_zero(&val_0), 1);
        assert!(!field_is_zero(&val_1), 1);
        assert!(!field_is_one(&val_0), 1);
        assert!(field_is_one(&val_1), 1);

        // Serialization/deserialization.
        let val_7 = from_u64<Fq12>(7);
        let val_7_another = std::option::extract(&mut deserialize<Fq12>(
            format_bls12381fq12_lsc_lsc_lsc_lsb(), &BLS12_381_FQ12_VAL_7_SERIALIZED));
        assert!(eq(&val_7, &val_7_another), 1);
        assert!(BLS12_381_FQ12_VAL_7_SERIALIZED == serialize(format_bls12381fq12_lsc_lsc_lsc_lsb(), &val_7), 1);
        assert!(std::option::is_none(&deserialize<Fq12>(format_bls12381fq12_lsc_lsc_lsc_lsb(), &x"ffff")), 1);

        // Negation.
        let val_minus_7 = field_neg(&val_7);
        assert!(BLS12_381_FQ12_VAL_7_NEG_SERIALIZED == serialize(format_bls12381fq12_lsc_lsc_lsc_lsb(), &val_minus_7), 1);

        // Addition.
        let val_9 = from_u64<Fq12>(9);
        let val_2 = from_u64<Fq12>(2);
        assert!(eq(&val_2, &field_add(&val_minus_7, &val_9)), 1);

        // Subtraction.
        assert!(eq(&val_9, &field_sub(&val_2, &val_minus_7)), 1);

        // Multiplication.
        let val_63 = from_u64<Fq12>(63);
        assert!(eq(&val_63, &field_mul(&val_7, &val_9)), 1);

        // division.
        let val_0 = from_u64<Fq12>(0);
        assert!(eq(&val_7, &std::option::extract(&mut field_div(&val_63, &val_9))), 1);
        assert!(std::option::is_none(&field_div(&val_63, &val_0)), 1);

        // Inversion.
        assert!(eq(&val_minus_7, &field_neg(&val_7)), 1);
        assert!(std::option::is_none(&field_inv(&val_0)), 1);

        // Squaring.
        let val_x = insecure_random_element<Fq12>();
        assert!(eq(&field_mul(&val_x, &val_x), &field_sqr(&val_x)), 1);

        // Downcasting.
        assert!(eq(&group_identity<Gt>(), &std::option::extract(&mut downcast<Fq12, Gt>(&val_1))), 1);
    }

    #[test_only]
    const BLS12_381_R: vector<u8> = x"01000000fffffffffe5bfeff02a4bd5305d8a10908d83933487d9d2953a7ed73";
    #[test_only]
    const BLS12381G1Affine_INF_SERIALIZED_COMP: vector<u8> = x"c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    #[test_only]
    const BLS12381G1Affine_INF_SERIALIZED_UNCOMP: vector<u8> = x"400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    #[test_only]
    const BLS12381G1Affine_GENERATOR_SERIALIZED_COMP: vector<u8> = x"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";
    #[test_only]
    const BLS12381G1Affine_GENERATOR_SERIALIZED_UNCOMP: vector<u8> = x"17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1";
    #[test_only]
    const BLS12381G1Affine_GENERATOR_MUL_BY_7_SERIALIZED_COMP: vector<u8> = x"b928f3beb93519eecf0145da903b40a4c97dca00b21f12ac0df3be9116ef2ef27b2ae6bcd4c5bc2d54ef5a70627efcb7";
    #[test_only]
    const BLS12381G1Affine_GENERATOR_MUL_BY_7_SERIALIZED_UNCOMP: vector<u8> = x"1928f3beb93519eecf0145da903b40a4c97dca00b21f12ac0df3be9116ef2ef27b2ae6bcd4c5bc2d54ef5a70627efcb7108dadbaa4b636445639d5ae3089b3c43a8a1d47818edd1839d7383959a41c10fdc66849cfa1b08c5a11ec7e28981a1c";
    #[test_only]
    const BLS12381G1Affine_GENERATOR_MUL_BY_7_NEG_SERIALIZED_COMP: vector<u8> = x"9928f3beb93519eecf0145da903b40a4c97dca00b21f12ac0df3be9116ef2ef27b2ae6bcd4c5bc2d54ef5a70627efcb7";
    #[test_only]
    const BLS12381G1Affine_GENERATOR_MUL_BY_7_NEG_SERIALIZED_UNCOMP: vector<u8> = x"1928f3beb93519eecf0145da903b40a4c97dca00b21f12ac0df3be9116ef2ef27b2ae6bcd4c5bc2d54ef5a70627efcb70973642f94c9b055f4e1d20812c1f91329ed2e3d71f635a72d599a679d0cda1320e597b4e1b24f735fed1381d767908f";

    #[test(fx = @std)]
    fun test_bls12_381_g1(fx: signer) {
        enable_initial_generic_algebraic_operations(&fx);
        enable_bls12_381_structures(&fx);

        // Special constants and checks.
        assert!(BLS12_381_R == group_order<G1Affine>(), 1);
        let point_at_infinity = group_identity<G1Affine>();
        let generator = group_generator<G1Affine>();
        assert!(group_is_identity(&point_at_infinity), 1);
        assert!(!group_is_identity(&generator), 1);

        // Serialization/deserialization.
        assert!(BLS12381G1Affine_GENERATOR_SERIALIZED_UNCOMP == serialize(
            format_bls12381g1_affine_uncompressed(), &generator), 1);
        assert!(BLS12381G1Affine_GENERATOR_SERIALIZED_COMP == serialize(format_bls12381g1_affine_compressed(), &generator), 1);
        let generator_from_comp = std::option::extract(&mut deserialize<G1Affine>(
            format_bls12381g1_affine_compressed(), &BLS12381G1Affine_GENERATOR_SERIALIZED_COMP));
        let generator_from_uncomp = std::option::extract(&mut deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &BLS12381G1Affine_GENERATOR_SERIALIZED_UNCOMP));
        assert!(eq(&generator, &generator_from_comp), 1);
        assert!(eq(&generator, &generator_from_uncomp), 1);

        // Deserialization: byte array of correct size but the value is not a member.
        assert!(std::option::is_none(&deserialize<Fq12>(
            format_bls12381fq12_lsc_lsc_lsc_lsb(), &x"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")), 1);

        // Deserialization: byte array of wrong size.
        assert!(std::option::is_none(&deserialize<Fq12>(
            format_bls12381fq12_lsc_lsc_lsc_lsb(), &x"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")), 1);

        assert!(BLS12381G1Affine_INF_SERIALIZED_UNCOMP == serialize(
            format_bls12381g1_affine_uncompressed(), &point_at_infinity), 1);
        assert!(BLS12381G1Affine_INF_SERIALIZED_COMP == serialize(
            format_bls12381g1_affine_compressed(), &point_at_infinity), 1);
        let inf_from_uncomp = std::option::extract(&mut deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &BLS12381G1Affine_INF_SERIALIZED_UNCOMP));
        let inf_from_comp = std::option::extract(&mut deserialize<G1Affine>(
            format_bls12381g1_affine_compressed(), &BLS12381G1Affine_INF_SERIALIZED_COMP));
        assert!(eq(&point_at_infinity, &inf_from_comp), 1);
        assert!(eq(&point_at_infinity, &inf_from_uncomp), 1);

        let point_7g_from_uncomp = std::option::extract(&mut deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &BLS12381G1Affine_GENERATOR_MUL_BY_7_SERIALIZED_UNCOMP));
        let point_7g_from_comp = std::option::extract(&mut deserialize<G1Affine>(
            format_bls12381g1_affine_compressed(), &BLS12381G1Affine_GENERATOR_MUL_BY_7_SERIALIZED_COMP));
        assert!(eq(&point_7g_from_comp, &point_7g_from_uncomp), 1);

        // Deserialization should fail if given a point on the curve but off its prime-order subgroup, e.g., `(0,2)`.
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002")), 1);
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_compressed(), &x"800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")), 1);

        // Deserialization should fail if given a valid point in (Fq,Fq) but not on the curve.
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &x"8959e137e0719bf872abb08411010f437a8955bd42f5ba20fca64361af58ce188b1adb96ef229698bb7860b79e24ba12000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")), 1);

        // Deserialization should fail if given an invalid point (x not in Fq).
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &x"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa76e9853b35f5c9b2002d9e5833fd8f9ab4cd3934a4722a06f6055bfca720c91629811e2ecae7f0cf301b6d07898a90f")), 1);
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_compressed(), &x"9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")), 1);

        // Deserialization should fail if given a byte array of wrong size.
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ab")), 1);
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_compressed(), &x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ab")), 1);

        // Scalar multiplication.
        let scalar_7 = from_u64<Fr>(7);
        let point_7g_calc = group_scalar_mul(&generator, &scalar_7);
        assert!(eq(&point_7g_calc, &point_7g_from_comp), 1);
        assert!(BLS12381G1Affine_GENERATOR_MUL_BY_7_SERIALIZED_UNCOMP == serialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &point_7g_calc), 1);
        assert!(BLS12381G1Affine_GENERATOR_MUL_BY_7_SERIALIZED_COMP == serialize<G1Affine>(
            format_bls12381g1_affine_compressed(),  &point_7g_calc), 1);

        // Multi-scalar multiplication.
        let scalar_a = from_u64<Fr>(0x0300);
        let scalar_b = from_u64<Fr>(0x0401);
        let scalar_c = from_u64<Fr>(0x0502);
        let point_p = insecure_random_element<G1Affine>();
        let point_q = insecure_random_element<G1Affine>();
        let point_r = insecure_random_element<G1Affine>();
        let expected = group_identity<G1Affine>();
        let expected = group_add(&expected, &group_scalar_mul(&point_p, &scalar_a));
        let expected = group_add(&expected, &group_scalar_mul(&point_q, &scalar_b));
        let expected = group_add(&expected, &group_scalar_mul(&point_r, &scalar_c));
        let points = vector[point_p, point_q, point_r];
        let scalars = vector[scalar_a, scalar_b, scalar_c];
        let actual = group_multi_scalar_mul(&points, &scalars);
        assert!(eq(&expected, &actual), 1);

        // Doubling.
        let scalar_2 = from_u64<Fr>(2);
        let point_2g = group_scalar_mul(&generator, &scalar_2);
        let point_double_g = group_double(&generator);
        assert!(eq(&point_2g, &point_double_g), 1);

        // Negation.
        let point_minus_7g_calc = group_neg(&point_7g_calc);
        assert!(BLS12381G1Affine_GENERATOR_MUL_BY_7_NEG_SERIALIZED_COMP == serialize<G1Affine>(
            format_bls12381g1_affine_compressed(), &point_minus_7g_calc), 1);
        assert!(BLS12381G1Affine_GENERATOR_MUL_BY_7_NEG_SERIALIZED_UNCOMP == serialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &point_minus_7g_calc), 1);

        // Addition.
        let scalar_9 = from_u64<Fr>(9);
        let point_9g = group_scalar_mul(&generator, &scalar_9);
        let point_2g = group_scalar_mul(&generator, &scalar_2);
        let point_2g_calc = group_add(&point_minus_7g_calc, &point_9g);
        assert!(eq(&point_2g, &point_2g_calc), 1);

        // Subtraction.
        assert!(eq(&point_9g, &group_sub(&point_2g, &point_minus_7g_calc)), 1);

        // Hash-to-group using suite `BLS12381G1_XMD:SHA-256_SSWU_RO_`.
        // Test vectors source: https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-16.html#name-bls12381g1_xmdsha-256_sswu_
        let actual = hash_to<G1Affine>(
            h2s_suite_bls12381g1_xmd_sha_256_sswu_ro(), &b"QUUX-V01-CS02-with-BLS12381G1_XMD:SHA-256_SSWU_RO_", &b"");
        let expected = std::option::extract(&mut deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &x"052926add2207b76ca4fa57a8734416c8dc95e24501772c814278700eed6d1e4e8cf62d9c09db0fac349612b759e79a108ba738453bfed09cb546dbb0783dbb3a5f1f566ed67bb6be0e8c67e2e81a4cc68ee29813bb7994998f3eae0c9c6a265"));
        assert!(eq(&expected, &actual), 1);
        let actual = hash_to<G1Affine>(
            h2s_suite_bls12381g1_xmd_sha_256_sswu_ro(), &b"QUUX-V01-CS02-with-BLS12381G1_XMD:SHA-256_SSWU_RO_", &b"abcdef0123456789");
        let expected = std::option::extract(&mut deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &x"11e0b079dea29a68f0383ee94fed1b940995272407e3bb916bbf268c263ddd57a6a27200a784cbc248e84f357ce82d9803a87ae2caf14e8ee52e51fa2ed8eefe80f02457004ba4d486d6aa1f517c0889501dc7413753f9599b099ebcbbd2d709"));
        assert!(eq(&expected, &actual), 1);
    }

    #[test_only]
    const BLS12381G2Affine_INF_SERIALIZED_UNCOMP: vector<u8> = x"400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    #[test_only]
    const BLS12381G2Affine_INF_SERIALIZED_COMP: vector<u8> = x"c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    #[test_only]
    const BLS12381G2Affine_GENERATOR_SERIALIZED_UNCOMP: vector<u8> = x"13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb80606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801";
    #[test_only]
    const BLS12381G2Affine_GENERATOR_SERIALIZED_COMP: vector<u8> = x"93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8";
    #[test_only]
    const BLS12381G2Affine_GENERATOR_MUL_BY_7_SERIALIZED_UNCOMP: vector<u8> = x"0d0273f6bf31ed37c3b8d68083ec3d8e20b5f2cc170fa24b9b5be35b34ed013f9a921f1cad1644d4bdb14674247234c8049cd1dbb2d2c3581e54c088135fef36505a6823d61b859437bfc79b617030dc8b40e32bad1fa85b9c0f368af6d38d3c05ecf93654b7a1885695aaeeb7caf41b0239dc45e1022be55d37111af2aecef87799638bec572de86a7437898efa702008b7ae4dbf802c17a6648842922c9467e460a71c88d393ee7af356da123a2f3619e80c3bdcc8e2b1da52f8cd9913ccdd";
    #[test_only]
    const BLS12381G2Affine_GENERATOR_MUL_BY_7_SERIALIZED_COMP: vector<u8> = x"8d0273f6bf31ed37c3b8d68083ec3d8e20b5f2cc170fa24b9b5be35b34ed013f9a921f1cad1644d4bdb14674247234c8049cd1dbb2d2c3581e54c088135fef36505a6823d61b859437bfc79b617030dc8b40e32bad1fa85b9c0f368af6d38d3c";
    #[test_only]
    const BLS12381G2Affine_GENERATOR_MUL_BY_7_NEG_SERIALIZED_UNCOMP: vector<u8> = x"0d0273f6bf31ed37c3b8d68083ec3d8e20b5f2cc170fa24b9b5be35b34ed013f9a921f1cad1644d4bdb14674247234c8049cd1dbb2d2c3581e54c088135fef36505a6823d61b859437bfc79b617030dc8b40e32bad1fa85b9c0f368af6d38d3c141418b3e4c84511f485fcc78b80b8bc623d6f3f1282e6da09f9c1860402272ba7129c72c4fcd2174f8ac87671053a8b1149639c79ffba82a4b71f73b11f186f8016a4686ab17ed0ec3d7bc6e476c6ee04c3f3c2d48b1d4ddfac073266ebddce";
    #[test_only]
    const BLS12381G2Affine_GENERATOR_MUL_BY_7_NEG_SERIALIZED_COMP: vector<u8> = x"ad0273f6bf31ed37c3b8d68083ec3d8e20b5f2cc170fa24b9b5be35b34ed013f9a921f1cad1644d4bdb14674247234c8049cd1dbb2d2c3581e54c088135fef36505a6823d61b859437bfc79b617030dc8b40e32bad1fa85b9c0f368af6d38d3c";

    #[test(fx = @std)]
    fun test_bls12_381_g2(fx: signer) {
        enable_initial_generic_algebraic_operations(&fx);
        enable_bls12_381_structures(&fx);

        // Special constants and checks.
        assert!(BLS12_381_R == group_order<G2Affine>(), 1);
        let point_at_infinity = group_identity<G2Affine>();
        let generator = group_generator<G2Affine>();
        assert!(group_is_identity(&point_at_infinity), 1);
        assert!(!group_is_identity(&generator), 1);

        // Serialization/deserialization.
        assert!(BLS12381G2Affine_GENERATOR_SERIALIZED_COMP == serialize<G2Affine>(
            format_bls12381g2_affine_compressed(), &generator), 1);
        assert!(BLS12381G2Affine_GENERATOR_SERIALIZED_UNCOMP == serialize<G2Affine>(
            format_bls12381g2_affine_uncompressed(), &generator), 1);
        let generator_from_uncomp = std::option::extract(&mut deserialize<G2Affine>(
            format_bls12381g2_affine_uncompressed(), &BLS12381G2Affine_GENERATOR_SERIALIZED_UNCOMP));
        let generator_from_comp = std::option::extract(&mut deserialize<G2Affine>(
            format_bls12381g2_affine_compressed(), &BLS12381G2Affine_GENERATOR_SERIALIZED_COMP));
        assert!(eq(&generator, &generator_from_comp), 1);
        assert!(eq(&generator, &generator_from_uncomp), 1);
        assert!(BLS12381G2Affine_INF_SERIALIZED_UNCOMP == serialize<G2Affine>(
            format_bls12381g2_affine_uncompressed(), &point_at_infinity), 1);
        assert!(BLS12381G2Affine_INF_SERIALIZED_COMP == serialize<G2Affine>(
            format_bls12381g2_affine_compressed(), &point_at_infinity), 1);
        let inf_from_uncomp = std::option::extract(&mut deserialize<G2Affine>(
            format_bls12381g2_affine_uncompressed(), &BLS12381G2Affine_INF_SERIALIZED_UNCOMP));
        let inf_from_comp = std::option::extract(&mut deserialize<G2Affine>(
            format_bls12381g2_affine_compressed(), &BLS12381G2Affine_INF_SERIALIZED_COMP));
        assert!(eq(&point_at_infinity, &inf_from_comp), 1);
        assert!(eq(&point_at_infinity, &inf_from_uncomp), 1);
        let point_7g_from_uncomp = std::option::extract(&mut deserialize<G2Affine>(
            format_bls12381g2_affine_uncompressed(), &BLS12381G2Affine_GENERATOR_MUL_BY_7_SERIALIZED_UNCOMP));
        let point_7g_from_comp = std::option::extract(&mut deserialize<G2Affine>(
            format_bls12381g2_affine_compressed(), &BLS12381G2Affine_GENERATOR_MUL_BY_7_SERIALIZED_COMP));
        assert!(eq(&point_7g_from_comp, &point_7g_from_uncomp), 1);

        // Deserialization should fail if given a point on the curve but not in the prime-order subgroup.
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &x"f037d4ccd5ee751eba1c1fd4c7edbb76d2b04c3a1f3f554827cf37c3acbc2dbb7cdb320a2727c2462d6c55ca1f637707b96eeebc622c1dbe7c56c34f93887c8751b42bd04f29253a82251c192ef27ece373993b663f4360505299c5bd18c890ddd862a6308796bf47e2265073c1f7d81afd69f9497fc1403e2e97a866129b43b672295229c21116d4a99f3e5c2ae720a31f181dbed8a93e15f909c20cf69d11a8879adbbe6890740def19814e6d4ed23fb0dcbd79291655caf48b466ac9cae04")), 1);
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_compressed(), &x"f037d4ccd5ee751eba1c1fd4c7edbb76d2b04c3a1f3f554827cf37c3acbc2dbb7cdb320a2727c2462d6c55ca1f637707b96eeebc622c1dbe7c56c34f93887c8751b42bd04f29253a82251c192ef27ece373993b663f4360505299c5bd18c890d")), 1);

        // Deserialization should fail if given a valid point in (Fq2,Fq2) but not on the curve.
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &x"f037d4ccd5ee751eba1c1fd4c7edbb76d2b04c3a1f3f554827cf37c3acbc2dbb7cdb320a2727c2462d6c55ca1f637707b96eeebc622c1dbe7c56c34f93887c8751b42bd04f29253a82251c192ef27ece373993b663f4360505299c5bd18c890d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")), 1);

        // Deserialization should fail if given an invalid point (x not in Fq2).
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &x"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdd862a6308796bf47e2265073c1f7d81afd69f9497fc1403e2e97a866129b43b672295229c21116d4a99f3e5c2ae720a31f181dbed8a93e15f909c20cf69d11a8879adbbe6890740def19814e6d4ed23fb0dcbd79291655caf48b466ac9cae04")), 1);
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_compressed(), &x"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")), 1);

        // Deserialization should fail if given a byte array of wrong size.
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_uncompressed(), &x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ab")), 1);
        assert!(std::option::is_none(&deserialize<G1Affine>(
            format_bls12381g1_affine_compressed(), &x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ab")), 1);

        // Scalar multiplication.
        let scalar_7 = from_u64<Fr>(7);
        let point_7g_calc = group_scalar_mul(&generator, &scalar_7);
        assert!(eq(&point_7g_calc, &point_7g_from_comp), 1);
        assert!(BLS12381G2Affine_GENERATOR_MUL_BY_7_SERIALIZED_UNCOMP == serialize<G2Affine>(
            format_bls12381g2_affine_uncompressed(), &point_7g_calc), 1);
        assert!(BLS12381G2Affine_GENERATOR_MUL_BY_7_SERIALIZED_COMP == serialize<G2Affine>(
            format_bls12381g2_affine_compressed(), &point_7g_calc), 1);

        // Multi-scalar multiplication.
        let scalar_a = from_u64<Fr>(0x0300);
        let scalar_b = from_u64<Fr>(0x0401);
        let scalar_c = from_u64<Fr>(0x0502);
        let point_p = insecure_random_element<G2Affine>();
        let point_q = insecure_random_element<G2Affine>();
        let point_r = insecure_random_element<G2Affine>();
        let expected = group_identity<G2Affine>();
        let expected = group_add(&expected, &group_scalar_mul(&point_p, &scalar_a));
        let expected = group_add(&expected, &group_scalar_mul(&point_q, &scalar_b));
        let expected = group_add(&expected, &group_scalar_mul(&point_r, &scalar_c));
        let points = vector[point_p, point_q, point_r];
        let scalars = vector[scalar_a, scalar_b, scalar_c];
        let actual = group_multi_scalar_mul(&points, &scalars);
        assert!(eq(&expected, &actual), 1);

        // Doubling.
        let scalar_2 = from_u64<Fr>(2);
        let point_2g = group_scalar_mul(&generator, &scalar_2);
        let point_double_g = group_double(&generator);
        assert!(eq(&point_2g, &point_double_g), 1);

        // Negation.
        let point_minus_7g_calc = group_neg(&point_7g_calc);
        assert!(BLS12381G2Affine_GENERATOR_MUL_BY_7_NEG_SERIALIZED_COMP == serialize<G2Affine>(
            format_bls12381g2_affine_compressed(), &point_minus_7g_calc), 1);
        assert!(BLS12381G2Affine_GENERATOR_MUL_BY_7_NEG_SERIALIZED_UNCOMP == serialize<G2Affine>(
            format_bls12381g2_affine_uncompressed(), &point_minus_7g_calc), 1);

        // Addition.
        let scalar_9 = from_u64<Fr>(9);
        let point_9g = group_scalar_mul(&generator, &scalar_9);
        let point_2g = group_scalar_mul(&generator, &scalar_2);
        let point_2g_calc = group_add(&point_minus_7g_calc, &point_9g);
        assert!(eq(&point_2g, &point_2g_calc), 1);

        // Subtraction.
        assert!(eq(&point_9g, &group_sub(&point_2g, &point_minus_7g_calc)), 1);

        // Hash-to-group using suite `BLS12381G2_XMD:SHA-256_SSWU_RO_`.
        // Test vectors source: https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-16.html#name-bls12381g2_xmdsha-256_sswu_
        let actual = hash_to<G2Affine>(
            h2s_suite_bls12381g2_xmd_sha_256_sswu_ro(), &b"QUUX-V01-CS02-with-BLS12381G2_XMD:SHA-256_SSWU_RO_", &b"");
        let expected = std::option::extract(&mut deserialize<G2Affine>(
            format_bls12381g2_affine_uncompressed(), &x"05cb8437535e20ecffaef7752baddf98034139c38452458baeefab379ba13dff5bf5dd71b72418717047f5b0f37da03d0141ebfbdca40eb85b87142e130ab689c673cf60f1a3e98d69335266f30d9b8d4ac44c1038e9dcdd5393faf5c41fb78a12424ac32561493f3fe3c260708a12b7c620e7be00099a974e259ddc7d1f6395c3c811cdd19f1e8dbf3e9ecfdcbab8d60503921d7f6a12805e72940b963c0cf3471c7b2a524950ca195d11062ee75ec076daf2d4bc358c4b190c0c98064fdd92"));
        assert!(eq(&expected, &actual), 1);
        let actual = hash_to<G2Affine>(
            h2s_suite_bls12381g2_xmd_sha_256_sswu_ro(), &b"QUUX-V01-CS02-with-BLS12381G2_XMD:SHA-256_SSWU_RO_", &b"abcdef0123456789");
        let expected = std::option::extract(&mut deserialize<G2Affine>(
            format_bls12381g2_affine_uncompressed(), &x"190d119345b94fbd15497bcba94ecf7db2cbfd1e1fe7da034d26cbba169fb3968288b3fafb265f9ebd380512a71c3f2c121982811d2491fde9ba7ed31ef9ca474f0e1501297f68c298e9f4c0028add35aea8bb83d53c08cfc007c1e005723cd00bb5e7572275c567462d91807de765611490205a941a5a6af3b1691bfe596c31225d3aabdf15faff860cb4ef17c7c3be05571a0f8d3c08d094576981f4a3b8eda0a8e771fcdcc8ecceaf1356a6acf17574518acb506e435b639353c2e14827c8"));
        assert!(eq(&expected, &actual), 1);
    }

    #[test_only]
    const BLS12_381_FQ12_ONE_SERIALIZED: vector<u8> = x"010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    #[test_only]
    const BLS12_381_GT_GENERATOR_SERIALIZED: vector<u8> = x"b68917caaa0543a808c53908f694d1b6e7b38de90ce9d83d505ca1ef1b442d2727d7d06831d8b2a7920afc71d8eb50120f17a0ea982a88591d9f43503e94a8f1abaf2e4589f65aafb7923c484540a868883432a5c60e75860b11e5465b1c9a08873ec29e844c1c888cb396933057ffdd541b03a5220eda16b2b3a6728ea678034ce39c6839f20397202d7c5c44bb68134f93193cec215031b17399577a1de5ff1f5b0666bdd8907c61a7651e4e79e0372951505a07fa73c25788db6eb8023519a5aa97b51f1cad1d43d8aabbff4dc319c79a58cafc035218747c2f75daf8f2fb7c00c44da85b129113173d4722f5b201b6b4454062e9ea8ba78c5ca3cadaf7238b47bace5ce561804ae16b8f4b63da4645b8457a93793cbd64a7254f150781019de87ee42682940f3e70a88683d512bb2c3fb7b2434da5dedbb2d0b3fb8487c84da0d5c315bdd69c46fb05d23763f2191aabd5d5c2e12a10b8f002ff681bfd1b2ee0bf619d80d2a795eb22f2aa7b85d5ffb671a70c94809f0dafc5b73ea2fb0657bae23373b4931bc9fa321e8848ef78894e987bff150d7d671aee30b3931ac8c50e0b3b0868effc38bf48cd24b4b811a2995ac2a09122bed9fd9fa0c510a87b10290836ad06c8203397b56a78e9a0c61c77e56ccb4f1bc3d3fcaea7550f3503efe30f2d24f00891cb45620605fcfaa4292687b3a7db7c1c0554a93579e889a121fd8f72649b2402996a084d2381c5043166673b3849e4fd1e7ee4af24aa8ed443f56dfd6b68ffde4435a92cd7a4ac3bc77e1ad0cb728606cf08bf6386e5410f";
    #[test_only]
    const BLS12_381_GT_GENERATOR_MUL_BY_7_SERIALIZED: vector<u8> = x"2041ea7b66c19680e2c0bb23245a71918753220b31f88a925aa9b1e192e7c188a0b365cb994b3ec5e809206117c6411242b940b10caa37ce734496b3b7c63578a0e3c076f9b31a7ca13a716262e0e4cda4ac994efb9e19893cbfe4d464b9210d099d808a08b3c4c3846e7529984899478639c4e6c46152ef49a04af9c8e6ff442d286c4613a3dac6a4bee4b40e1f6b030f2871dabe4223b250c3181ecd3bc6819004745aeb6bac567407f2b9c7d1978c45ee6712ae46930bc00638383f6696158bad488cbe7663d681c96c035481dbcf78e7a7fbaec3799163aa6914cef3365156bdc3e533a7c883d5974e3462ac6f19e3f9ce26800ae248a45c5f0dd3a48a185969224e6cd6af9a048241bdcac9800d94aeee970e08488fb961e36a769b6c185d185b4605dc9808517196bba9d00a3e37bca466c19187486db104ee03962d39fe473e276355618e44c965f05082bb027a7baa4bcc6d8c0775c1e8a481e77df36ddad91e75a982302937f543a11fe71922dcd4f46fe8f951f91cde412b359507f2b3b6df0374bfe55c9a126ad31ce254e67d64194d32d7955ec791c9555ea5a917fc47aba319e909de82da946eb36e12aff936708402228295db2712f2fc807c95092a86afd71220699df13e2d2fdf2857976cb1e605f72f1b2edabadba3ff05501221fe81333c13917c85d725ce92791e115eb0289a5d0b3330901bb8b0ed146abeb81381b7331f1c508fb14e057b05d8b0190a9e74a3d046dcd24e7ab747049945b3d8a120c4f6d88e67661b55573aa9b361367488a1ef7dffd967d64a1518";
    #[test_only]
    const BLS12_381_GT_GENERATOR_MUL_BY_7_NEG_SERIALIZED: vector<u8> = x"2041ea7b66c19680e2c0bb23245a71918753220b31f88a925aa9b1e192e7c188a0b365cb994b3ec5e809206117c6411242b940b10caa37ce734496b3b7c63578a0e3c076f9b31a7ca13a716262e0e4cda4ac994efb9e19893cbfe4d464b9210d099d808a08b3c4c3846e7529984899478639c4e6c46152ef49a04af9c8e6ff442d286c4613a3dac6a4bee4b40e1f6b030f2871dabe4223b250c3181ecd3bc6819004745aeb6bac567407f2b9c7d1978c45ee6712ae46930bc00638383f6696158bad488cbe7663d681c96c035481dbcf78e7a7fbaec3799163aa6914cef3365156bdc3e533a7c883d5974e3462ac6f19e3f9ce26800ae248a45c5f0dd3a48a185969224e6cd6af9a048241bdcac9800d94aeee970e08488fb961e36a769b6c184e92a4b9fa2366b1ae8ebdf5542fa1e0ec390c90df40a91e5261800581b5492bd9640d1c5352babc551d1a49998f4517312f55b4339272b28a3e6b0c7d182e2bb61bd7d72b29ae3696db8fafe32b904ab5d0764e46bf21f9a0c9a1f7bedc6b12b9f64820fc8b3fd4a26541472be3c9c93d784cdd53a059d1604bf3292fedd1babfb00398128e3241bc63a5a47b5e9207fcb0c88f7bfddc376a242c9f0c032ba28eec8670f1fa1d47567593b4571c983b8015df91cfa1241b7fb8a57e0e6e01145b98de017eccc2a66e83ced9d83119a505e552467838d35b8ce2f4d7cc9a894f6dee922f35f0e72b7e96f0879b0c8614d3f9e5f5618b5be9b82381628448641a8bb0fd1dffb16c70e6831d8d69f61f2a2ef9e90c421f7a5b1ce7a5d113c7eb01";

    #[test(fx = @std)]
    fun test_bls12_381_gt(fx: signer) {
        enable_initial_generic_algebraic_operations(&fx);
        enable_bls12_381_structures(&fx);

        // Special constants and checks.
        assert!(BLS12_381_R == group_order<Gt>(), 1);
        let identity = group_identity<Gt>();
        let generator = group_generator<Gt>();
        assert!(group_is_identity(&identity), 1);
        assert!(!group_is_identity(&generator), 1);

        // Serialization/deserialization.
        assert!(BLS12_381_GT_GENERATOR_SERIALIZED == serialize<Gt>(format_bls12381gt(), &generator), 1);
        let generator_from_deser = std::option::extract(&mut deserialize<Gt>(
            format_bls12381gt(), &BLS12_381_GT_GENERATOR_SERIALIZED));
        assert!(eq(&generator, &generator_from_deser), 1);
        assert!(BLS12_381_FQ12_ONE_SERIALIZED == serialize<Gt>(format_bls12381gt(), &identity), 1);
        let identity_from_deser = std::option::extract(&mut deserialize<Gt>(
            format_bls12381gt(), &BLS12_381_FQ12_ONE_SERIALIZED));
        assert!(eq(&identity, &identity_from_deser), 1);
        let element_7g_from_deser = std::option::extract(&mut deserialize<Gt>(
            format_bls12381gt(), &BLS12_381_GT_GENERATOR_MUL_BY_7_SERIALIZED));
        assert!(std::option::is_none(&deserialize<Gt>(format_bls12381gt(), &x"ffff")), 1);

        // Deserialization: in Fq12 but not in the prime-order subgroup.
        assert!(std::option::is_none(&deserialize<Gt>(
            format_bls12381gt(), &x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")), 1);

        // Deserialization: byte array of wrong size.
        assert!(std::option::is_none(&deserialize<Gt>(
            format_bls12381gt(), &x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ab")), 1);

        // Element scalar multiplication.
        let scalar_7 = from_u64<Fr>(7);
        let element_7g_calc = group_scalar_mul(&generator, &scalar_7);
        assert!(eq(&element_7g_calc, &element_7g_from_deser), 1);
        assert!(BLS12_381_GT_GENERATOR_MUL_BY_7_SERIALIZED == serialize<Gt>(
            format_bls12381gt(), &element_7g_calc), 1);

        // Element negation.
        let element_minus_7g_calc = group_neg(&element_7g_calc);
        assert!(BLS12_381_GT_GENERATOR_MUL_BY_7_NEG_SERIALIZED == serialize<Gt>(
            format_bls12381gt(), &element_minus_7g_calc), 1);

        // Element addition.
        let scalar_9 = from_u64<Fr>(9);
        let element_9g = group_scalar_mul(&generator, &scalar_9);
        let scalar_2 = from_u64<Fr>(2);
        let element_2g = group_scalar_mul(&generator, &scalar_2);
        let element_2g_calc = group_add(&element_minus_7g_calc, &element_9g);
        assert!(eq(&element_2g, &element_2g_calc), 1);

        // Subtraction.
        assert!(eq(&element_9g, &group_sub(&element_2g, &element_minus_7g_calc)), 1);

        // Upcasting to Fq12.
        assert!(eq(&field_one<Fq12>(), &upcast<Gt, Fq12>(&identity)), 1);
    }

    #[test_only]
    use aptos_std::algebra::{field_zero, field_one, field_is_zero, field_is_one, from_u64, eq, deserialize, serialize, field_neg, field_add, field_sub, field_mul, field_div, field_inv, insecure_random_element, field_sqr, group_order, group_identity, group_generator, group_is_identity, group_scalar_mul, group_add, group_multi_scalar_mul, group_double, group_neg, group_sub, hash_to, upcast, downcast, enable_initial_generic_algebraic_operations, pairing, multi_pairing};

    #[test_only]
    const BLS12_381_FR_VAL_7_SERIALIZED_LENDIAN: vector<u8> = x"0700000000000000000000000000000000000000000000000000000000000000";
    #[test_only]
    const BLS12_381_FR_VAL_7_SERIALIZED_BENDIAN: vector<u8> = x"0000000000000000000000000000000000000000000000000000000000000007";
    #[test_only]
    const BLS12_381_FR_VAL_7_NEG_SERIALIZED_LENDIAN: vector<u8> = x"fafffffffefffffffe5bfeff02a4bd5305d8a10908d83933487d9d2953a7ed73";

    #[test(fx = @std)]
    fun test_bls12_381_fr(fx: signer) {
        enable_initial_generic_algebraic_operations(&fx);
        enable_bls12_381_structures(&fx);

        // Special elements and checks.
        let val_0 = field_zero<Fr>();
        let val_1 = field_one<Fr>();
        assert!(field_is_zero(&val_0), 1);
        assert!(!field_is_zero(&val_1), 1);
        assert!(!field_is_one(&val_0), 1);
        assert!(field_is_one(&val_1), 1);

        // Serialization/deserialization.
        let val_7 = from_u64<Fr>(7);
        let val_7_2nd = std::option::extract(&mut deserialize<Fr>(
            format_bls12381fr_lsb(), &BLS12_381_FR_VAL_7_SERIALIZED_LENDIAN));
        let val_7_3rd = std::option::extract(&mut deserialize<Fr>(
            format_bls12381fr_msb(), &BLS12_381_FR_VAL_7_SERIALIZED_BENDIAN));
        assert!(eq(&val_7, &val_7_2nd), 1);
        assert!(eq(&val_7, &val_7_3rd), 1);
        assert!(BLS12_381_FR_VAL_7_SERIALIZED_LENDIAN == serialize(format_bls12381fr_lsb(), &val_7), 1);
        assert!(BLS12_381_FR_VAL_7_SERIALIZED_BENDIAN == serialize(format_bls12381fr_msb(), &val_7), 1);

        // Deserialization: byte array of right size but the value is not a member.
        assert!(std::option::is_none(&deserialize<Fr>(
            format_bls12381fr_lsb(), &x"01000000fffffffffe5bfeff02a4bd5305d8a10908d83933487d9d2953a7ed73")), 1);
        assert!(std::option::is_none(&deserialize<Fr>(
            format_bls12381fr_msb(), &x"73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001")), 1);

        // Deserialization: byte array of wrong size.
        assert!(std::option::is_none(&deserialize<Fr>(
            format_bls12381fr_lsb(), &x"01000000fffffffffe5bfeff02a4bd5305d8a10908d83933487d9d2953a7ed7300")), 1);
        assert!(std::option::is_none(&deserialize<Fr>(
            format_bls12381fr_msb(), &x"0073eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001")), 1);
        assert!(std::option::is_none(&deserialize<Fr>(format_bls12381fr_lsb(), &x"ffff")), 1);
        assert!(std::option::is_none(&deserialize<Fr>(format_bls12381fr_msb(), &x"ffff")), 1);

        // Negation.
        let val_minus_7 = field_neg(&val_7);
        assert!(BLS12_381_FR_VAL_7_NEG_SERIALIZED_LENDIAN == serialize<Fr>(
            format_bls12381fr_lsb(), &val_minus_7), 1);

        // Addition.
        let val_9 = from_u64<Fr>(9);
        let val_2 = from_u64<Fr>(2);
        assert!(eq(&val_2, &field_add(&val_minus_7, &val_9)), 1);

        // Subtraction.
        assert!(eq(&val_9, &field_sub(&val_2, &val_minus_7)), 1);

        // Multiplication.
        let val_63 = from_u64<Fr>(63);
        assert!(eq(&val_63, &field_mul(&val_7, &val_9)), 1);

        // division.
        let val_0 = from_u64<Fr>(0);
        assert!(eq(&val_7, &std::option::extract(&mut field_div(&val_63, &val_9))), 1);
        assert!(std::option::is_none(&field_div(&val_63, &val_0)), 1);

        // Inversion.
        assert!(eq(&val_minus_7, &field_neg(&val_7)), 1);
        assert!(std::option::is_none(&field_inv(&val_0)), 1);

        // Squaring.
        let val_x = insecure_random_element<Fr>();
        assert!(eq(&field_mul(&val_x, &val_x), &field_sqr(&val_x)), 1);
    }

    #[test(fx = @std)]
    fun test_bls12381_pairing(fx: signer) {
        enable_initial_generic_algebraic_operations(&fx);
        enable_bls12_381_structures(&fx);

        // pairing(a*P,b*Q) == (a*b)*pairing(P,Q)
        let element_p = insecure_random_element<G1Affine>();
        let element_q = insecure_random_element<G2Affine>();
        let a = insecure_random_element<Fr>();
        let b = insecure_random_element<Fr>();
        let gt_element = pairing<G1Affine,G2Affine,Gt>(&group_scalar_mul(&element_p, &a), &group_scalar_mul(&element_q, &b));
        let gt_element_another = group_scalar_mul(&pairing<G1Affine,G2Affine,Gt>(&element_p, &element_q), &field_mul(&a, &b));
        assert!(eq(&gt_element, &gt_element_another), 1);
    }

    #[test(fx = @std)]
    fun test_bls12381_multi_pairing(fx: signer) {
        enable_initial_generic_algebraic_operations(&fx);
        enable_bls12_381_structures(&fx);

        // Will compute e(a0*P0,b0*Q0)+e(a1*P1,b1*Q1)+e(a2*P2,b2*Q2).
        let a0 = insecure_random_element<Fr>();
        let a1 = insecure_random_element<Fr>();
        let a2 = insecure_random_element<Fr>();
        let element_p0 = insecure_random_element<G1Affine>();
        let element_p1 = insecure_random_element<G1Affine>();
        let element_p2 = insecure_random_element<G1Affine>();
        let p0_a0 = group_scalar_mul(&element_p0, &a0);
        let p1_a1 = group_scalar_mul(&element_p1, &a1);
        let p2_a2 = group_scalar_mul(&element_p2, &a2);
        let b0 = insecure_random_element<Fr>();
        let b1 = insecure_random_element<Fr>();
        let b2 = insecure_random_element<Fr>();
        let element_q0 = insecure_random_element<G2Affine>();
        let element_q1 = insecure_random_element<G2Affine>();
        let element_q2 = insecure_random_element<G2Affine>();
        let q0_b0 = group_scalar_mul(&element_q0, &b0);
        let q1_b1 = group_scalar_mul(&element_q1, &b1);
        let q2_b2 = group_scalar_mul(&element_q2, &b2);

        // Naive method.
        let n0 = pairing<G1Affine,G2Affine,Gt>(&p0_a0, &q0_b0);
        let n1 = pairing<G1Affine,G2Affine,Gt>(&p1_a1, &q1_b1);
        let n2 = pairing<G1Affine,G2Affine,Gt>(&p2_a2, &q2_b2);
        let n = group_identity<Gt>();
        n = group_add(&n, &n0);
        n = group_add(&n, &n1);
        n = group_add(&n, &n2);

        // Efficient API.
        let m = multi_pairing<G1Affine, G2Affine, Gt>(&vector[p0_a0, p1_a1, p2_a2], &vector[q0_b0, q1_b1, q2_b2]);
        assert!(eq(&n, &m), 1);
    }

    #[test(fx = @std)]
    #[expected_failure(abort_code = 0x010000, location = aptos_std::algebra)]
    fun test_multi_pairing_should_abort_when_sizes_mismatch(fx: signer) {
        enable_initial_generic_algebraic_operations(&fx);
        enable_bls12_381_structures(&fx);
        let g1_elements = vector[insecure_random_element<G1Affine>()];
        let g2_elements = vector[insecure_random_element<G2Affine>(), insecure_random_element<G2Affine>()];
        multi_pairing<G1Affine, G2Affine, Gt>(&g1_elements, &g2_elements);
    }

    #[test(fx = @std)]
    #[expected_failure(abort_code = 0x010000, location = aptos_std::algebra)]
    fun test_multi_scalar_mul_should_abort_when_sizes_mismatch(fx: signer) {
        enable_initial_generic_algebraic_operations(&fx);
        enable_bls12_381_structures(&fx);
        let elements = vector[insecure_random_element<G1Affine>()];
        let scalars = vector[insecure_random_element<Fr>(), insecure_random_element<Fr>()];
        group_multi_scalar_mul(&elements, &scalars);
    }

    // Tests end.
}
