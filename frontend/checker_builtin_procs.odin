package frontend


Builtin_Proc_Id :: enum {
    Invalid,

	len,
	cap,

	size_of,
	align_of,
	offset_of,
	offset_of_by_string,
	type_of,
	type_info_of,
	typeid_of,


	swizzle,

	complex,
	quaternion,
	real,
	imag,
	jmag,
	kmag,
	conj,

	expand_values,

	min,
	max,
	abs,
	clamp,

	soa_zip,
	soa_unzip,

	transpose,
	outer_product,
	hadamard_product,
	matrix_flatten,

	unreachable,

	raw_data,

	DIRECTIVE, // NOTE(bill : This is used for specialized hash-prefixed procedures

	// "Intrinsics"
	is_package_imported,

	soa_struct,

	alloca,
	cpu_relax,
	trap,
	debug_trap,
	read_cycle_counter,

	count_ones,
	count_zeros,
	count_trailing_zeros,
	count_leading_zeros,
	reverse_bits,
	byte_swap,

	overflow_add,
	overflow_sub,
	overflow_mul,

	sqrt,
	fused_mul_add,

	mem_copy,
	mem_copy_non_overlapping,
	mem_zero,
	mem_zero_volatile,

	ptr_offset,
	ptr_sub,

	volatile_store,
	volatile_load,
	
	unaligned_store,
	unaligned_load,
	non_temporal_store,
	non_temporal_load,
	
	prefetch_read_instruction,
	prefetch_read_data,
	prefetch_write_instruction,
	prefetch_write_data,

	atomic_type_is_lock_free,
	atomic_thread_fence,
	atomic_signal_fence,
	atomic_store,
	atomic_store_explicit,
	atomic_load,
	atomic_load_explicit,
	atomic_add,
	atomic_add_explicit,
	atomic_sub,
	atomic_sub_explicit,
	atomic_and,
	atomic_and_explicit,
	atomic_nand,
	atomic_nand_explicit,
	atomic_or,
	atomic_or_explicit,
	atomic_xor,
	atomic_xor_explicit,
	atomic_exchange,
	atomic_exchange_explicit,
	atomic_compare_exchange_strong,
	atomic_compare_exchange_strong_explicit,
	atomic_compare_exchange_weak,
	atomic_compare_exchange_weak_explicit,

	fixed_point_mul,
	fixed_point_div,
	fixed_point_mul_sat,
	fixed_point_div_sat,

	expect,

_simd_begin,
	simd_add,
	simd_sub,
	simd_mul,
	simd_div,
	simd_rem,
	simd_shl,        // Odin logic
	simd_shr,        // Odin logic
	simd_shl_masked, // C logic
	simd_shr_masked, // C logic

	simd_add_sat, // saturation arithmetic
	simd_sub_sat, // saturation arithmetic

	simd_and,
	simd_or,
	simd_xor,
	simd_and_not,

	simd_neg,
	simd_abs,

	simd_min,
	simd_max,
	simd_clamp,

	simd_lanes_eq,
	simd_lanes_ne,
	simd_lanes_lt,
	simd_lanes_le,
	simd_lanes_gt,
	simd_lanes_ge,

	simd_extract,
	simd_replace,

	simd_reduce_add_ordered,
	simd_reduce_mul_ordered,
	simd_reduce_min,
	simd_reduce_max,
	simd_reduce_and,
	simd_reduce_or,
	simd_reduce_xor,

	simd_shuffle,
	simd_select,

	simd_ceil,
	simd_floor,
	simd_trunc,
	simd_nearest,

	simd_to_bits,

	simd_lanes_reverse,
	simd_lanes_rotate_left,
	simd_lanes_rotate_right,


	// Platform specific SIMD intrinsics
	simd_x86__MM_SHUFFLE,
_simd_end,
	
	// Platform specific intrinsics
	syscall,

	x86_cpuid,
	x86_xgetbv,

	// Constant type tests

_type_begin,

	type_base_type,
	type_core_type,
	type_elem_type,

	type_convert_variants_to_pointers,
	type_merge,

_type_simple_boolean_begin,
	type_is_boolean,
	type_is_integer,
	type_is_rune,
	type_is_float,
	type_is_complex,
	type_is_quaternion,
	type_is_string,
	type_is_typeid,
	type_is_any,

	type_is_endian_platform,
	type_is_endian_little,
	type_is_endian_big,
	type_is_unsigned,
	type_is_numeric,
	type_is_ordered,
	type_is_ordered_numeric,
	type_is_indexable,
	type_is_sliceable,
	type_is_comparable,
	type_is_simple_compare, // easily compared using memcmp
	type_is_dereferenceable,
	type_is_valid_map_key,
	type_is_valid_matrix_elements,

	type_is_named,
	type_is_pointer,
	type_is_multi_pointer,
	type_is_array,
	type_is_enumerated_array,
	type_is_slice,
	type_is_dynamic_array,
	type_is_map,
	type_is_struct,
	type_is_union,
	type_is_enum,
	type_is_proc,
	type_is_bit_set,
	type_is_simd_vector,
	type_is_matrix,

	type_is_specialized_polymorphic_record,
	type_is_unspecialized_polymorphic_record,

	type_has_nil,

_type_simple_boolean_end,

	type_has_field,
	type_field_type,

	type_is_specialization_of,

	type_is_variant_of,

	type_struct_field_count,

	type_proc_parameter_count,
	type_proc_return_count,

	type_proc_parameter_type,
	type_proc_return_type,

	type_polymorphic_record_parameter_count,
	type_polymorphic_record_parameter_value,

	type_is_subtype_of,

	type_field_index_of,

	type_equal_proc,
	type_hasher_proc,
	type_map_info,
	type_map_cell_info,

_type_end,

	__entry_point,

	objc_send,
	objc_find_selector,
	objc_find_class,
	objc_register_selector,
	objc_register_class,

	constant_utf16_cstring,

	wasm_memory_grow,
	wasm_memory_size,
	wasm_memory_atomic_wait32,
	wasm_memory_atomic_notify32,

	valgrind_client_request,
}

