package frontend

import "core:container/queue"
import "core:sync"

Addressing_Mode :: enum {
	Invalid   = 0,        // invalid addressing mode
	NoValue   = 1,        // no value (void in C)
	Value     = 2,        // computed value (rvalue)
	Context   = 3,        // context value
	Variable  = 4,        // addressable variable (lvalue)
	Constant  = 5,        // constant
	Type      = 6,        // type
	Builtin   = 7,        // built-in procedure
	Proc_Group = 8,        // procedure group (overloaded procedure)
	MapIndex  = 9,        // map index expression -
	                      //         lhs: acts like a Variable
	                      //         rhs: acts like OptionalOk
	Optional_Ok    = 10,   // rhs: acts like a value with an optional boolean part (for existence check)
	Optional_Ok_Ptr = 11,   // rhs: same as OptionalOk but the value is a pointer
	Soa_Variable   = 12,   // Struct-Of-Arrays indexed variable
	Swizzle_Value    = 13, // Swizzle indexed value
	Swizzle_Variable = 14, // Swizzle indexed variable
}

Type_And_Value :: struct {
	type: ^Type,
	mode: Addressing_Mode,
	is_lhs: bool, // debug info
	value: Exact_Value,
}

Parse_File_Error :: enum {
	None,

	Wrong_Extension,
	Invalid_File,
	Empty_File,
	Permission,
	Not_Found,
	Invalid_Token,
	General_Error,
	File_Too_Large,
	Directory_Already_Exists,
}

Comment_Group :: struct {
	list: []Token,
}

Package_Kind :: enum {
	Normal,
	Runtime,
	Init,
}

Imported_File :: struct {
	pkg: ^Ast_Package,
	fi: File_Info,
	pos: Token_Pos,
	index: int,
}

Ast_File_Flag :: enum {
	Is_Private_Package,
	Is_Private_File,
	Is_Test,
	Is_Lazy,
}

Ast_File_Flags :: bit_set[Ast_File_Flag]

Ast_Delay_Queue_Kind :: enum {
	Import,
	Expr,
}

Ast_File :: struct {
	id: int,
	flags: Ast_File_Flags,
	pkg: ^Ast_Package,
	scope: ^Scope,
	pkg_decl: ^Ast,
	fullpath: string,
	filename: string,
	directory: string,

	tokenizer: Tokenizer,
	tokens: [dynamic]Token,
	curr_token_index: int,
	prev_token_index: int,
	curr_token: Token,
	prev_token: Token, // previous non-comment
	package_token: Token,
	package_name: string,

	// >= 0: In Expression
	// <  0: In Control Clause
	// Note: Used to prevent type literals in control clauses
	expr_level: int,
	allow_newline: bool, // Only valid for expr_level == 0
	allow_range: bool, // Ranges are onoly allowed in certain cases
	allow_in_expr: bool, // In expression are only allowed in certain cases
	in_foreign_block: bool,
	allow_type: bool,

	total_file_decl_count: int,
	delayed_decl_count: int, // Note(Dragos): These 2 might not be needed

	// Note(Dragos): Maybe this needs to be a dynamic array aswell
	decls: []^Ast, // Learn(Dragos): I believe Ast is the equivalent of Stmt in core:odin
	imports: [dynamic]^Ast, // Note(Dragos): Maybe these can be made easier to work with using the core:odin approach
	directive_count: int,

	curr_proc: ^Ast,
	error_count: int,
	last_error: Parse_File_Error,
	time_to_tokenize: f64, // seconds
	time_to_parse: f64, // seconds
	
	lead_comment: ^Comment_Group, // Comment (block) before the decl
	line_commend: ^Comment_Group, // Comment after the semicolon
	docs: ^Comment_Group, // Current docs
	comments: [dynamic]^Comment_Group,

	delayed_decls_queues: [Ast_Delay_Queue_Kind][dynamic]^Ast,

	fix_count: int,
	fix_prev_pos: Token_Pos,
}

PARSER_MAX_FIX_COUNT :: 6

Ast_Foreign_File_Kind :: enum {
	Invalid,
	Source,
}

Ast_Foreign_File :: struct {
	kind: Ast_Foreign_File_Kind,
	source: string,
}

Ast_Package_Exported_Entity :: struct {
	identifier: ^Ast,
	entity: ^Entity,
}

