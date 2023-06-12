package frontend

// Warning(Dragos): I think i forgot to do the multithreading work for this one

Type_Flag :: enum {
	Polymorphic,
	Poly_Specialized,
	In_Process_Of_Checking_Polymorphic,
}

Type_Flags :: bit_set[Type_Flag]

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
	cached_size: int,
	cached_align: int,
	flags: Type_Flags,
	failure: bool,
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
	No_Nil,
	Shared_Nil,
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

Typeid_Kind :: enum {
	Invalid,
	Integer,
	Rune,
	Float,
	Complex,
	Quaternion,
	String,
	Boolean,
	Any,
	Type_Id,
	Pointer,
	Multi_Pointer,
	Procedure,
	Array,
	Enumerated_Array,
	Dynamic_Array,
	Slice,
	Tuple,
	Struct,
	Union,
	Enum,
	Map,
	Bit_Set,
	Simd_Vector,
	Relative_Pointer,
	Relative_Slice,
	Matrix,
	SoaPointer,
}

Type_Info_Flag :: enum {
	Comparable     = 1<<0,
	Simple_Compare = 1<<1,
}

Type_Info_Flags :: bit_set[Type_Info_Flag]

MATRIX_ELEMENT_COUNT_MIN :: 1 
MATRIX_ELEMENT_COUNT_MAX :: 16
MATRIX_ELEMENT_MAX_SIZE :: MATRIX_ELEMENT_COUNT_MAX * (2 * 8) // complex128
SIMD_ELEMENT_COUNT_MIN :: 1
SIMD_ELEMENT_COUNT_MAX :: 64

is_type_comparable :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_simple_compare :: proc(t: ^Type) -> bool {
	unimplemented()
}

type_info_flags_of_type :: proc(type: ^Type) -> (flags: Type_Info_Flags) {
	if type == nil do return
	if is_type_comparable(type) do flags += {.Comparable}
	if is_type_simple_compare(type) do flags += {.Simple_Compare}
	return flags
}

Selection :: struct {
	entity: ^Entity,
	// Note(Dragos): Array seems to be a [dynamic]array in the compiler
	index: [dynamic]int, // Note(Dragos): What this Array thing? Is it a small array? or slice? We'll see
	indirect: bool,       // Set if there was a pointer deref anywhere down the line
	swizzle_count: u8,    // maximum components = 4
	swizle_indices: u8,   // 2 bits per component, representing which swizzle index
	pseudo_field: bool,
}

empty_selection := Selection{}

make_selection :: proc(entity: ^Entity, index: [dynamic]int, indirect: bool) -> Selection {
	return Selection{entity, index, indirect, 0, 0, false}
}

selection_add_index :: proc(s: ^Selection, index: int) {
	append(&s.index, index)
}

selection_combine :: proc(lhs: Selection, rhs: Selection) -> Selection {
	unimplemented()
}

sub_selection :: proc(sel: Selection, offset: int) -> Selection {
	unimplemented()
}

Odin_Atomic_Memory_Order :: enum {
	relaxed = 0, // unordered
	consume = 1, // monotonic
	acquire = 2,
	release = 3,
	acq_rel = 4,
	seq_cst = 5,
	COUNT,
};

type_size_of :: proc(t: ^Type) -> int {
	unimplemented()
}

type_align_of :: proc(t: ^Type) -> int {
	unimplemented()
}

type_offset_of :: proc(t: ^Type, index: int) -> int {
	unimplemented()
}

type_to_string :: proc(t: ^Type, shorthand: bool, allocator := context.allocator) -> string {
	unimplemented()
}

init_map_internal_types :: proc(type: ^Type) {
	unimplemented()
}

bit_set_to_int :: proc(t: ^Type) -> ^Type {
	unimplemented()
}

are_types_identical :: proc(x: ^Type, y: ^Type) -> bool {
	unimplemented()
}

is_type_pointer :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_soa_pointer :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_proc :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Proc;
}

is_type_slice :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Slice;
}

is_type_integer :: proc(arg_t: ^Type) -> bool {
	t := base_type(arg_t)
	basic, is_basic := t.variant.(Type_Basic)
	if is_basic {
		return (basic.flags & {.Integer}) != bit_set[Basic_Flag]{};
	}
	return false;
}

type_set_offsets :: proc(t: ^Type) -> bool {
	unimplemented()
}

