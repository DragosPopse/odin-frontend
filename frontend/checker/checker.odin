package frontend_checker

import "core:container/queue"
import "core:sync"



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