Ast_Package :: struct {
	kind: Package_Kind,
	id: int,
	name: string,
	fullpath: string,
	files: [dynamic]^Ast_File,
	foreign_files: [dynamic]Ast_Foreign_File,
	is_single_file: bool,
	order: int,

	exported_entity_queue: queue.Queue(Ast_Package_Exported_Entity),

	scope: ^Scope,
	decl_info: ^Decl_Info,
	is_extra: bool,
}

Parse_File_Error_Node :: struct {
	next, prev: ^Parse_File_Error_Node,
	err: Parse_File_Error,
}

String_Set :: map[string]bool

Parser :: struct {
	init_fullpath: string,

	imported_files: String_Set, // fullpath
	imported_files_mutex: sync.Mutex, // We'll multithread later maybe

	packages: [dynamic]^Ast_Package,
	packages_mutex: sync.Mutex,

	file_to_process_count: int,
	total_token_count: int,
	total_line_count: int,

	file_decl_mutex: sync.Mutex,
	file_error_mutex: sync.Mutex,

	file_error_head: ^Parse_File_Error_Node,
	file_error_tail: ^Parse_File_Error_Node,
}

Parser_Worker_Data :: struct {
	parser: ^Parser,
	imported_file: Imported_File,
}

Foreign_File_Worker_Data :: struct {
	parser: ^Parser,
	imported_file: Imported_File,
	foreign_kind: Ast_Foreign_File_Kind,
}

Proc_Inlining :: enum {
	None,
	Inline,
	No_Inline,
}

Proc_Tag :: enum {
	Bounds_Check, 
	No_Bounds_Check, // Note(Dragos): Should these be merged into 1 tag?
	Type_Assert,
	No_Type_Assert,
	Require_Results,
	Optional_Ok,
	Optional_Allocator_Error,
}

Proc_Tags :: bit_set[Proc_Tag]

Calling_Convention :: enum {
	Invalid     = 0,
	Odin        = 1,
	Contextless = 2,
	CDecl       = 3,
	StdCall     = 4,
	FastCall    = 5,

	None        = 6,
	Naked       = 7,

	InlineAsm   = 8,

	Win64       = 9,
	SysV        = 10,



	//ForeignBlockDefault = -1,
};

calling_convention_strings := [Calling_Convention]string{
	.Invalid 	= "",
	.Odin 		= "odin",
	.Contextless= "contextless",
	.CDecl      = "cdecl",
	.StdCall    = "stdcall",
	.FastCall   = "fastcall",
	.None       = "none",
	.Naked      = "naked",
	.InlineAsm  = "inlineasm",
	.Win64      = "win64",
	.SysV       = "sysv",
}

default_calling_convention :: proc() -> Calling_Convention {
	return .Odin,
}

State_Flag :: enum {
	Bounds_Check,    
	No_Bounds_Check, 
	Type_Assert,     
	No_Type_Assert, 
	Selector_Call_Expr, 
	Directive_Was_False,
	Been_Handled,
}

State_Flags :: bit_set[State_Flag]

Viral_State_Flag :: enum {
	Contains_Deferred_Procedure,
}

Viral_State_Flags :: bit_set[Viral_State_Flag]

Field_Flag :: enum {
	Ellipsis,
	Using,
	No_Alias,
	C_Vararg,

	Const,
	Any_Int,
	Subtype,
	By_Ptr,

	// Internal use by the parser
	Tags,
	Results,

	Unknown,
	Invalid,
}

Field_Flags :: bit_set[Field_Flag]

// Parameter list restrictions
Field_Flags_Allowed_Signature :: Field_Flags{.Ellipsis, .Using, .No_Alias, .C_Vararg, .Const, .Any_Int, .By_Ptr}
Field_Flags_Allowed_Struct :: Field_Flags{.Using, .Subtype, .Tags}

Stmt_Allow_Flag :: enum {
	In,
	Label,
}

Stmt_Allow_Flags :: bit_set[Stmt_Allow_Flag]

Inline_Asm_Dialect_Kind :: enum {
	Default, // ATT is default
	ATT,
	Intel,
}

inline_asm_dialect_strings := [Inline_Asm_Dialect_Kind]string{
	.Default = "",
	.ATT = "att",
	.Intel = "intel",
}

union_type_kind_strings := [Union_Type_Kind]string {
	.Normal = "(normal)",
	// Warning(Dragos): seems like there is a #maybe in here, should investigate later
	.No_Nil = "#no_nil", 
	.Shared_Nil = "#shared_nil",
}

