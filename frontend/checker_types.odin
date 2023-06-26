package frontend

import "core:sync"
import "core:container/queue"

Exact_Value :: struct {
    
}

Builtin_Proc :: struct {
    name: string,
    arg_count: int,
    variadic: bool,
    kind: Expr_Kind,
    pkg: Builtin_Proc_Pkg,
    diverging: bool,
    ignore_results: bool, // ignores require results handling
}

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

// stores information used for "untyped" expressions
Expr_Info :: struct {
    mode: Addressing_Mode,
    is_lhs: bool, // Debug info
    type: ^Type,
    value: Exact_Value,
}

make_expr_info :: proc(mode: Addressing_Mode, type: ^Type, value: Exact_Value, is_lhs: bool) -> ^Expr_Info {
    unimplemented()
}

Expr_Kind :: enum {
    Expr,
    Stmt,
}

Stmt_Flag :: enum {
    Break_Allowed,
    Continue_Allowed,
    Fallthrough_Allowed,
    Type_Switch,
    Check_Scope_Decls,
}; Stmt_Flags :: bit_set[Stmt_Flag]

Builtin_Proc_Pkg :: enum {
    Builtin,
    Intrinsics,
}

// #include "checker_builtin_procs.hpp" // do this

Operand :: struct {
    mode: Addressing_Mode,
    type: ^Type,
    value: Exact_Value,
    expr: ^Node, // So this can be an ast.Any_Expr
    builtin_id: Builtin_Proc_Id,
    proc_group: ^Entity,
}

Block_Label :: struct  {
    name: string,
    label: ^Node,
}

Deferred_Procedure_Kind :: enum {
    None,
    In,
    Out,
    In_Out,
    In_By_Ptr,
    Out_By_Ptr,
    In_Out_By_Ptr,
}

Deferred_Procedure :: struct {
    kind: Deferred_Procedure_Kind,
    entity: ^Entity,
}

Attribute_Context :: struct {
    link_name: string,
    link_prefix: string,
    link_section: string,
    linkage: string,
    init_expr_list_count: int,
    thread_local_model: string,
    deprecated_message: string,
    warning_message: string,
    deferred_procedure: Deferred_Procedure,
    // Todo(Dragos): Make this a flag thing
    is_export: bool,
    is_static: bool,
    require_results: bool,
    require_declaration: bool,
    has_disabled_proc: bool,
    disabled_proc: bool,
    test: bool,
    init: bool,
    fini: bool,
    set_cold: bool,
    optimization_mode: Procedure_Optimization_Mode,
    foreign_import_priority_index: int,
    extra_linker_flags: string,
    
    objc_class: string,
    objc_name: string,
    objc_is_class_method: bool,
    objc_type: ^Type,

    require_target_feature: string,
    enable_target_feature: string,
}

Proc_Checked_State :: enum {
    Unchecked,
    In_Progress,
    Checked,
}

Proc_Checked_State_strings := [Proc_Checked_State]string {
    .Unchecked = "Unchecked",
    .In_Progress = "In Progress",
    .Checked = "Checked",
}

Decl_Info :: struct {
	parent: ^Decl_Info, // Note(): only used for procedure literals at the moment

    next_mutex: sync.Mutex,
    next_child: ^Decl_Info,
    next_sibling: ^Decl_Info,

    scope: ^Scope,
    
    entity: ^Entity,

    decl_node: ^Node,
    type_expr: ^Node,
    init_expr: ^Node,
    attributes: [dynamic]^Node,
    proc_lit: ^Node,
    gen_proc_type: ^Type,
    is_using: bool,
    where_clauses_evaluated: bool,
    proc_checked_state: Proc_Checked_State, // atomic // Note(Dragos): name atomic vars with atomic_
    proc_checked_mutex: sync.Mutex,
    defer_used: int, // Note(Dragos): can this be a bool?
    defer_use_checked: bool,

    comment, docs: ^Comment_Group,

    deps_mutex: sync.Mutex, // RwMutex?
    deps: map[^Entity]bool, // PtrSet

    type_info_deps_mutex: sync.Mutex, // RwMutex
    type_info_deps: map[^Type]bool, // PtrSet

    type_and_value_mutex: sync.Mutex,

    labels: [dynamic]Block_Label,
}

