package frontend
import "core:math/big"


Exact_Value :: union {
    bool,
    string,
    big.Int,
    f64,
    i64,
    complex128,
    quaternion256,
    ^Comp_Lit,
    ^Proc_Lit, // Note(Dragos): Having better types will remove the need for a raw union, similar to core:odin/ast
    ^Type, // typeid 
}

empty_exact_value := Exact_Value{}