import "core:reflect";

base_type :: proc(arg_t: ^Type) -> ^Type {
	t := arg_t
	for {
		if (t == nil) {
			break
		}
		named, is_named := t.variant.(Type_Named)
		if (!is_named) {
			break
		}
		if (t == named.base) {
			return t_invalid
		}
		t = t.variant.(Type_Named).base
	}
	return t;
}

type_size_of_internal :: proc(t: ^Type, path: ^Type_Path) -> int {
	unimplemented()
}

type_align_of_internal :: proc(t: ^Type, path: ^Type_Path) -> int {
	unimplemented()
}

Type_Path :: struct {
	path: [dynamic]^Entity, // Entity_TypeName
	failure: bool,
}

type_path_init :: proc(tp: ^Type_Path) {
	unimplemented()
}

type_path_free :: proc(tp: ^Type_Path) {
	unimplemented()
}

type_path_print_illegal_cycle :: proc(tp: ^Type_Path, start_index: int) {
	unimplemented("This needs to be rethinked since we might want to reroute printing")
}

type_path_push :: proc(tp: ^Type_Path, t: ^Type) -> bool {
	unimplemented()
}

type_path_pop :: proc(tp: ^Type_Path) {
	unimplemented()
}

FAILURE_SIZE :: 0
FAILURE_ALIGNMENT :: 0

Type_Ptr_Set :: map[^Type]bool

type_ptr_set_update :: proc(s: ^Type_Ptr_Set, t: ^Type) -> bool {
	unimplemented()
}

type_ptr_set_exists :: proc(s: ^Type_Ptr_Set, t: ^Type) -> bool {
	unimplemented()
}

base_enum_type :: proc(t: ^Type) -> ^Type {
	unimplemented()
}

core_type :: proc(t: ^Type) -> ^Type {
	unimplemented()
}

set_base_type :: proc(t: ^Type, base: ^Type) {
	unimplemented()
}

alloc_type :: proc(variant: $T) -> ^Type {
	unimplemented()
}

alloc_type_generic :: proc(scope: ^Scope, id: i64, name: string, specialized: ^Type) -> ^Type {
	unimplemented()
}

alloc_type_pointer :: proc(elem: ^Type) -> ^Type {
	unimplemented()
}

alloc_type_multi_pointer :: proc(elem: ^Type) -> ^Type {
	unimplemented()
}

alloc_type_soa_pointer :: proc(elem: ^Type) -> ^Type {
	unimplemented()
}

alloc_type_array :: proc(elem: ^Type, count: int, generic_count: ^Type = nil) -> ^Type {
	unimplemented()
}

alloc_type_matrix :: proc(elem: ^Type, row_count: int, column_count: int, generic_row_count: ^Type, generic_column_count: ^Type) -> ^Type {
	unimplemented()
}

alloc_type_enumerated_array :: proc(elem: ^Type, index: ^Type, min_value: ^Exact_Value, max_value: ^Exact_Value, op: Token_Kind) -> ^Type {
	unimplemented()
}

alloc_type_slice :: proc(elem: ^Type) -> ^Type {
	unimplemented()
}

alloc_type_dynamic_array :: proc(elem: ^Type) -> ^Type {
	unimplemented()
}

alloc_type_struct :: proc() -> ^Type {
	unimplemented()
}

alloc_type_union :: proc() -> ^Type {
	unimplemented()
}

alloc_type_enum :: proc() -> ^Type {
	unimplemented()
}

alloc_type_relative_pointer :: proc(pointer_type: ^Type, base_integer: ^Type) -> ^Type {
	unimplemented()
}

alloc_type_relative_slice :: proc(slice_type: ^Type, base_integer: ^Type) -> ^Type {
	unimplemented()
}

alloc_type_named :: proc(name: string, base: ^Type, type_name: ^Entity) {
	unimplemented()
}

is_calling_convention_none :: proc(c: Calling_Convention) -> bool {
	unimplemented()
}

is_calling_convention_odin :: proc(c: Calling_Convention) -> bool {
	unimplemented()
}

alloc_type_tuple :: proc() -> ^Type {
	unimplemented()
}

alloc_type_proc :: proc(scope: ^Scope, params: ^Type, param_count: int, results: ^Type, result_count: int, variadic: bool, calling_conv: Calling_Convention) -> ^Type {
	unimplemented()
}

