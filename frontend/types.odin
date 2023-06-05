package frontend

Type :: struct {
	variant: union {
		Type_Basic,
		Type_Struct,
		Type_Proc,
		Type_Generic,
		Type_Pointer,
		Type_Multi_Pointer,
		Type_Enumerated_Array,
		Type_Slice,
		Type_Dynamic_Array,
		Type_Enum,
		Type_Tuple,
		Type_Bit_Set,
		Type_Simd_Vector,
		Type_Relative_Pointer,
		Type_Relative_Slice,
		Type_Matrix,
		Type_Soa_Pointer,
	},
}

Basic_Kind :: enum {
    Invalid,

	llvm_bool,
	bool,
	b8,
	b16,
	b32,
	b64,

	i8,
	u8,
	i16,
	u16,
	i32,
	u32,
	i64,
	u64,
	i128,
	u128,

	rune,

	f16,
	f32,
	f64,

	complex32,
	complex64,
	complex128,

	quaternion64,
	quaternion128,
	quaternion256,

	int,
	uint,
	uintptr,
	rawptr,
	string,  // ^u8 + int
	cstring, // ^u8
	any,     // rawptr + ^Type_Info

	Typeid,

	// Endian Specific Types
	i16le,
	u16le,
	i32le,
	u32le,
	i64le,
	u64le,
	i128le,
	u128le,

	i16be,
	u16be,
	i32be,
	u32be,
	i64be,
	u64be,
	i128be,
	u128be,

	f16le,
	f32le,
	f64le,

	f16be,
	f32be,
	f64be,

	// Untyped types
	Untyped_Bool,
	Untyped_Integer,
	Untyped_Float,
	Untyped_Complex,
	Untyped_Quaternion,
	Untyped_String,
	Untyped_Rune,
	Untyped_Nil,
	Untyped_Uninit,
}

Basic_Flag :: enum {
    Boolean, 
    Integer,
    Unsigned,
    Float,
    Complex,
    Quaternion,
    Pointer,
    String,
    Rune,
    Untyped,
    LLVM,
    EndianLittle,
    EndianBig,
}

Basic_Flags :: bit_set[Basic_Flag]
Basic_Flag_Numeric :: Basic_Flags{.Integer, .Float, .Complex, .Quaternion}
Basic_Flag_Ordered :: Basic_Flags{.Integer, .Float, .String, .Pointer, .Rune}
Basic_Flag_Ordered_Numeric :: Basic_Flags{.Integer, .Float, .Rune}
Basic_Flag_Constant_Type :: Basic_Flags{.Boolean, .String, .Pointer, .Rune} + Basic_Flag_Numeric
Basic_Flag_Simple_Compare :: Basic_Flags{.Boolean, .Pointer, .Rune} + Basic_Flag_Numeric

Type_Basic :: struct {
    kind: Basic_Kind,
    flags: Basic_Flags,
    size: i64, // -1 if arch. dep.
    name: string,
}

Struct_Soa_Kind :: enum {
    None,
    Fixed,
    Slice,
    Dynamic,
}

Struct_Flag :: enum {
	Polymorphic,
	Offsets_Set,
	Offsets_Being_Processed,
	Packed,
	Raw_Union,
	No_Copy,
	Poly_Specialized,
}

Struct_Flags :: bit_set[Struct_Flag]

Type_Struct :: struct {
    fields: []^Entity,
    tags: []string, // len(tags) == len(fields)
    offsets: []i64, // len(offsets) == len(fields)
    
    node: ^Ast,
    scope: ^Scope,
	
	custom_align: i64,
	polymorphic_params: ^Type, // Tuple_Type
	polymorphic_parent: ^Type,

	soa_elem: ^Type,
	soa_count: i32,
	soa_kind: Struct_Soa_Kind,
	
	flags: Struct_Flags,
}

Union_Type_Kind :: enum {
	Normal,
	no_nil,
	shared_nil,
}

Union_Flag :: enum {

}

Union_Flags :: bit_set[Union_Flag]

Type_Union :: struct {
	variants: []^Type,

	node: ^Ast,
	scope: ^Scope,

	variant_block_size: i64,
	custom_alignment: i64,
	polymorphic_params: ^Type,
	polymorphic_parent: ^Type,
	
	tag_size: i16,
	flags: Union_Flags,
	kind: Union_Type_Kind,
}

Proc_Flag :: enum {
	Variadic,
	Require_Results,
	C_vararg,
	Polymorphic,
	Poly_Specialized,
	Diverging,
	Return_By_Pointer,
	Optional_Ok,
}

Proc_Flags :: bit_set[Proc_Flag]

Type_Proc :: struct {

}

Type_Generic :: struct {

}

Type_Pointer :: struct {

}

Type_Multi_Pointer :: struct {

}

Type_Enumerated_Array :: struct {

}

Type_Slice :: struct {

}

Type_Dynamic_Array :: struct {

}

Type_Enum :: struct {

}

Type_Tuple :: struct {

}

Type_Bit_Set :: struct {

}

Type_Simd_Vector :: struct {

}

Type_Relative_Pointer :: struct {

}

Type_Relative_Slice :: struct {

}

Type_Matrix :: struct {

}

Type_Soa_Pointer :: struct {

}