Ast_Ident :: struct {
	token: Token,
	entity: ^Entity,
}

Ast_Implicit :: distinct Token

Ast_Uninit :: distinct Token

Ast_Basic_Lit :: struct {
	token: Token,
}

Ast_Basic_Directive :: struct {
	token: Token,
	name: Token,
}

Ast_Ellipsis :: struct {
	token: Token,
	expr: ^Ast,
}

Ast_Proc_Group :: struct {
	token: Token,
	open: Token,
	close: Token,
	args: []^Ast,
}

Ast_Proc_Lit :: struct {
	type: ^Ast,
	body: ^Ast,
	tags: Proc_Tags,
	inlining: Proc_Inlining,
	where_token: Token,
	where_clauses: []^Ast,
	decl: ^Decl_Info,
}

Ast_Compound_Lit :: struct {
	type: ^Ast,
	elems: []^Ast,
	open, close: Token,
	max_count: int,
	tag: ^Ast,
}

// Expr Begin

Ast_Bad_Expr :: struct {
	begin, end: Token,
}

Ast_Tag_Expr :: struct {
	token, name: Token,
	expr: ^Ast,
}

Ast_Unary_Expr :: struct {
	op: Token,
	expr: ^Ast,
}

Ast_Binary_Expr :: struct {
	op: Token,
	left, right: ^Ast,
}

Ast_Paren_Expr :: struct {
	expr: ^Ast,
	open, close: Token,
}

Ast_Selector_Expr :: struct {
	token: ^Token,
	expr, selector: ^Ast,
	swizzle_count: u8, // maximum of 4 components, if set, count >= 2
	swizzle_indices: u8,  // 2 bits per component
}

Ast_Implicit_Selector_Expr :: struct {
	token: Token,
	selector: ^Ast,
}

Ast_Selector_Call_Expr :: struct {
	token: Token,
	expr, call: ^Ast,
	modified_call: bool,
}

Ast_Index_Expr :: struct {
	expr, index: ^Ast,
	open, close: Token,
}

Ast_Deref_Expr :: struct {
	expr: ^Ast,
	op: Token,
}

Ast_Slice_Expr :: struct {
	expr: ^Ast,
	open, close: Token,
	interval: Token,
	low, high: ^Ast,
}

Ast_Call_Expr :: struct {
	procedure: ^Ast,
	args: []^Ast,
	open, close: Token,
	ellipsis: Token,
	inlining: Proc_Inlining,
	optional_ok_one: bool,
	was_selector: bool,
}

Ast_Field_Value :: struct {
	eq: Token,
	field, value: ^Ast,
}

Ast_Enum_Field_Value :: struct {
	name: ^Ast,
	value: ^Ast,
	docs: ^Comment_Group,
	comment: ^Comment_Group,
}

Ast_Ternary_If_Expr :: struct {
	x, cond, y: ^Ast,
}

Ast_Ternary_When_Expr :: struct {
	x, cond, y: ^Ast,
}

Ast_Or_Else_Expr :: struct {
	x: ^Ast,
	token: Token,
	y: ^Ast,
}

Ast_Or_Return_Expr :: struct {
	expr: ^Ast,
	token: ^Token,
}

Ast_Type_Assertion :: struct {
	expr: ^Ast,
	dot: Token,
	type: ^Ast,
	type_hint: ^Type,
	ignores: [2]bool,
}

Ast_Type_Cast :: struct {
	token: Token,
	type: ^Ast,
	expr: ^Ast,
}

Ast_Auto_Cast :: struct {
	token: Token,
	expr: ^Ast,
}

Ast_Inline_Asm_Expr :: struct {
	token: Token,
	open, close: Token,
	param_types: []^Ast,
	return_type: ^Ast,
	asm_string: ^Ast,
	constraints_string: ^Ast,
	has_side_effects: bool,
	is_align_stack: bool,
	dialect: Inline_Asm_Dialect_Kind,
}

Ast_Matrix_Index_Expr :: struct {
	expr, row_index, column_index: ^Ast,
	open, close: Token,
}

// Expr End

// Stmt Begin

Ast_Bad_Stmt :: struct {
	begin, end: Token,
}

Ast_Empty_Stmt :: struct {
	begin, end: Token,
}

Ast_Expr_Stmt :: struct {
	expr: ^Ast,
}

Ast_Assign_Stmt :: struct {
	op: Token,
	lhs, rhs: []^Ast,
}

