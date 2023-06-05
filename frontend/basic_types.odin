package frontend

basic_types := [Basic_Kind]Type{
	.Invalid = Type{
		variant = Type_Basic{
			kind = .Invalid,
		},
	},

	.llvm_bool = Type{
		variant = Type_Basic{
			kind = .llvm_bool,
		},
	},

	.bool = Type{
		variant = Type_Basic{
			kind = .bool,
		},
	},

	.b8 = Type{
		variant = Type_Basic{
			kind = .b8,
		},
	},

	.b16 = Type{
		variant = Type_Basic{
			kind = .b16,
		},
	},

	.b32 = Type{
		variant = Type_Basic{
			kind = .b32,
		},
	},

	.b64 = Type{
		variant = Type_Basic{
			kind = .b64,
		},
	},

	.i8 = Type{
		variant = Type_Basic{
			kind = .i8,
		},
	},

	.u8 = Type{
		variant = Type_Basic{
			kind = .u8,
		},
	},

	.i16 = Type{
		variant = Type_Basic{
			kind = .i16,
		},
	},

	.u16 = Type{
		variant = Type_Basic{
			kind = .u16,
		},
	},

	.u32 = Type{
		variant = Type_Basic{
			kind = .u32,
		},
	},

	.i32 = Type{
		variant = Type_Basic{
			kind = .i32,
		},
	},

	.u64 = Type{
		variant = Type_Basic{
			kind = .u64,
		},
	},

	.i64 = Type{
		variant = Type_Basic{
			kind = .i64,
		},
	},

	.u128 = Type{
		variant = Type_Basic{
			kind = .u128,
		},
	},

	.i128 = Type{
		variant = Type_Basic{
			kind = .i128,
		},
	},

	.rune = Type{
		variant = Type_Basic{
			kind = .rune,
		},
	},

	.f16 = Type{
		variant = Type_Basic{
			kind = .f16,
		},
	},

	.f32 = Type{
		variant = Type_Basic{
			kind = .f32,
		},
	},

	.f64 = Type{
		variant = Type_Basic{
			kind = .f64,
		},
	},

	.complex32 = Type{
		variant = Type_Basic{
			kind = .complex32,
		},
	},

	.complex64 = Type{
		variant = Type_Basic{
			kind = .complex64,
		},
	},

	.complex128 = Type{
		variant = Type_Basic{
			kind = .complex128,
		},
	},

	.quaternion64 = Type{
		variant = Type_Basic{
			kind = .quaternion64,
		},
	},

	.quaternion128 = Type{
		variant = Type_Basic{
			kind = .quaternion128,
		},
	},

	.quaternion256 = Type{
		variant = Type_Basic{
			kind = .quaternion256,
		},
	},

	.int = Type{
		variant = Type_Basic{
			kind = .int,
		},
	},

	.uint = Type{
		variant = Type_Basic{
			kind = .uint,
		},
	},

	.uintptr = Type{
		variant = Type_Basic{
			kind = .uintptr,
		},
	},

	.rawptr = Type{
		variant = Type_Basic{
			kind = .rawptr,
		},
	},

	.string = Type{
		variant = Type_Basic{
			kind = .string,
		},
	},

	.cstring = Type{
		variant = Type_Basic{
			kind = .cstring,
		},
	},

	.any = Type{
		variant = Type_Basic{
			kind = .any,
		},
	},

	.Typeid = Type{
		variant = Type_Basic{
			kind = .Typeid,
		},
	},

	.i16le = Type{
		variant = Type_Basic{
			kind = .i16le,
		},
	},

	.u16le = Type{
		variant = Type_Basic{
			kind = .u16le,
		},
	},

	.i32le = Type{
		variant = Type_Basic{
			kind = .i32le,
		},
	},

	.u32le = Type{
		variant = Type_Basic{
			kind = .u32le,
		},
	},

	.i64le = Type{
		variant = Type_Basic{
			kind = .i64le,
		},
	},

	.u64le = Type{
		variant = Type_Basic{
			kind = .u64le,
		},
	},

	.i128le = Type{
		variant = Type_Basic{
			kind = .i128le,
		},
	},

	.u128le = Type{
		variant = Type_Basic{
			kind = .u128le,
		},
	},

	.i16be = Type{
		variant = Type_Basic{
			kind = .i16be,
		},
	},

	.u16be = Type{
		variant = Type_Basic{
			kind = .u16be,
		},
	},

	.i32be = Type{
		variant = Type_Basic{
			kind = .i32be,
		},
	},

	.u32be = Type{
		variant = Type_Basic{
			kind = .u32be,
		},
	},

	.i64be = Type{
		variant = Type_Basic{
			kind = .i64be,
		},
	},

	.u64be = Type{
		variant = Type_Basic{
			kind = .u64be,
		},
	},

	.i128be = Type{
		variant = Type_Basic{
			kind = .i128be,
		},
	},

	.u128be = Type{
		variant = Type_Basic{
			kind = .u128be,
		},
	},

	.f16le = Type{
		variant = Type_Basic{
			kind = .f16le,
		},
	},

	.f32le = Type{
		variant = Type_Basic{
			kind = .f32le,
		},
	},

	.f64le = Type{
		variant = Type_Basic{
			kind = .f64le,
		},
	},

	.f16be = Type{
		variant = Type_Basic{
			kind = .f16be,
		},
	},

	.f32be = Type{
		variant = Type_Basic{
			kind = .f32be,
		},
	},

	.f64be = Type{
		variant = Type_Basic{
			kind = .f64be,
		},
	},

	.Untyped_Bool = Type{
		variant = Type_Basic{
			kind = .Untyped_Bool,
		},
	},

	.Untyped_Integer = Type{
		variant = Type_Basic{
			kind = .Untyped_Integer,
		},
	},

	.Untyped_Float = Type{
		variant = Type_Basic{
			kind = .Untyped_Float,
		},
	},

	.Untyped_Complex = Type{
		variant = Type_Basic{
			kind = .Untyped_Complex,
		},
	},

	.Untyped_Quaternion = Type{
		variant = Type_Basic{
			kind = .Untyped_Quaternion,
		},
	},

	.Untyped_String = Type{
		variant = Type_Basic{
			kind = .Untyped_String,
		},
	},

	.Untyped_Rune = Type{
		variant = Type_Basic{
			kind = .Untyped_Rune,
		},
	},

	.Untyped_Nil = Type{
		variant = Type_Basic{
			kind = .Untyped_Nil,
		},
	},

	.Untyped_Uninit = Type{
		variant = Type_Basic{
			kind = .Untyped_Uninit,
		},
	},
}

