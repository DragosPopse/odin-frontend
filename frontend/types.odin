package frontend

Type :: struct {
	variant: union {
		Type_Basic,
		Type_Named,
		Type_Struct,
		Type_Proc,
		Type_Generic,
		Type_Pointer,
		Type_Multi_Pointer,
		Type_Array,
		Type_Enumerated_Array,
		Type_Slice,
		Type_Dynamic_Array,
		Type_Map,
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
	node: ^Ast,
	scope: ^Scope,
	params: ^Type, // Type_Tuple
	results: ^Type, // Type_Tuple
	param_count: i32,
	result_count: i32,
	specialization_count: int,
	calling_convention: Calling_Convention,
	variadic_index: i32,
	flags: Proc_Flags,
}

Type_Named :: struct {
	name: string,
	base: ^Type,
	type_name: ^Entity, // Entity_Type_Name
}

Type_Generic :: struct {
	id: i64,
	name: string,
	specialized: ^Type,
	scope: ^Scope,
	entity: ^Entity,
}

Type_Pointer :: struct {
	elem: ^Type,
}

Type_Multi_Pointer :: struct {
	elem: ^Type,
}

Type_Array :: struct {
	elem: ^Type,
	count: i64, // Note(Dragos): These can probably become int types
	generic_count: ^Type,
}

Type_Enumerated_Array :: struct {
	elem: ^Type,
	index: ^Type,
	min_value: ^Exact_Value, // Note(Dragos): Could the exact value be a val instead of ptr?
	max_value: ^Exact_Value,
	count: i64,
	op: Token_Kind,
	is_sparse: bool,
}

Type_Slice :: struct {
	elem: ^Type,
}

Type_Dynamic_Array :: struct {
	elem: ^Type,
}

Type_Map :: struct {
	key: ^Type,
	value: ^Type,
	lookup_result_type: ^Type,
}

Type_Enum :: struct {
	fields: []^Entity,
	node: ^Ast,
	scope: ^Scope,
	base_type: ^Type,
	min_value: ^Exact_Value,
	max_value: ^Exact_Value,
	min_value_index: int,
	max_value_index: int,
}

Type_Tuple :: struct {
	variables: []^Entity,
	offsets: []i64,
	are_offsets_being_processed: bool,
	are_offsets_set: bool,
	is_packed: bool,
}

Type_Bit_Set :: struct {
	elem: ^Type,
	underlying: ^Type,
	lower: i64,
	upper: i64,
	node: ^Ast,
}

Type_Simd_Vector :: struct {
	count: i64,
	elem: ^Type,
	generic_count: ^Type,
}

Type_Relative_Pointer :: struct {
	pointer_type: ^Type,
	base_integer: ^Type,
}

Type_Relative_Slice :: struct {
	slice_type: ^Type,
	base_integer: ^Type,
}

Type_Matrix :: struct {
	elem: ^Type,
	row_count: i64,
	column_count: i64,
	generic_row_count: ^Type,
	generic_column_count: ^Type,
	stride_in_bytes: i64,
}

Type_Soa_Pointer :: struct {
	elem: ^Type,
}