// Complex Stmt Begin

Ast_Block_Stmt :: struct {
	scope: ^Scope,
	stmts: []^Ast,
	label: ^Ast,
	open, close: Token,
}

Ast_If_Stmt :: struct {
	scope: ^Scope,
	token: Token,
	label, init, cond, body, else_stmt: ^Ast,
}

Ast_When_Stmt :: struct {
	token: Token,
	cond: ^Ast,
	body: ^Ast,
	else_stmt: ^Ast,
	is_cond_determined, determined_cond: bool,
}

Ast_Return_Stmt :: struct {
	token: Token,
	results: []^Ast,
}

Ast_For_Stmt :: struct {
	scope: ^Scope,
	token: Token,
	label, init, cond, post, body: ^Ast,
}

Ast_Range_Stmt :: struct {
	scope: ^Scope,
	token: Token,
	label: ^Ast,
	vals: []^Ast,
	in_token: Token,
	expr, body: ^Ast,
	reverse: bool,
}

Ast_Unroll_Range_Stmt :: struct {
	scope: ^Scope,
	unroll_token: Token,
	for_token: Token,
	val0, val1: ^Ast,
	in_token: Token,
	expr, body: ^Ast,
}

Ast_Case_Clause :: struct {
	scope: ^Scope,
	token: ^Token,
	list: []^Ast,
	stmts: []^Ast,
	implicit_entity: ^Entity,
}

Ast_Switch_Stmt :: struct {
	scope: ^Scope,
	token: Token,
	label, init, tag, body: ^Ast,
	partial: bool,
}

Ast_Type_Switch_Stmt :: struct {
	scope: ^Scope,
	token: Token,
	label, tag, body: ^Ast,
	partial: bool,
}

Ast_Defer_Stmt :: struct {
	token: Token,
	stmt: ^Ast,
}

Ast_Branch_Stmt :: struct {
	token: Token,
	label: ^Ast,
}

Ast_Using_Stmt :: struct {
	token: ^Token,
	list: []^Ast,
}

// Complex Stmt End
// Stmt End

// Decl Begin

Ast_Bad_Decl :: struct {
	begin, end: Token,
}

Ast_Foreign_Block_Decl :: struct {
	token: Token,
	foreign_library: ^Ast,
	body: ^Ast,
	attributes: [dynamic]^Ast, // Learn(Dragos): Why are some things slices and some things arrays? Seems off
	docs: ^Comment_Group,
}

Ast_Label :: struct {
	token: Token,
	name: ^Ast,
}

Ast_Value_Decl :: struct {
	names: []^Ast,
	type: ^Ast,
	values: []^Ast,
	attributes: [dynamic]^Ast,
	docs, comment: ^Comment_Group,
	is_using, is_mutable: bool,
}

Ast_Package_Decl :: struct {
	token: Token,
	name: Token,
	docs, comment: ^Comment_Group,
}

Ast_Import_Decl :: struct {
	pkg: ^Ast_Package,
	token: Token,
	relpath: Token,
	fullpath: string,
	import_name: string,
	docs, comment: ^Comment_Group,
}

Ast_Foreign_Import_Decl :: struct {
	token: Token,
	filepaths: []Token,
	library_name: Token,
	collection_name: string,
	fullpaths: []string,
	attributes: [dynamic]^Ast,
	docs, comment: ^Comment_Group,
}

// Decl End

Ast_Attribute :: struct {
	token: Token,
	elems: []^Ast,
	open, close: Token,
}

Ast_Field :: struct {
	names: []^Ast,
	type: ^Ast,
	default_value: ^Ast,
	tag: Token,
	flags: Field_Flags,
	docs, comment: ^Comment_Group,
}

Ast_Field_List :: struct {
	token: Token,
	list: []^Ast,
}

// Type Begin

Ast_Typeid_Type :: struct {
	token: Token,
	specialization: ^Ast,
}

Ast_Helper_Type :: struct { // Learn(Dragos): Not sure what a helper type is
	token: Token,
	type: ^Ast,
}

Ast_Poly_Type :: struct {
	token: Token,
	type: ^Ast,
	specialization: ^Ast,
}

Ast_Proc_Type :: struct {
	scope: ^Scope,
	token: Token,
	params: ^Ast,
	results: ^Ast,
	tags: Proc_Tags,
	calling_convention: Calling_Convention,
	generic: bool,
	diverging: bool,
}