builtin_procs :: [Builtin_Proc_Id]Builtin_Proc {
	.Invalid = {"",                 0, false,  .Stmt,  .Builtin, false, false},

	.len = {"len",              1, false,  .Expr,  .Builtin, false, false},
	.cap = {"cap",              1, false,  .Expr,  .Builtin, false, false},

	.size_of = {"size_of",          1, false,  .Expr,  .Builtin, false, false},
	.align_of = {"align_of",         1, false,  .Expr,  .Builtin, false, false},
	.offset_of = {"offset_of",        1, true,   .Expr,  .Builtin, false, false},
	.offset_of_by_string = {"offset_of_by_string",2, false,  .Expr,  .Builtin, false, false},
	.type_of = {"type_of",          1, false,  .Expr,  .Builtin, false, false},
	.type_info_of = {"type_info_of",     1, false,  .Expr,  .Builtin, false, false},
	.typeid_of = {"typeid_of",        1, false,  .Expr,  .Builtin, false, false},

	.swizzle = {"swizzle",          1, true,   .Expr,  .Builtin, false, false},

	.complex = {"complex" ,          2, false,  .Expr,  .Builtin, false, false},
	.quaternion = {"quaternion" ,       4, false,  .Expr,  .Builtin, false, false},
	.real = {"real" ,             1, false,  .Expr,  .Builtin, false, false},
	.imag = {"imag" ,             1, false,  .Expr,  .Builtin, false, false},
	.jmag = {"jmag" ,             1, false,  .Expr,  .Builtin, false, false},
	.kmag = {"kmag" ,             1, false,  .Expr,  .Builtin, false, false},
	.conj = {"conj" ,             1, false,  .Expr,  .Builtin, false, false},

	.expand_values = {"expand_values" ,    1, false,  .Expr,  .Builtin, false, false},

	.min = {"min" ,              1, true,   .Expr,  .Builtin, false, false},
	.max = {"max" ,              1, true,   .Expr,  .Builtin, false, false},
	.abs = {"abs" ,              1, false,  .Expr,  .Builtin, false, false},
	.clamp = {"clamp" ,            3, false,  .Expr,  .Builtin, false, false},

	.soa_zip = {"soa_zip" ,          1, true,   .Expr,  .Builtin, false, false},
	.soa_unzip = {"soa_unzip" ,        1, false,  .Expr,  .Builtin, false, false},
	
	.transpose = {"transpose" ,        1, false,  .Expr,  .Builtin, false, false},
	.outer_product = {"outer_product" ,    2, false,  .Expr,  .Builtin, false, false},
	.hadamard_product = {"hadamard_product" , 2, false,  .Expr,  .Builtin, false, false},
	.matrix_flatten = {"matrix_flatten" ,   1, false,  .Expr,  .Builtin, false, false},

	.unreachable = {"unreachable" ,      0, false,  .Expr,  .Builtin, /*diverging*/true, false},

	.raw_data = {"raw_data" ,         1, false,  .Expr,  .Builtin, false, false},

	.DIRECTIVE = {"" ,                 0, true,   .Expr,  .Builtin, false, false}, // DIRECTIVE


	.is_package_imported = {"is_package_imported" , 1, false,  .Expr,  .Intrinsics, false, false},
	
	.soa_struct = {"soa_struct" ,  2, false,  .Expr,  .Intrinsics, false, false}, // Type

	.alloca = {"alloca" ,    2, false,  .Expr,  .Intrinsics, false, false},
	.cpu_relax = {"cpu_relax" , 0, false,  .Stmt,  .Intrinsics, false, false},

	.trap = {"trap" ,               0, false,  .Expr,  .Intrinsics, /*diverging*/true, false},
	.debug_trap = {"debug_trap" ,         0, false,  .Stmt,  .Intrinsics, /*diverging*/false, false},
	.read_cycle_counter = {"read_cycle_counter" , 0, false,  .Expr,  .Intrinsics, false, false},

	.count_ones = {"count_ones" ,           1, false,  .Expr,  .Intrinsics, false, false},
	.count_zeros = {"count_zeros" ,          1, false,  .Expr,  .Intrinsics, false, false},
	.count_trailing_zeros = {"count_trailing_zeros" , 1, false,  .Expr,  .Intrinsics, false, false},
	.count_leading_zeros = {"count_leading_zeros" ,  1, false,  .Expr,  .Intrinsics, false, false},
	.reverse_bits = {"reverse_bits" ,         1, false,  .Expr,  .Intrinsics, false, false},
	.byte_swap = {"byte_swap" ,            1, false,  .Expr,  .Intrinsics, false, false},

	.overflow_add = {"overflow_add" , 2, false,  .Expr,  .Intrinsics, false, false},
	.overflow_sub = {"overflow_sub" , 2, false,  .Expr,  .Intrinsics, false, false},
	.overflow_mul = {"overflow_mul" , 2, false,  .Expr,  .Intrinsics, false, false},

	.sqrt = {"sqrt" , 1, false,  .Expr,  .Intrinsics, false, false},
	.fused_mul_add = {"fused_mul_add" , 3, false,  .Expr,  .Intrinsics, false, false},

	.mem_copy = {"mem_copy" ,                 3, false,  .Stmt,  .Intrinsics, false, false},
	.mem_copy_non_overlapping = {"mem_copy_non_overlapping" , 3, false,  .Stmt,  .Intrinsics, false, false},
	.mem_zero = {"mem_zero" ,                 2, false,  .Stmt,  .Intrinsics, false, false},
	.mem_zero_volatile = {"mem_zero_volatile" ,        2, false,  .Stmt,  .Intrinsics, false, false},

	.ptr_offset = {"ptr_offset" , 2, false,  .Expr,  .Intrinsics, false, false},
	.ptr_sub = {"ptr_sub" ,    2, false,  .Expr,  .Intrinsics, false, false},

	.volatile_store = {"volatile_store" ,  2, false,  .Stmt,  .Intrinsics, false, false},
	.volatile_load = {"volatile_load" ,   1, false,  .Expr,  .Intrinsics, false, false},
	
	.unaligned_store = {"unaligned_store" ,  2, false,  .Stmt,  .Intrinsics, false, false},
	.unaligned_load = {"unaligned_load" ,   1, false,  .Expr,  .Intrinsics, false, false},
	.non_temporal_store = {"non_temporal_store" ,  2, false,  .Stmt,  .Intrinsics, false, false},
	.non_temporal_load = {"non_temporal_load" ,   1, false,  .Expr,  .Intrinsics, false, false},
	
	.prefetch_read_instruction = {"prefetch_read_instruction" ,  2, false,  .Stmt,  .Intrinsics, false, false},
	.prefetch_read_data = {"prefetch_read_data" ,         2, false,  .Stmt,  .Intrinsics, false, false},
	.prefetch_write_instruction = {"prefetch_write_instruction" , 2, false,  .Stmt,  .Intrinsics, false, false},
	.prefetch_write_data = {"prefetch_write_data" ,        2, false,  .Stmt,  .Intrinsics, false, false},

	.atomic_type_is_lock_free = {"atomic_type_is_lock_free" ,                1, false,  .Expr,  .Intrinsics, false, false},
	.atomic_thread_fence = {"atomic_thread_fence" ,                     1, false,  .Stmt,  .Intrinsics, false, false},
	.atomic_signal_fence = {"atomic_signal_fence" ,                     1, false,  .Stmt,  .Intrinsics, false, false},
	.atomic_store = {"atomic_store" ,                            2, false,  .Stmt,  .Intrinsics, false, false},
	.atomic_store_explicit = {"atomic_store_explicit" ,                   3, false,  .Stmt,  .Intrinsics, false, false},
	.atomic_load = {"atomic_load" ,                             1, false,  .Expr,  .Intrinsics, false, true},
	.atomic_load_explicit = {"atomic_load_explicit" ,                    2, false,  .Expr,  .Intrinsics, false, true},
	.atomic_add = {"atomic_add" ,                              2, false,  .Expr,  .Intrinsics, false, true},
	.atomic_add_explicit = {"atomic_add_explicit" ,                     3, false,  .Expr,  .Intrinsics, false, true},
	.atomic_sub = {"atomic_sub" ,                              2, false,  .Expr,  .Intrinsics, false, true},
	.atomic_sub_explicit = {"atomic_sub_explicit" ,                     3, false,  .Expr,  .Intrinsics, false, true},
	.atomic_and = {"atomic_and" ,                              2, false,  .Expr,  .Intrinsics, false, true},
	.atomic_and_explicit = {"atomic_and_explicit" ,                     3, false,  .Expr,  .Intrinsics, false, true},
	.atomic_nand = {"atomic_nand" ,                             2, false,  .Expr,  .Intrinsics, false, true},
	.atomic_nand_explicit = {"atomic_nand_explicit" ,                    3, false,  .Expr,  .Intrinsics, false, true},
	.atomic_or = {"atomic_or" ,                               2, false,  .Expr,  .Intrinsics, false, true},
	.atomic_or_explicit = {"atomic_or_explicit" ,                      3, false,  .Expr,  .Intrinsics, false, true},
	.atomic_xor = {"atomic_xor" ,                              2, false,  .Expr,  .Intrinsics, false, true},
	.atomic_xor_explicit = {"atomic_xor_explicit" ,                     3, false,  .Expr,  .Intrinsics, false, true},
	.atomic_exchange = {"atomic_exchange" ,                         2, false,  .Expr,  .Intrinsics, false, true},
	.atomic_exchange_explicit = {"atomic_exchange_explicit" ,                3, false,  .Expr,  .Intrinsics, false, true},
	.atomic_compare_exchange_strong = {"atomic_compare_exchange_strong" ,          3, false,  .Expr,  .Intrinsics, false, true},
	.atomic_compare_exchange_strong_explicit = {"atomic_compare_exchange_strong_explicit" , 5, false,  .Expr,  .Intrinsics, false, true},
	.atomic_compare_exchange_weak = {"atomic_compare_exchange_weak" ,            3, false,  .Expr,  .Intrinsics, false, true},
	.atomic_compare_exchange_weak_explicit = {"atomic_compare_exchange_weak_explicit" ,   5, false,  .Expr,  .Intrinsics, false, true},

	.fixed_point_mul = {"fixed_point_mul" , 3, false,  .Expr,  .Intrinsics, false, false},
	.fixed_point_div = {"fixed_point_div" , 3, false,  .Expr,  .Intrinsics, false, false},
	.fixed_point_mul_sat = {"fixed_point_mul_sat" , 3, false,  .Expr,  .Intrinsics, false, false},
	.fixed_point_div_sat = {"fixed_point_div_sat" , 3, false,  .Expr,  .Intrinsics, false, false},

	.expect = {"expect" , 2, false,  .Expr,  .Intrinsics, false, false},

	._simd_begin = {"" , 0, false,  .Stmt,  .Intrinsics, false, false},
	.simd_add = {"simd_add" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_sub = {"simd_sub" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_mul = {"simd_mul" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_div = {"simd_div" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_rem = {"simd_rem" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_shl = {"simd_shl" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_shr = {"simd_shr" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_shl_masked = {"simd_shl_masked" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_shr_masked = {"simd_shr_masked" , 2, false,  .Expr,  .Intrinsics, false, false},

	.simd_add_sat = {"simd_add_sat" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_sub_sat = {"simd_sub_sat" , 2, false,  .Expr,  .Intrinsics, false, false},

	.simd_and = {"simd_and" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_or = {"simd_or" ,  2, false,  .Expr,  .Intrinsics, false, false},
	.simd_xor = {"simd_xor" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_and_not = {"simd_and_not" , 2, false,  .Expr,  .Intrinsics, false, false},

	.simd_neg = {"simd_neg" , 1, false,  .Expr,  .Intrinsics, false, false},

	.simd_abs = {"simd_abs" , 1, false,  .Expr,  .Intrinsics, false, false},

	.simd_min = {"simd_min" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_max = {"simd_max" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_clamp = {"simd_clamp" , 3, false,  .Expr,  .Intrinsics, false, false},

	.simd_lanes_eq = {"simd_lanes_eq" ,  2, false,  .Expr,  .Intrinsics, false, false},
	.simd_lanes_ne = {"simd_lanes_ne" ,  2, false,  .Expr,  .Intrinsics, false, false},
	.simd_lanes_lt = {"simd_lanes_lt" ,  2, false,  .Expr,  .Intrinsics, false, false},
	.simd_lanes_le = {"simd_lanes_le" ,  2, false,  .Expr,  .Intrinsics, false, false},
	.simd_lanes_gt = {"simd_lanes_gt" ,  2, false,  .Expr,  .Intrinsics, false, false},
	.simd_lanes_ge = {"simd_lanes_ge" ,  2, false,  .Expr,  .Intrinsics, false, false},

	.simd_extract = {"simd_extract" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_replace = {"simd_replace" , 3, false,  .Expr,  .Intrinsics, false, false},

	.simd_reduce_add_ordered = {"simd_reduce_add_ordered" , 1, false,  .Expr,  .Intrinsics, false, false},
	.simd_reduce_mul_ordered = {"simd_reduce_mul_ordered" , 1, false,  .Expr,  .Intrinsics, false, false},
	.simd_reduce_min = {"simd_reduce_min" ,         1, false,  .Expr,  .Intrinsics, false, false},
	.simd_reduce_max = {"simd_reduce_max" ,         1, false,  .Expr,  .Intrinsics, false, false},
	.simd_reduce_and = {"simd_reduce_and" ,         1, false,  .Expr,  .Intrinsics, false, false},
	.simd_reduce_or = {"simd_reduce_or" ,          1, false,  .Expr,  .Intrinsics, false, false},
	.simd_reduce_xor = {"simd_reduce_xor" ,         1, false,  .Expr,  .Intrinsics, false, false},

	.simd_shuffle = {"simd_shuffle" , 2, true,   .Expr,  .Intrinsics, false, false},
	.simd_select = {"simd_select" ,  3, false,  .Expr,  .Intrinsics, false, false},

	.simd_ceil = {"simd_ceil"  , 1, false,  .Expr,  .Intrinsics, false, false},
	.simd_floor = {"simd_floor" , 1, false,  .Expr,  .Intrinsics, false, false},
	.simd_trunc = {"simd_trunc" , 1, false,  .Expr,  .Intrinsics, false, false},
	.simd_nearest = {"simd_nearest" , 1, false,  .Expr,  .Intrinsics, false, false},

	.simd_to_bits = {"simd_to_bits" , 1, false,  .Expr,  .Intrinsics, false, false},

	.simd_lanes_reverse = {"simd_lanes_reverse" , 1, false,  .Expr,  .Intrinsics, false, false},
	.simd_lanes_rotate_left = {"simd_lanes_rotate_left" , 2, false,  .Expr,  .Intrinsics, false, false},
	.simd_lanes_rotate_right = {"simd_lanes_rotate_right" , 2, false,  .Expr,  .Intrinsics, false, false},

	.simd_x86__MM_SHUFFLE = {"simd_x86__MM_SHUFFLE" , 4, false,  .Expr,  .Intrinsics, false, false},

	._simd_end = {"" , 0, false,  .Stmt,  .Intrinsics, false, false},


	.syscall = {"syscall" , 1, true,  .Expr,  .Intrinsics, false, true},
	.x86_cpuid = {"x86_cpuid" ,  2, false,  .Expr,  .Intrinsics, false, false},
	.x86_xgetbv = {"x86_xgetbv" , 1, false,  .Expr,  .Intrinsics, false, false},


	._type_begin = {"" , 0, false,  .Stmt,  .Intrinsics, false, false},
	.type_base_type = {"type_base_type" ,            1, false,  .Expr,  .Intrinsics, false, false},
	.type_core_type = {"type_core_type" ,            1, false,  .Expr,  .Intrinsics, false, false},
	.type_elem_type = {"type_elem_type" ,            1, false,  .Expr,  .Intrinsics, false, false},
	.type_convert_variants_to_pointers = {"type_convert_variants_to_pointers" , 1, false,  .Expr,  .Intrinsics, false, false},
	.type_merge = {"type_merge" ,                2, false,  .Expr,  .Intrinsics, false, false},

	._type_simple_boolean_begin = {"" , 0, false,  .Stmt,  .Intrinsics, false, false},
	.type_is_boolean = {"type_is_boolean" ,           1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_integer = {"type_is_integer" ,           1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_rune = {"type_is_rune" ,              1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_float = {"type_is_float" ,             1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_complex = {"type_is_complex" ,           1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_quaternion = {"type_is_quaternion" ,        1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_string = {"type_is_string" ,            1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_typeid = {"type_is_typeid" ,            1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_any = {"type_is_any" ,               1, false,  .Expr,  .Intrinsics, false, false},

	.type_is_endian_platform = {"type_is_endian_platform" ,   1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_endian_little = {"type_is_endian_little" ,     1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_endian_big = {"type_is_endian_big" ,        1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_unsigned = {"type_is_unsigned" ,          1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_numeric = {"type_is_numeric" ,           1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_ordered = {"type_is_ordered" ,           1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_ordered_numeric = {"type_is_ordered_numeric" ,   1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_indexable = {"type_is_indexable" ,         1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_sliceable = {"type_is_sliceable" ,         1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_comparable = {"type_is_comparable" ,        1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_simple_compare = {"type_is_simple_compare" ,    1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_dereferenceable = {"type_is_dereferenceable" ,   1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_valid_map_key = {"type_is_valid_map_key" ,     1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_valid_matrix_elements = {"type_is_valid_matrix_elements" , 1, false,  .Expr,  .Intrinsics, false, false},

	.type_is_named = {"type_is_named" ,             1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_pointer = {"type_is_pointer" ,           1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_multi_pointer = {"type_is_multi_pointer" ,      1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_array = {"type_is_array" ,             1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_enumerated_array = {"type_is_enumerated_array" ,  1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_slice = {"type_is_slice" ,             1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_dynamic_array = {"type_is_dynamic_array" ,     1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_map = {"type_is_map" ,               1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_struct = {"type_is_struct" ,            1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_union = {"type_is_union" ,             1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_enum = {"type_is_enum" ,              1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_proc = {"type_is_proc" ,              1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_bit_set = {"type_is_bit_set" ,           1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_simd_vector = {"type_is_simd_vector" ,       1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_matrix = {"type_is_matrix" ,            1, false,  .Expr,  .Intrinsics, false, false},

	.type_is_specialized_polymorphic_record = {"type_is_specialized_polymorphic_record" ,   1, false,  .Expr,  .Intrinsics, false, false},
	.type_is_unspecialized_polymorphic_record = {"type_is_unspecialized_polymorphic_record" , 1, false,  .Expr,  .Intrinsics, false, false},

	.type_has_nil = {"type_has_nil" ,              1, false,  .Expr,  .Intrinsics, false, false},
	._type_simple_boolean_end = {"" , 0, false,  .Stmt,  .Intrinsics, false, false},

	.type_has_field = {"type_has_field" ,            2, false,  .Expr,  .Intrinsics, false, false},
	.type_field_type = {"type_field_type" ,           2, false,  .Expr,  .Intrinsics, false, false},

	.type_is_specialization_of = {"type_is_specialization_of" , 2, false,  .Expr,  .Intrinsics, false, false},

	.type_is_variant_of = {"type_is_variant_of" , 2, false,  .Expr,  .Intrinsics, false, false},

	.type_struct_field_count = {"type_struct_field_count" ,   1, false,  .Expr,  .Intrinsics, false, false},

	.type_proc_parameter_count = {"type_proc_parameter_count" , 1, false,  .Expr,  .Intrinsics, false, false},
	.type_proc_return_count = {"type_proc_return_count" ,    1, false,  .Expr,  .Intrinsics, false, false},

	.type_proc_parameter_type = {"type_proc_parameter_type" ,  2, false,  .Expr,  .Intrinsics, false, false},
	.type_proc_return_type = {"type_proc_return_type" ,     2, false,  .Expr,  .Intrinsics, false, false},

	.type_polymorphic_record_parameter_count = {"type_polymorphic_record_parameter_count" , 1, false,  .Expr,  .Intrinsics, false, false},
	.type_polymorphic_record_parameter_value = {"type_polymorphic_record_parameter_value" , 2, false,  .Expr,  .Intrinsics, false, false},

	.type_is_subtype_of = {"type_is_subtype_of" , 2, false,  .Expr,  .Intrinsics, false, false},

	.type_field_index_of = {"type_field_index_of" , 2, false,  .Expr,  .Intrinsics, false, false},

	.type_equal_proc = {"type_equal_proc" ,    1, false,  .Expr,  .Intrinsics, false, false},
	.type_hasher_proc = {"type_hasher_proc" ,   1, false,  .Expr,  .Intrinsics, false, false},
	.type_map_info = {"type_map_info" ,      1, false,  .Expr,  .Intrinsics, false, false},
	.type_map_cell_info = {"type_map_cell_info" , 1, false,  .Expr,  .Intrinsics, false, false},


	._type_end = {"" , 0, false,  .Stmt,  .Intrinsics, false, false},

	.__entry_point = {"__entry_point" , 0, false,  .Stmt,  .Intrinsics, false, false},

	.objc_send = {"objc_send" ,   3, true,   .Expr,  .Intrinsics, false, true},

	.objc_find_selector = {"objc_find_selector" ,     1, false,  .Expr,  .Intrinsics, false, false},
	.objc_find_class = {"objc_find_class" ,        1, false,  .Expr,  .Intrinsics, false, false},
	.objc_register_selector = {"objc_register_selector" , 1, false,  .Expr,  .Intrinsics, false, true},
	.objc_register_class = {"objc_register_class" ,    1, false,  .Expr,  .Intrinsics, false, true},

	.constant_utf16_cstring = {"constant_utf16_cstring" , 1, false,  .Expr,  .Intrinsics, false, false},

	.wasm_memory_grow = {"wasm_memory_grow" , 2, false,  .Expr,  .Intrinsics, false, false},
	.wasm_memory_size = {"wasm_memory_size" , 1, false,  .Expr,  .Intrinsics, false, false},
	.wasm_memory_atomic_wait32 = {"wasm_memory_atomic_wait32" , 3, false,  .Expr,  .Intrinsics, false, false},
	.wasm_memory_atomic_notify32 = {"wasm_memory_atomic_notify32" , 2, false,  .Expr,  .Intrinsics, false, false},

	.valgrind_client_request = {"valgrind_client_request" , 7, false,  .Expr,  .Intrinsics, false, false},
}