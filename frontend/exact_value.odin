package frontend
import "core:math/big"

Exact_Value_Kind :: enum {
    Invalid,
    Bool,
    String,
    Integer,
    Float,
    Pointer,
    Complex,
    Quaternion,
    Compound,
    Procedure,
    Typeid,
}

Exact_Value :: struct {
    kind: Exact_Value_Kind,
    using _: struct #raw_union {
        value_bool: bool,
        value_string: string,
        value_int: big.Int,
        value_float: f64,
        value_pointer: i64,
        value_complex: complex128,
        value_quat: quaternion256,
        value_compound: ^Node,
        value_procedure: ^Node, // Note(Dragos): Having better types will remove the need for a raw union, similar to core:odin/ast
        value_typeid: ^Type, 
    },
}

empty_exact_value := Exact_Value{}