Ast_Pointer_Type :: struct {
	token: Token,
	type: ^Ast,
	tag: ^Ast,
}

Ast_Relative_Type :: struct {
	tag: ^Ast,
	type: ^Ast,
}

Ast_Multi_Pointer_Type :: struct {
	token: Token,
	type: ^Ast,
}

Ast_Array_Type :: struct {
	token: Token,
	count: ^Ast,
	elem: ^Ast,
	tag: ^Ast,
}

Ast_Dynamic_Array_Type :: struct {
	token: Token,
	elem: ^Ast,
	tag: ^Ast,
}

Ast_Struct_Type :: struct {
	scope: ^Scope,
	token: Token,
	fields: []^Ast,
	field_count: int,
	polymorphic_params: ^Ast,
	align: ^Ast,
	where_token: Token,
	where_clauses: []^Ast,
	is_packed, is_raw_union, is_no_copy: bool,
}

Ast_Union_Type :: struct {
	scope: ^Scope, 
	token: Token,
	variants: []^Ast,
	polymorphic_params: ^Ast,
	align: ^Ast,
	kind: Union_Type_Kind,
	where_token: Token,
	where_clauses: []^Ast,
}

Ast_Enum_Type :: struct {
	scope: ^Scope,
	token: Token,
	base_type: ^Ast,
	fields: []^Ast,
	is_using: bool,
}

Ast_Bit_Set_Type :: struct {
	token: Token,
	elem: ^Ast,
	underlying: ^Ast,
}

Ast_Map_Type :: struct {
	token: Token,
	count: ^Ast,
	key: ^Ast,
	value: ^Ast,
}

Ast_Matrix_Type :: struct {
	token: Token,
	row_count, column_count: ^Ast,
	elem: ^Ast,
}

// Type End

Ast :: struct {
	state_flags: State_Flags,
	viral_state_flags: Viral_State_Flags,
	file_id: int,
	tav: Type_And_Value,
	variant: union {
		Ast_Ident,
		Ast_Implicit,
		Ast_Uninit,
		Ast_Basic_Lit,
		Ast_Basic_Directive,
		Ast_Ellipsis,
		Ast_Proc_Group,
		Ast_Proc_Lit,
		Ast_Compound_Lit,

		// Expr Begin
		Ast_Bad_Expr,
		Ast_Tag_Expr,
		Ast_Unary_Expr,
		Ast_Binary_Expr,
		Ast_Paren_Expr,
		Ast_Selector_Expr,
		Ast_Implicit_Selector_Expr,
		Ast_Selector_Call_Expr,
		Ast_Index_Expr,
		Ast_Deref_Expr,
		Ast_Slice_Expr,
		Ast_Call_Expr,
		Ast_Field_Value,
		Ast_Enum_Field_Value,
		Ast_Ternary_If_Expr,
		Ast_Ternary_When_Expr,
		Ast_Or_Else_Expr,
		Ast_Or_Return_Expr,
		Ast_Type_Assertion,
		Ast_Type_Cast,
		Ast_Auto_Cast,
		Ast_Inline_Asm_Expr,
		Ast_Matrix_Index_Expr,
		// Expr End

		// Stmt Begin
		Ast_Bad_Stmt,
		Ast_Empty_Stmt,
		Ast_Expr_Stmt,
		Ast_Assign_Stmt,
		// Complex Stmt Begin
		Ast_Block_Stmt,
		Ast_If_Stmt,
		Ast_When_Stmt,
		Ast_Return_Stmt,
		Ast_For_Stmt,
		Ast_Range_Stmt,
		Ast_Unroll_Range_Stmt,
		Ast_Case_Clause,
		Ast_Switch_Stmt,
		Ast_Type_Switch_Stmt,
		Ast_Defer_Stmt,
		Ast_Branch_Stmt,
		Ast_Using_Stmt,
		// Complex Stmt End
		//Stmt End

		// Decl Begin
		Ast_Bad_Decl,
		Ast_Foreign_Block_Decl,
		Ast_Label,
		Ast_Value_Decl,
		Ast_Package_Decl,
		Ast_Import_Decl,
		Ast_Foreign_Import_Decl,
		// Decl End

		Ast_Attribute,
		Ast_Field,
		Ast_Field_List,

		// Type Begin
		Ast_Typeid_Type,
		Ast_Helper_Type,
		Ast_Poly_Type,
		Ast_Proc_Type,
		Ast_Pointer_Type,
		Ast_Relative_Type,
		Ast_Multi_Pointer_Type,
		Ast_Array_Type,
		Ast_Dynamic_Array_Type,
		Ast_Struct_Type,
		Ast_Union_Type,
		Ast_Enum_Type,
		Ast_Bit_Set_Type,
		Ast_Map_Type,
		Ast_Matrix_Type,
		// Type End
	},
}