// Stores information needed for checking a procedure
Proc_Info :: struct {
    file: ^Ast_File,
    token: Token,
    decl: ^Decl_Info,
    type: ^Type,
    body: ^Node,
    tags: Proc_Tags,
    generated_from_polymorphic: bool,
    poly_def_node: ^Node,
}

Scope_Flag :: enum {
    Pkg,
    Builtin,
    Global,
    File,
    Init,
    Proc,
    Type,
    Has_Been_Imported, 
    Context_Defined,
}; Scope_Flags :: bit_set[Scope_Flag]

DEFAULT_SCOPE_CAPACITY :: 32

Scope :: struct {
    node: ^Node,
    parent: ^Scope,
    next: ^Scope, // atomic
    head_child: ^Scope,

    mutex: sync.Mutex, // RwMutex
    elements: map[string]^Entity,
    imported: map[^Scope]bool,

    flags: Scope_Flags,

    using _: struct #raw_union { 
        pkg: ^Ast_Package,
        file: ^Ast_File,
        procedure_entity: ^Entity,
    },
}

Entity_Graph_Node_Set :: map[^Entity_Graph_Node]bool

Entity_Graph_Node :: struct {
    entity: ^Entity, // proc, var, const
    pred: Entity_Graph_Node_Set,
    succ: Entity_Graph_Node_Set,
    index: int, // index in array/queue
    dep_count: int,
}

Import_Graph_Node_Set :: map[^Import_Graph_Node]bool

Import_Graph_Node :: struct {
    pkg: ^Ast_Package,
    scope: ^Scope,
    pred: Import_Graph_Node_Set,
    succ: Import_Graph_Node_Set,
    index: int, // index in array/queue
    dep_count: int,
}

Entity_Visiblity_Kind :: enum {
    Public,
    Private_To_Package,
    Private_To_File,
}

Foreign_Context :: struct {
    curr_library: ^Node,
    default_cc: Proc_Calling_Convention,
    link_prefix: string,
    visibility_kind: Entity_Visiblity_Kind,
}

Checker_Type_Path :: [dynamic]^Entity
Checker_Poly_Path :: [dynamic]^Type

Atom_Op_Map_Entry :: struct {
    kind: u32, // Warning(Dragos): what is this?
    node: ^Node,
}

Untyped_Expr_Info :: struct {
    expr: ^Node,
    info: ^Expr_Info,
}

Untyped_Expr_Info_Map :: map[^Node]^Expr_Info

ObjC_Msg_Kind :: enum {
    Normal,
    fpret,
    fp2ret,
    stret,
}

ObjC_Msg_Data :: struct {
    kind: ObjC_Msg_Kind,
    proc_type: ^Type,
}

Load_File_Cache :: struct {
    path: string,
    file_error: int, // Warning(Dragos): this is gbFileError
    data: string,
    hashes: map[string]u64,
}

Gen_Procs_Data :: struct {
    procs: [dynamic]^Entity,
    mutex: sync.RW_Mutex, // RwMutex
}

Gen_Types_Data :: struct {
    types: [dynamic]^Entity,
    mutex: sync.RW_Mutex,
}




// Note(Dragos): Do we need this?
Entity_Dummy :: struct {
    start: u8,
}

Entity_Invalid :: struct {
    value: Exact_Value,
    param_value: Parameter_Value,
    flags: Entity_Flags,
}

Entity_Constant :: struct {
    value: Exact_Value,
    param_value: Parameter_Value,
    flags: Entity_Flags,
    field_group_index: int,
    docs, comment: ^Comment_Group,
}

Entity_Variable :: struct {
    init_expr: ^Node, // only used for some variables within procedure bodies
    field_index: int,
    field_group_index: int,

    param_value: Parameter_Value,

    thread_local_model: string,
    foreign_library: ^Entity,
    foreign_library_ident: ^Node,
    link_name: string,
    link_prefix: string,
    link_section: string,
    docs, comment: ^Comment_Group,
    is_foreign, is_export: bool,
}

Entity_Type_Name :: struct {
    type_parameter_specialization: ^Type,
    ir_mangled_name: string,
    is_type_alias: bool,
    objc_class_name: string,
    objc_metadata: ^Type_Name_ObjC_Metadata,
}

