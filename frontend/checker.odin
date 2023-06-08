package frontend

import "core:container/queue"
import "core:sync"

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

Builtin_Proc :: struct {
    name: string,
    arg_count: int,
    variadic: bool,
    kind: Expr_Kind,
    pkg: Builtin_Proc_Pkg,
    diverging: bool,
    ignore_results: bool, // ignores require results handling
}

// #include "checker_builtin_procs.hpp" // do this

Operand :: struct {
    mode: Addressing_Mode,
    type: ^Type,
    value: Exact_Value,
    expr: ^Ast, // So this can be an ast.Any_Expr
    builtin_id: Builtin_Proc_Id,
    proc_group: ^Entity,
}

Block_Label :: struct  {
    name: string,
    label: ^Ast,
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

make_attribute_context :: proc(link_prefix: string) -> Attribute_Context {
    ac: Attribute_Context
    ac.link_prefix = link_prefix
    return ac
}

check_decl_attributes :: proc(c: ^Checker_Context, attributes: [dynamic]^Ast, procedure: Decl_Attribute_Proc, ac: ^Attribute_Context) {
    unimplemented()
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

    decl_node: ^Ast,
    type_expr: ^Ast,
    init_expr: ^Ast,
    attributes: [dynamic]^Ast,
    proc_lit: ^Ast,
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
    body: ^Ast,
    tags: Proc_Tags,
    generated_from_polymorphic: bool,
    poly_def_node: ^Ast,
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
    node: ^Ast,
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
    curr_library: ^Ast,
    default_cc: Calling_Convention,
    link_prefix: string,
    visibility_kind: Entity_Visiblity_Kind,
}

Checker_Type_Path :: [dynamic]^Entity
Checker_Poly_Path :: [dynamic]^Type

Atom_Op_Map_Entry :: struct {
    kind: u32, // Warning(Dragos): what is this?
    node: ^Ast,
}

Untyped_Expr_Info :: struct {
    expr: ^Ast,
    info: ^Expr_Info,
}

Untyped_Expr_Info_Map :: map[^Ast]^Expr_Info

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

    intrinsics_entry_point_usage: queue.Queue(^Ast), // MPSC

    objc_types_mutex: sync.Mutex,
    objc_msg_send_types: map[^Ast]ObjC_Msg_Data,

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
    curr_proc_calling_conv: Calling_Convention,
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

    assignment_lhs_hint: ^Ast,
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

builtin_pkg: ^Ast_Package
intrinsics_pkg: ^Ast_Package
config_pkg: ^Ast_Package

// CheckerInfo API
type_and_value_of_expr :: proc(expr: ^Ast) -> Type_And_Value {
    unimplemented()
}

type_of_expr :: proc(expr: ^Ast) -> ^Type {
    unimplemented()
}

implicit_entity_of_node :: proc(clause: ^Ast) -> ^Entity {
    unimplemented()
}

decl_info_of_ident :: proc(ident: ^Ast) -> ^Decl_Info {
    unimplemented()
}

decl_info_of_entity :: proc(e: ^Entity) -> ^Decl_Info {
    unimplemented()
}

ast_file_of_filename :: proc(i: ^Checker_Info, filename: string) -> ^Ast_File {
    unimplemented()
}


// IMPORTANT: Only to use once checking is done
type_info_index :: proc(i: ^Checker_Info, type: ^Type, error_on_failure: bool) -> int {
    unimplemented()
}

// Will return nullptr if not found
entity_of_node :: proc(expr: ^Ast) -> ^Entity {
    unimplemented()
}

scope_lookup_current :: proc(s: ^Scope, name: string) -> ^Entity {
    unimplemented()
}

scope_lookup :: proc(s: ^Scope, name: string) -> ^Entity {
    unimplemented()
}

// Note(Dragos): Can this have multiple return values instead of scope_ entity_
scope_lookup_parent :: proc(s: ^Scope, name: string, scope_: ^^Scope, entity_: ^^Entity) {
    unimplemented()
}

scope_insert :: proc(s: ^Scope, entity: ^Entity) -> ^Entity {
    unimplemented()
}

add_type_and_value :: proc(c: ^Checker_Context, expression: ^Ast, mode: Addressing_Mode, type: ^Type, value: Exact_Value) {
    unimplemented()
}

check_get_expr_info :: proc(c: ^Checker_Context, expr: ^Ast) -> ^Expr_Info {
    unimplemented()
}

add_untyped :: proc(c: ^Checker_Context, expression: ^Ast, mode: Addressing_Mode, basic_type: ^Type, value: Exact_Value) {
    unimplemented()
}

add_entity_use :: proc(c: ^Checker_Context, identifier: ^Ast, entity: ^Entity) {
    unimplemented()
}

add_implicit_entity :: proc(c: ^Checker_Context, node: ^Ast, e: ^Entity) {
   unimplemented()
}

add_entity_and_decl_info :: proc(c: ^Checker_Context, ident: ^Ast, e: ^Entity, d: ^Decl_Info, is_exported := true) {
   unimplemented()
}

add_type_info_type :: proc(c: ^Checker_Context, t: ^Type) {
   unimplemented()
}

check_add_import_decl :: proc(c: ^Checker_Context, decl: ^Ast) {
    unimplemented()
}

check_add_foreign_import_decl :: proc(c: ^Checker_Context, decl: ^Ast) {
    unimplemented()
}

check_entity_decl :: proc(c: ^Checker_Context, e: ^Entity, d: ^Decl_Info, named_type: ^Type) {
    unimplemented()   
}

check_const_decl :: proc(c: ^Checker_Context, e: ^Entity, type_expr: ^Ast, init_expr: ^Ast, named_type: ^Type) {
    unimplemented()
}

check_type_decl :: proc(c: ^Checker_Context, e: ^Entity, type_expr: ^Ast, def: ^Type) {
    unimplemented()
}

// Arity is the number of args taken by a function. ???!?!?!?!
check_arity_match :: proc(c: ^Checker_Context, vd: ^Ast_Value_Decl, is_global := false) {
    unimplemented()
}

check_collect_entities :: proc(c: ^Checker_Context, nodes: []^Ast) {
    unimplemented()
}

check_collect_entities_from_when_stmt :: proc(c: ^Checker_Context, ws: ^Ast_When_Stmt) {
    unimplemented()
}

new_checker_type_path :: proc() -> ^Checker_Type_Path {
    unimplemented()
}

destroy_checker_type_path :: proc(tp: ^Checker_Type_Path) {
    unimplemented()
}

check_type_path_push :: proc(c: ^Checker_Context, e: ^Entity) {
    unimplemented()
}

check_type_path_pop :: proc(c: ^Checker_Context) -> ^Entity {
    unimplemented()
}

init_core_context :: proc(c: ^Checker) {
    unimplemented()
}

init_mem_allocator :: proc(c: ^Checker) {
    unimplemented()
}

add_untyped_expressions :: proc(cinfo: ^Checker_Info, untyped: ^Untyped_Expr_Info_Map) {
    unimplemented()
}