is_type_valid_for_keys :: proc(t: ^Type) -> bool {
	unimplemented()
}

alloc_type_bit_set :: proc() -> ^Type {
	unimplemented()
}

alloc_type_simd_vector :: proc(count: int, elem: ^Type, generic_count: ^Type = nil) -> ^Type {
	unimplemented()
}

type_deref :: proc(t: ^Type, allow_multi_pointer := false) -> ^Type {
	unimplemented()
}

is_type_named :: proc(t: ^Type) -> bool {
	_, is_basic := t.variant.(Type_Basic)
	if is_basic do return true;
	_, is_named := t.variant.(Type_Named)
	return is_named;
}

is_type_boolean :: proc(arg_t: ^Type) -> bool {
	t := base_type(arg_t)
	basic, is_basic := t.variant.(Type_Basic)
	if is_basic {
		return (basic.flags & {.Boolean}) != bit_set[Basic_Flag]{};
	}
	return false;
}

is_type_integer_like :: proc(t: ^Type) -> bool {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & (BasicFlag_Integer|BasicFlag_Boolean)) != 0;
	}
	if (t->kind == Type_BitSet) {
		if (t->BitSet.underlying) {
			return is_type_integer_like(t->BitSet.underlying);
		}
		return true;
	}
	return false;
}

is_type_unsigned :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_integer_128bit :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Integer) != 0 && t->Basic.size == 16;
	}
	return false;
}

is_type_rune :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Rune) != 0;
	}
	return false;
}

is_type_numeric :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_string :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_String) != 0;
	}
	return false;
}

is_type_cstring :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return t->Basic.kind == Basic_cstring;
	}
	return false;
}

is_type_typed :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t == nullptr) {
		return false;
	}
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Untyped) == 0;
	}
	return true;
}

is_type_untyped :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t == nullptr) {
		return false;
	}
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Untyped) != 0;
	}
	return false;
}

is_type_ordered :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_ordered_numeric :: proc(t: ^Type) -> bool {
	t = core_type(t);
	switch (t->kind) {
	case Type_Basic:
		return (t->Basic.flags & BasicFlag_OrderedNumeric) != 0;
	}
	return false;
}

is_type_constant_type :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_float :: proc(t: ^Type) -> bool {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Float) != 0;
	}
	return false;
}

is_type_complex :: proc(t: ^Type) -> bool {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Complex) != 0;
	}
	return false;
}

is_type_quaternion :: proc(t: ^Type) -> bool {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Quaternion) != 0;
	}
	return false;
}

is_type_complex_or_quaternion :: proc(t: ^Type) -> bool {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & (BasicFlag_Complex|BasicFlag_Quaternion)) != 0;
	}
	return false;
}

is_type_multi_pointer :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_MultiPointer;
}

is_type_internally_pointer_like :: proc(t: ^Type) -> bool {
	return is_type_pointer(t) || is_type_multi_pointer(t) || is_type_cstring(t) || is_type_proc(t);
}

is_type_tuple :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Tuple;
}

is_type_uintptr :: proc(t: ^Type) -> bool {
	if (t->kind == Type_Basic) {
		return (t->Basic.kind == Basic_uintptr);
	}
	return false;
}

is_type_u8 :: proc(t: ^Type) -> bool {
	if (t->kind == Type_Basic) {
		return t->Basic.kind == Basic_u8;
	}
	return false;
}

is_type_array :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Array;
}

is_type_enumerated_array :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_EnumeratedArray;
}

is_type_matrix :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Matrix;
}

matrix_align_of :: proc(t: ^Type, tp: ^Type_Path) -> int {
	unimplemented()
}

matrix_type_stride_in_bytes :: proc(t: ^Type, tp: ^Type_Path) -> int {
	unimplemented()
}

matrix_type_total_internal_elems :: proc(t: ^Type) -> int {
	unimplemented()
}

matrix_indices_to_offset :: proc(t: ^Type, row_index: int, column_index: int) -> int {
	unimplemented()
}

matrix_row_major_index_to_offset :: proc(t: ^Type, index: int) -> int {
	unimplemented()
}

matrix_column_major_index_to_offset :: proc(t: ^Type, index: int) -> int {
	unimplemented()
}

is_matrix_square :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_valid_for_matrix_elems :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_dynamic_array :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_DynamicArray;
}

