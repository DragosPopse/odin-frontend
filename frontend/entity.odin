package frontend
import "core:sync"

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
    init_expr: ^Ast, // only used for some variables within procedure bodies
    field_index: int,
    field_group_index: int,

    param_value: Parameter_Value,

    thread_local_model: string,
    foreign_library: ^Entity,
    foreign_library_ident: ^Ast,
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
    foreign_library_ident: ^Ast,
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
    node: ^Ast,
    parent: ^Ast,
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
    original_ast_expr: ^Ast,
    using _: struct #raw_union {
        value: Exact_Value,
        ast_value: ^Ast,
    },
}

has_parameter_value :: proc(param_value: Parameter_Value) -> bool {
    unimplemented()
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

create_type_name_obj_c_metadata :: proc() -> Type_Name_ObjC_Metadata {
    unimplemented()
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
    identifier: ^Ast, // can be nil
    decl_info: ^Decl_Info,
    parent_proc_decl: ^Decl_Info, // nil if in file/global scope
    file: ^Ast_File,
    pkg: ^Ast_Package,

    using_parent: ^Entity,
    using_expr: ^Ast,

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

is_entity_exported :: proc(e: ^Entity, allow_builtin := false) -> bool {
    unimplemented()
}

entity_has_deferred_procedure :: proc(e: ^Entity) -> bool {
    unimplemented()
}

global_entity_id: int // atomic

// Note(Dragos): 
alloc_entity :: proc(scope: ^Scope, token: Token, type: ^Type) -> ^Entity {
    unimplemented()
}

alloc_entity_variable :: proc(scope: ^Scope, token: Token, type: ^Type, state: Entity_State = .Unresolved) -> ^Entity {
    unimplemented()
}

alloc_entity_using_variable :: proc(parent: ^Entity, token: Token, type: ^Type, using_expr: ^Ast) -> ^Entity {
    unimplemented()
}

alloc_entity_constant :: proc(scope: ^Scope, token: Token, type: ^Type, value: Exact_Value) -> ^Entity {
    unimplemented()
}

alloc_entity_type_name :: proc(scope: ^Scope, token: Token, type: ^Type, state: Entity_State = .Unresolved) -> ^Entity {
    unimplemented()
}

alloc_entity_param :: proc(scope: ^Scope, token: Token, type: ^Type, is_using, is_value: bool) -> ^Entity {
    unimplemented()
}

alloc_entity_const_param :: proc(scope: ^Scope, token: Token, type: ^Type, value: Exact_Value, poly_const: bool) -> ^Entity {
    unimplemented()
}

alloc_entity_field :: proc(scope: ^Scope, token: Token, type: ^Type, is_using: bool, field_index: int, state: Entity_State = .Unresolved) -> ^Entity {
    unimplemented()
}

alloc_entity_array_elem :: proc(scope: ^Scope, token: Token, type: ^Type, field_index: int) -> ^Entity {
    unimplemented()
}

alloc_entity_procedure :: proc(scope: ^Scope, token: Token, signature_type: ^Type, tags: Proc_Tags) -> ^Entity {
    unimplemented()
}

alloc_entity_proc_group :: proc(scope: ^Scope, token: Token, type: ^Type) -> ^Entity {
    unimplemented()
}

alloc_entity_import_name :: proc(scope: ^Scope, token: Token, type: ^Type, path: string, name: string, import_scope: ^Scope) -> ^Entity {
    unimplemented()
}

alloc_entity_library_name :: proc(scope: ^Scope, token: Token, type: ^Type, paths: []string, name: string) -> ^Entity {
    unimplemented()
}

alloc_entity_nil :: proc(name: string, type: ^Type) -> ^Entity {
    unimplemented()
}

alloc_entity_label :: proc(scope: ^Scope, token: Token, type: ^Type, node: ^Ast, parent: ^Ast) -> ^Entity {
    unimplemented()
}

// Learn(Dragos): so a dummy entity is the _ ident?
alloc_entity_dummy_variable :: proc(scope: ^Scope, token: Token) -> ^Entity {
    unimplemented()
}

strip_entity_wrapping :: proc(e: ^Entity) -> ^Entity {
    unimplemented()
}