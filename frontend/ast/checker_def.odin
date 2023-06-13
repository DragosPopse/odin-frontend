package frontend_ast

// Used by frontend/checker. Defined here to avoid cyclic dependencies

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