Entity_Procedure :: struct {
    tags: Proc_Tags, // Warning(Dragos): This should be a bitset, but not sure of what yet
    foreign_library: ^Entity,
    foreign_library_ident: ^Node,
    link_name: string,
    link_prefix: string,
    deferred_procedure: Deferred_Procedure,
    
    gen_procs: ^Gen_Procs_Data,
    gen_procs_mutex: sync.Mutex,
    optimization_mode: Procedure_Optimization_Mode,
    is_foreign, is_export, generated_from_polymorphic, target_feature_disabled: bool, // Note(Dragos): flagify this
    target_feature: string,
}

Entity_Proc_Group :: struct {
    entities: [dynamic]^Entity,
}

Entity_Builtin :: struct {
    id: int,
}

Entity_Import_Name :: struct {
    path, name: string,
    scope: ^Scope,
}

Entity_Library_Name :: struct {
    paths: []string,
    name: string,
    priority_index: int,
    extra_linker_flags: string,
}

Entity_Nil :: distinct int

Entity_Label :: struct {
    name: string,
    node: ^Node,
    parent: ^Node,
}

Entity_Flag :: enum {
    Visited      ,
    Used         ,
    Using        ,
    Field        ,
    Param        ,
    Result       ,
    Array_Elem    ,
    Array_Swizzle ,
    Ellipsis     ,
    No_Alias      ,
    Type_Field    ,
    Value        ,
    Poly_Const    ,
    Not_Exported  ,
    Const_Input   ,
    Static       ,
    Implicit_Reference,
    Soa_Ptr_Field    ,
    Proc_Body_Checked ,
    C_Var_Arg       ,
    Any_Int         ,
    Disabled       ,
    Cold           ,
    Lazy           ,
    For_Value       ,
    Switch_Value    ,
    Test           ,
    Init           ,
    Subtype        ,
    Fini           ,
    Custom_Link_Name ,
    Custom_Linkage_Internal,
    Custom_Linkage_Strong  ,
    Custom_Linkage_Weak    ,
    Custom_Linkage_Link_Once,
    Require,
    By_Ptr, 
    Overridden ,
}

Entity_Flags :: bit_set[Entity_Flag]

Entity_State :: enum {
    Unresolved,
    In_Progress,
    Resolved,
}

Parameter_Value_Kind :: enum {
    Invalid,
    Constant,
    Nil,
    Location,
    Value,
}

Parameter_Value :: struct {
    kind: Parameter_Value_Kind,
    original_ast_expr: ^Node,
    using _: struct #raw_union {
        value: Exact_Value,
        ast_value: ^Node,
    },
}

Entity_Constant_Flags :: enum {
    Implicit_Enum_Value,
}

Procedure_Optimization_Mode :: enum {
    Default,
    None,
    Minimal,
    Size,
    Speed,
}

global_type_name_objc_metadata_mutex: sync.Mutex

Type_Name_ObjC_Metadata_Entry :: struct {
    name: string,
    entity: ^Entity,
}

Type_Name_ObjC_Metadata :: struct {
    mutex: ^sync.Mutex,
    type_entries: [dynamic]Type_Name_ObjC_Metadata_Entry,
    value_entries: [dynamic]Type_Name_ObjC_Metadata_Entry,
}

// Note(Dragos): Attempt the Any_Entity approach, seems more reasonable for an API
// Note(Dragos): I think it might just be better to separate things in multiple packages
Entity :: struct {
    id: int,
    flags: Entity_Flags,
    state: Entity_State,
    token: Token,
    scope: ^Scope,
    type: ^Type,
    identifier: ^Node, // can be nil
    decl_info: ^Decl_Info,
    parent_proc_decl: ^Decl_Info, // nil if in file/global scope
    file: ^Ast_File,
    pkg: ^Ast_Package,

    using_parent: ^Entity,
    using_expr: ^Node,

    aliased_of: ^Entity,

    order_in_src: int,
    deprecated_message: string,
    warning_message: string,

    variant: union {
        Entity_Dummy,
        Entity_Invalid,
        Entity_Constant,
        Entity_Variable,
        Entity_Type_Name,
        Entity_Procedure,
        Entity_Proc_Group,
        Entity_Builtin,
        Entity_Import_Name,
        Entity_Library_Name,
        Entity_Nil,
        Entity_Label,
    },
}