is_ast_expr :: proc(node: ^Ast) -> bool {
	#partial switch in node.variant {
		case Ast_Bad_Expr,
		Ast_Tag_Expr,
		Ast_Unary_Expr,
		Ast_Binary_Expr,
		Ast_Paren_Expr,
		Ast_Selector_Expr,
		Ast_Implicit_Selector_Expr,
		Ast_Selector_Call_Expr,
		Ast_Index_Expr,
		Ast_Deref_Expr,
		Ast_Slice_Expr,
		Ast_Call_Expr,
		Ast_Field_Value,
		Ast_Enum_Field_Value,
		Ast_Ternary_If_Expr,
		Ast_Ternary_When_Expr,
		Ast_Or_Else_Expr,
		Ast_Or_Return_Expr,
		Ast_Type_Assertion,
		Ast_Type_Cast,
		Ast_Auto_Cast,
		Ast_Inline_Asm_Expr,
		Ast_Matrix_Index_Expr: return true
	}
	return false
}

// Question(Dragos): Would this be way slower than a in_between comparison on an enum or reflection?
is_ast_stmt :: proc(node: ^Ast) -> bool {
	#partial switch in node.variant {
		case Ast_Bad_Stmt,
		Ast_Empty_Stmt,
		Ast_Expr_Stmt,
		Ast_Assign_Stmt,
		Ast_Block_Stmt,
		Ast_If_Stmt,
		Ast_When_Stmt,
		Ast_Return_Stmt,
		Ast_For_Stmt,
		Ast_Range_Stmt,
		Ast_Unroll_Range_Stmt,
		Ast_Case_Clause,
		Ast_Switch_Stmt,
		Ast_Type_Switch_Stmt,
		Ast_Defer_Stmt,
		Ast_Branch_Stmt,
		Ast_Using_Stmt: return true
	}

	return false
}

is_ast_complex_stmt :: proc(node: ^Ast) -> bool {
	#partial switch in node.variant {
		case Ast_Block_Stmt,
		Ast_If_Stmt,
		Ast_When_Stmt,
		Ast_Return_Stmt,
		Ast_For_Stmt,
		Ast_Range_Stmt,
		Ast_Unroll_Range_Stmt,
		Ast_Case_Clause,
		Ast_Switch_Stmt,
		Ast_Type_Switch_Stmt,
		Ast_Defer_Stmt,
		Ast_Branch_Stmt,
		Ast_Using_Stmt: return true
	}

	return false
}

is_ast_decl :: proc(node: ^Ast) -> bool {
	#partial switch in node.variant {
		case Ast_Bad_Decl,
		Ast_Foreign_Block_Decl,
		Ast_Label,
		Ast_Value_Decl,
		Ast_Package_Decl,
		Ast_Import_Decl,
		Ast_Foreign_Import_Decl: return true
	}

	return false
}

is_ast_type :: proc(node: ^Ast) -> bool {
	#partial switch in node.variant {
		case Ast_Typeid_Type,
		Ast_Helper_Type,
		Ast_Poly_Type,
		Ast_Proc_Type,
		Ast_Pointer_Type,
		Ast_Relative_Type,
		Ast_Multi_Pointer_Type,
		Ast_Array_Type,
		Ast_Dynamic_Array_Type,
		Ast_Struct_Type,
		Ast_Union_Type,
		Ast_Enum_Type,
		Ast_Bit_Set_Type,
		Ast_Map_Type,
		Ast_Matrix_Type: return true
	}

	return false
}

is_ast_when_stmt :: proc(node: ^Ast) -> bool {
	_, ok := &node.variant.(Ast_When_Stmt)
	return ok
}

// Learn(Dragos): Ast nodes are allocated by an arena. We can put the allocator in the parser
alloc_ast_node :: proc(f: ^Ast_File, $Variant: typeid) -> ^Ast {
	unimplemented()
}

expr_to_string :: proc(expr: ^Ast) -> string {
	unimplemented()
}

allow_field_separator :: proc(f: ^Ast_File) -> bool {
	unimplemented()
}
