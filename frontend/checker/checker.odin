package frontend_checker



builtin_pkg: ^Ast_Package
intrinsics_pkg: ^Ast_Package
config_pkg: ^Ast_Package

// CheckerInfo API
type_and_value_of_expr :: proc(expr: ^Node) -> Type_And_Value {
    unimplemented()
}

type_of_expr :: proc(expr: ^Node) -> ^Type {
    unimplemented()
}

implicit_entity_of_node :: proc(clause: ^Node) -> ^Entity {
    unimplemented()
}

decl_info_of_ident :: proc(ident: ^Node) -> ^Decl_Info {
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
entity_of_node :: proc(expr: ^Node) -> ^Entity {
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


add_entity_use :: proc(c: ^Checker_Context, identifier: ^Node, entity: ^Entity) {
    unimplemented()
}

add_implicit_entity :: proc(c: ^Checker_Context, node: ^Node, e: ^Entity) {
   unimplemented()
}

add_entity_and_decl_info :: proc(c: ^Checker_Context, ident: ^Node, e: ^Entity, d: ^Decl_Info, is_exported := true) {
   unimplemented()
}

add_type_info_type :: proc(c: ^Checker_Context, t: ^Type) {
   unimplemented()
}

check_add_import_decl :: proc(c: ^Checker_Context, decl: ^Node) {
    unimplemented()
}

check_add_foreign_import_decl :: proc(c: ^Checker_Context, decl: ^Node) {
    unimplemented()
}

check_entity_decl :: proc(c: ^Checker_Context, e: ^Entity, d: ^Decl_Info, named_type: ^Type) {
    unimplemented()   
}

check_const_decl :: proc(c: ^Checker_Context, e: ^Entity, type_expr: ^Node, init_expr: ^Node, named_type: ^Type) {
    unimplemented()
}

check_type_decl :: proc(c: ^Checker_Context, e: ^Entity, type_expr: ^Node, def: ^Type) {
    unimplemented()
}

check_collect_entities :: proc(c: ^Checker_Context, nodes: []^Node) {
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