is_type_asm_proc :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Proc && t->Proc.calling_convention == ProcCC_InlineAsm;
}

is_type_simd_vector :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_SimdVector;
}

base_array_type :: proc(t: ^Type) -> ^Type {
	Type *bt = base_type(t);
	if (is_type_array(bt)) {
		return bt->Array.elem;
	} else if (is_type_enumerated_array(bt)) {
		return bt->EnumeratedArray.elem;
	} else if (is_type_simd_vector(bt)) {
		return bt->SimdVector.elem;
	} else if (is_type_matrix(bt)) {
		return bt->Matrix.elem;
	}
	return t;
}

is_type_generic :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Generic;
}

is_type_relative_pointer :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_RelativePointer;
}

is_type_relative_slice :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_RelativeSlice;
}

is_type_u8_slice :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_Slice) {
		return is_type_u8(t->Slice.elem);
	}
	return false;
}

is_type_u8_array :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_Array) {
		return is_type_u8(t->Array.elem);
	}
	return false;
}

is_type_u8_ptr :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_Pointer) {
		return is_type_u8(t->Slice.elem);
	}
	return false;
}

is_type_u8_multi_ptr :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_MultiPointer) {
		return is_type_u8(t->Slice.elem);
	}
	return false;
}

is_type_rune_array :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_Array) {
		return is_type_rune(t->Array.elem);
	}
	return false;
}

is_type_array_like :: proc(t: ^Type) -> bool {
	return is_type_array(t) || is_type_enumerated_array(t);
}

core_array_type :: proc(t: ^Type) -> ^Type {
	unimplemented()
}

type_math_rank :: proc(t: ^Type) -> int {
	unimplemented()
}

base_complex_elem_type :: proc(t: ^Type) -> ^Type {
	unimplemented()
}

is_type_struct :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Struct;
}

is_type_union :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Union;
}

is_type_soa_struct :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Struct && t->Struct.soa_kind != StructSoa_None;
}

is_type_raw_union :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return (t->kind == Type_Struct && t->Struct.is_raw_union);
}

is_type_enum :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return (t->kind == Type_Enum);
}

is_type_bit_set :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return (t->kind == Type_BitSet);
}

is_type_map :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Map;
}

is_type_union_maybe_pointer :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_Union && t->Union.variants.count == 1) {
		Type *v = t->Union.variants[0];
		return is_type_internally_pointer_like(v);
	}
	return false;
}

is_type_union_maybe_pointer_original_alignment :: proc(t: ^Type) -> bool {
	t = base_type(t);
	if (t->kind == Type_Union && t->Union.variants.count == 1) {
		Type *v = t->Union.variants[0];
		if (is_type_internally_pointer_like(v)) {
			return type_align_of(v) == type_align_of(t);
		}
	}
	return false;
}

is_type_endian_big :: proc(t: ^Type) -> bool {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		if (t->Basic.flags & BasicFlag_EndianBig) {
			return true;
		} else if (t->Basic.flags & BasicFlag_EndianLittle) {
			return false;
		}
		return build_context.endian_kind == TargetEndian_Big;
	} else if (t->kind == Type_BitSet) {
		return is_type_endian_big(bit_set_to_int(t));
	} else if (t->kind == Type_Pointer) {
		return is_type_endian_big(&basic_types[Basic_uintptr]);
	}
	return build_context.endian_kind == TargetEndian_Big;
}

is_type_endian_little :: proc(t: ^Type) -> bool {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		if (t->Basic.flags & BasicFlag_EndianLittle) {
			return true;
		} else if (t->Basic.flags & BasicFlag_EndianBig) {
			return false;
		}
		return build_context.endian_kind == TargetEndian_Little;
	} else if (t->kind == Type_BitSet) {
		return is_type_endian_little(bit_set_to_int(t));
	} else if (t->kind == Type_Pointer) {
		return is_type_endian_little(&basic_types[Basic_uintptr]);
	}
	return build_context.endian_kind == TargetEndian_Little;
}

is_type_endian_platform :: proc(t: ^Type) -> bool {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & (BasicFlag_EndianLittle|BasicFlag_EndianBig)) == 0;
	} else if (t->kind == Type_BitSet) {
		return is_type_endian_platform(bit_set_to_int(t));
	} else if (t->kind == Type_Pointer) {
		return is_type_endian_platform(&basic_types[Basic_uintptr]);
	}
	return false;
}