// stores all the symbol information for a type-checked program
Checker_Info :: struct {
    checker: ^Checker,
    mutex: sync.RW_Mutex,

    files: map[string]^Ast_File,
    pkgs: map[string]^Ast_Package,
    variable_init_order: [dynamic]^Decl_Info,

    builtin_pkg: ^Ast_Package,
    runtime_pkg: ^Ast_Package,
    init_pkg: ^Ast_Package,
    init_scope: ^Scope,
    entry_point: ^Entity,
    minimum_dependency_set: map[^Entity]bool,
    // type info index, min dep index
    minimum_dependency_type_info_set: map[int]int, // Warning(Dragos): not sure about this one

    testing_procs: [dynamic]^Entity,
    init_procs: [dynamic]^Entity,
    fini_procs: [dynamic]^Entity,

    definitions: [dynamic]^Entity,
    entities: [dynamic]^Entity,
    required_foreign_imports_through_force: [dynamic]^Entity,

    global_untyped_mutex: sync.RW_Mutex,
    global_untyped: Untyped_Expr_Info_Map,

    builtin_mutex: sync.Mutex,

    type_and_value_mutex: sync.Mutex,

    lazy_mutex: sync.Recursive_Mutex,

    gen_types_mutex: sync.RW_Mutex,
    gen_types: map[^Type]Gen_Types_Data,

    type_info_mutex: sync.Mutex,
    type_info_types: [dynamic]^Type,
    type_info_map: map[^Type]int,

    foreign_mutex: sync.Mutex,
    foreigns: map[string]^Entity,

    definition_queue: queue.Queue(^Entity), // MPSC
    entity_queue: queue.Queue(^Entity), // MPSC
    required_global_variable_queue: queue.Queue(^Entity), // MPSC
    required_foreign_imports_through_force_queue: queue.Queue(^Entity), // MPSC

    intrinsics_entry_point_usage: queue.Queue(^Node), // MPSC

    objc_types_mutex: sync.Mutex,
    objc_msg_send_types: map[^Node]ObjC_Msg_Data,

    load_file_mutex: sync.Mutex,
    load_file_cache: map[string]^Load_File_Cache,

    all_procedures_mutex: sync.Mutex,
    all_procedures: [dynamic]^Proc_Info,
}

Checker_Context :: struct {
    // Order matters here // Learn(Dragos): why?
    mutex: sync.Mutex,
    checker: ^Checker,
    info: ^Checker_Info,

    pkg: ^Ast_Package,
    file: ^Ast_File,
    scope: ^Scope,
    decl: ^Decl_Info,
    
    // Order doesn't matter after this
    state_flags: State_Flags,
    in_defer: bool,
    type_hint: ^Type,

    proc_name: string,
    curr_proc_decl: ^Decl_Info,
    curr_proc_sig: ^Type,
    curr_proc_calling_conv: Proc_Calling_Convention,
    in_proc_sig: bool,
    foreign_context: Foreign_Context,

    type_path: ^Checker_Type_Path,
    type_level: int,

    untyped: Untyped_Expr_Info_Map,
    
    inline_for_depth: int,

    in_enum_type: bool,
    collect_delayed_decls: bool,
    allow_polymorphic_types: bool,
    no_polymorphic_errors: bool,
    hide_polymorphic_errors: bool,
    in_polymorphic_specialization: bool,
    allow_arrow_right_selector_expr: bool,
    polymorphic_scope: ^Scope,

    assignment_lhs_hint: ^Node,
}

MAX_INLINE_FOR_DEPTH :: 1024

Checker :: struct {
    parser: ^Parser,
    info: Checker_Info,

    builtin_ctx: Checker_Context,

    procs_with_deferred_to_check: queue.Queue(^Entity), // MPSC
    procs_to_check: [dynamic]^Proc_Info,

    nested_proc_lits_mutex: sync.Mutex,
    nested_proc_lits: [dynamic]^Decl_Info,

    global_untyped_queue: queue.Queue(Untyped_Expr_Info), // MPSC
}