t_invalid :=            &basic_types[.Invalid]
t_llvm_bool :=          &basic_types[.llvm_bool]
t_bool :=               &basic_types[.bool]
t_i8 :=                 &basic_types[.i8]
t_u8 :=                 &basic_types[.u8]
t_i16 :=                &basic_types[.i16]
t_u16 :=                &basic_types[.u16]
t_i32 :=                &basic_types[.i32]
t_u32 :=                &basic_types[.u32]
t_i64 :=                &basic_types[.i64]
t_u64 :=                &basic_types[.u64]
t_i128 :=               &basic_types[.i128]
t_u128 :=               &basic_types[.u128]
t_rune :=               &basic_types[.rune]
t_f16 :=                &basic_types[.f16]
t_f32 :=                &basic_types[.f32]
t_f64 :=                &basic_types[.f64]
t_complex32 :=          &basic_types[.complex32 ]
t_complex64 :=          &basic_types[.complex64 ]
t_complex128 :=         &basic_types[.complex128]
t_quaternion64 :=       &basic_types[.quaternion64 ]
t_quaternion128 :=      &basic_types[.quaternion128]
t_quaternion256 :=      &basic_types[.quaternion256]
t_int :=                &basic_types[.int ]
t_uint :=               &basic_types[.uint]
t_uintptr :=            &basic_types[.uintptr]
t_rawptr :=             &basic_types[.rawptr ]
t_string :=             &basic_types[.string ]
t_cstring :=            &basic_types[.cstring]
t_any :=                &basic_types[.any]
t_typeid :=             &basic_types[.Typeid]
t_i16le :=              &basic_types[.i16le ]
t_u16le :=              &basic_types[.u16le ]
t_i32le :=              &basic_types[.i32le ]
t_u32le :=              &basic_types[.u32le ]
t_i64le :=              &basic_types[.i64le ]
t_u64le :=              &basic_types[.u64le ]
t_i128le :=             &basic_types[.i128le]
t_u128le :=             &basic_types[.u128le]
t_i16be :=              &basic_types[.i16be ]
t_u16be :=              &basic_types[.u16be ]
t_i32be  :=             &basic_types[.i32be ]
t_u32be  :=             &basic_types[.u32be ]
t_i64be  :=             &basic_types[.i64be ]
t_u64be  :=             &basic_types[.u64be ]
t_i128be :=             &basic_types[.i128be]
t_u128be :=             &basic_types[.u128be]
t_untyped_bool       := &basic_types[.Untyped_Bool      ]
t_untyped_integer    := &basic_types[.Untyped_Integer   ]
t_untyped_float      := &basic_types[.Untyped_Float     ]
t_untyped_complex    := &basic_types[.Untyped_Complex   ]
t_untyped_quaternion := &basic_types[.Untyped_Quaternion]
t_untyped_string     := &basic_types[.Untyped_String    ]
t_untyped_rune       := &basic_types[.Untyped_Rune      ]
t_untyped_nil        := &basic_types[.Untyped_Nil       ]
t_untyped_uninit     := &basic_types[.Untyped_Uninit    ]