types_have_same_internal_endian :: proc(a: ^Type, b: ^Type) -> bool {
	return is_type_endian_little(a) == is_type_endian_little(b);
}

is_type_endian_specific :: proc(t: ^Type) -> bool {
	t = core_type(t);
	if (t->kind == Type_BitSet) {
		t = bit_set_to_int(t);
	}
	if (t->kind == Type_Basic) {
		switch (t->Basic.kind) {
		case Basic_i16le:
		case Basic_u16le:
		case Basic_i32le:
		case Basic_u32le:
		case Basic_i64le:
		case Basic_u64le:
		case Basic_u128le:
			return true;

		case Basic_i16be:
		case Basic_u16be:
		case Basic_i32be:
		case Basic_u32be:
		case Basic_i64be:
		case Basic_u64be:
		case Basic_u128be:
			return true;

		case Basic_f16le:
		case Basic_f16be:
		case Basic_f32le:
		case Basic_f32be:
		case Basic_f64le:
		case Basic_f64be:
			return true;
		}
	}

	return false;
}

is_type_dereferenceable :: proc(t: ^Type) -> bool {
	if (is_type_rawptr(t)) {
		return false;
	}
	return is_type_pointer(t) || is_type_soa_pointer(t);
}

is_type_different_to_arch_endianness :: proc(t: ^Type) -> bool {
	switch (build_context.endian_kind) {
		case TargetEndian_Little:
			return !is_type_endian_little(t);
		case TargetEndian_Big:
			return !is_type_endian_big(t);
		}
		return false;
}

integer_endian_type_to_platform_type :: proc(t: ^Type) -> ^Type {
	t = core_type(t);
	if (t->kind == Type_BitSet) {
		t = bit_set_to_int(t);
	}
	GB_ASSERT_MSG(t->kind == Type_Basic, "%s", type_to_string(t));

	switch (t->Basic.kind) {
	// Endian Specific Types
	case Basic_i16le: return t_i16;
	case Basic_u16le: return t_u16;
	case Basic_i32le: return t_i32;
	case Basic_u32le: return t_u32;
	case Basic_i64le: return t_i64;
	case Basic_u64le: return t_u64;
	case Basic_i128le: return t_i128;
	case Basic_u128le: return t_u128;

	case Basic_i16be: return t_i16;
	case Basic_u16be: return t_u16;
	case Basic_i32be: return t_i32;
	case Basic_u32be: return t_u32;
	case Basic_i64be: return t_i64;
	case Basic_u64be: return t_u64;
	case Basic_i128be: return t_i128;
	case Basic_u128be: return t_u128;

	case Basic_f16le: return t_f16;
	case Basic_f16be: return t_f16;
	case Basic_f32le: return t_f32;
	case Basic_f32be: return t_f32;
	case Basic_f64le: return t_f64;
	case Basic_f64be: return t_f64;
	}

	return t;
}

is_type_any :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_any);
}

is_type_typeid :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_typeid);
}

is_type_untyped_nil :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_UntypedNil);
}

is_type_untyped_undef :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_UntypedUndef);
}

is_type_untyped_uninit :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_empty_union :: proc(t: ^Type) -> bool {
	t = base_type(t);
	return t->kind == Type_Union && t->Union.variants.count == 0;
}

is_type_valid_bit_set_elem :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_valid_vector_elem :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_indexable :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_sliceable :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_polymorphic_record :: proc(t: ^Type) -> bool {
	unimplemented()
}

polymorphic_record_parent_scope :: proc(t: ^Type) -> ^Scope {
	unimplemented()
}

is_type_polymorphic_record_specialized :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_polymorphic_record_unspecialized :: proc(t: ^Type) -> bool {
	unimplemented()
}

get_record_polymorphic_params :: proc(t: ^Type) -> ^Type_Tuple {
	unimplemented()
}

is_type_polymorphic :: proc(t: ^Type) -> bool {
	unimplemented()
}

type_has_nil :: proc(t: ^Type) -> bool {
	unimplemented()
}

elem_type_can_be_constant :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_lock_free :: proc(t: ^Type) -> bool {
	unimplemented()
}

is_type_load_safe :: proc(t: ^Type) -> bool {
	unimplemented()
}

lookup_subtype_polymorphic_field :: proc(dst: ^Type, src: ^Type) -> string {
	unimplemented()
}

lookup_subtype_polymorphic_selection :: proc(dst: ^Type, src: ^Type, sel: ^Selection) -> bool {
	unimplemented()
}

are_types_identical_internal :: proc(x: ^Type, y: ^Type, check_tuple_names: bool) -> bool {
	unimplemented()
}

are_types_identical_unique_tuples :: proc(x: ^Type, y: ^Type) -> bool {
	unimplemented()
}

default_type :: proc(t: ^Type) -> ^Type {
	unimplemented()
}

union_variant_index_types_equal :: proc(v: ^Type, vt: ^Type) -> bool {
	unimplemented()
}

union_variant_index :: proc(u: ^Type, v: ^Type) -> int {
	unimplemented()
}

union_tag_size :: proc(u: ^Type) -> int {
	unimplemented()
}

union_tag_type :: proc(u: ^Type) -> ^Type {
	i64 s = union_tag_size(u);
	switch (s) {
	case  0: return  t_u8;
	case  1: return  t_u8;
	case  2: return  t_u16;
	case  4: return  t_u32;
	case  8: return  t_u64;
	}
	GB_PANIC("Invalid union_tag_size");
	return t_uint;
}

Proc_Type_Overload_Kind :: enum {
	Identical, // The types are identical
	Calling_Convention,
	Param_Count,
	Param_Variadic,
	Param_Types,
	Result_Count,
	Result_Types,
	Polymorphic,
	Not_Procedure,	
}

are_proc_types_overload_safe :: proc(x: ^Type, y: ^Type) -> Proc_Type_Overload_Kind {
	//Do later
	unimplemented()
}

lookup_field_with_selection :: proc(type_: ^Type, field_name: string, is_type: bool, sel: Selection, allow_blank_ident := false) -> Selection {
	//Do later
	unimplemented()
}

lookup_field :: proc(type_: ^Type, field_name: string, is_type: bool, allow_blank_ident := false) -> Selection {
	//Do later
	unimplemented()
}

lookup_field_from_index :: proc(type: ^Type, index: int) -> Selection {
	//Do later
	unimplemented()
}

has_type_got_objc_class_attribute :: proc(t: ^Type) -> bool {
	return t->kind == Type_Named && t->Named.type_name != nullptr && t->Named.type_name->TypeName.objc_class_name != "";
}

are_struct_fields_reordered :: proc(t: ^Type) -> bool {
	type = base_type(type);
	GB_ASSERT(type->kind == Type_Struct);
	type_set_offsets(type);
	GB_ASSERT(type->Struct.offsets != nullptr);
	
	i64 prev_offset = 0;
	for_array(i, type->Struct.fields) {
		i64 offset = type->Struct.offsets[i];
		if (prev_offset > offset) {
			return true;
		}
		prev_offset = offset;
	}

	return false;
}

struct_fields_index_by_increasing_offset :: proc(t: ^Type, allocator := context.allocator) -> []int {
	//Do later
	unimplemented()
}

type_align_of_internal :: proc(t: ^Type, path: ^Type_Path) -> int {
	//Do later
	unimplemented()
}

type_size_of_struct_pretend_is_packed :: proc(ot: ^Type) -> int {
	//Do later
	unimplemented()
}

type_set_offsets_of :: proc(fields: []^Entity, is_packed: bool, is_raw_union: bool) -> ^int {
	//Do later
	unimplemented()
}

type_offset_of_from_selection :: proc(t: ^Type, sel: Selection) -> int {
	//Do later
	unimplemented()
}

check_is_assignable_to_using_subtype :: proc(src: ^Type, dst: ^Type, level := 0, src_is_ptr := false) -> int {
	//Do later
	unimplemented()
}

is_type_subtype_of :: proc(src: ^Type, dst: ^Type) -> bool {
	//Do later
	unimplemented()
}

alloc_type_tuple_from_field_types :: proc(field_types: []^Type, is_packed, must_be_tuple: bool) -> ^Type {
	//Do later
	unimplemented()
}

alloc_type_proc_from_types :: proc(param_types: []^Type, results: []^Type, is_c_vararg: bool, calling_conv: Calling_Convention) -> ^Type {
	//Do later
	unimplemented()
}

write_type_to_string :: proc(str: string, type: ^Type, shorthand := false) -> string {
	//do later
	unimplemented()
}