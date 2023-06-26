package frontend

import "core:container/queue"
import "core:sync"
import "core:mem"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"




Addressing_Mode :: enum u8 {
	Invalid   = 0,        // invalid addressing mode
	No_Value   = 1,        // no value (void in C)
	Value     = 2,        // computed value (rvalue)
	Context   = 3,        // context value
	Variable  = 4,        // addressable variable (lvalue)
	Constant  = 5,        // constant
	Type      = 6,        // type
	Builtin   = 7,        // built-in procedure
	Proc_Group = 8,        // procedure group (overloaded procedure)
	Map_Index  = 9,        // map index expression -
	                      //         lhs: acts like a Variable
	                      //         rhs: acts like OptionalOk
	Optional_Ok    = 10,   // rhs: acts like a value with an optional boolean part (for existence check)
	Optional_Ok_Ptr = 11,   // rhs: same as OptionalOk but the value is a pointer
	Soa_Variable   = 12,   // Struct-Of-Arrays indexed variable

	Swizzle_Value    = 13, // Swizzle indexed value
	Swizzle_Variable = 14, // Swizzle indexed variable
}

Type_And_Value :: struct  {
	type : ^Type,
	mode : Addressing_Mode,
	is_lhs : bool, // Debug info
	value : Exact_Value,
}


Parse_File_Error :: enum  {
	None,

	WrongExtension,
	InvalidFile,
	EmptyFile,
	Permission,
	NotFound,
	InvalidToken,
	GeneralError,
	FileTooLarge,
	DirectoryAlreadyExists,
}

Comment_Group :: struct  {
	list: []Token, // Token_Comment
}


Package_Kind :: enum  {
	Normal,
	Runtime,
	Init,
}

Imported_File :: struct  {
	pkg: ^Ast_Package,
	fi: File_Info,
	pos: Token_Pos, // import
	index: int,
}

Ast_File_Flag :: enum u32 {
	Is_Private_Pkg = 1<<0,
	Is_Private_File = 1<<1,

	Is_Test    = 1<<3,
	Is_Lazy    = 1<<4,
}
Ast_File_Flags :: bit_set[Ast_File_Flag]

Ast_Delay_Queue_Kind :: enum {
	Import,
	Expr,
}

Ast_File :: struct {
	id: i32,
	flags: u32,
	pkg: ^Ast_Package,
	scope: ^Scope,

	pkg_decl: ^Node,

	fullpath: string,
	filename: string,
	directory: string,

	tokenizer: Tokenizer,
	tokens: [dynamic]Token,
	curr_token_index: int,
	prev_token_index: int,
	curr_token: Token,
	prev_token: Token,
	package_token: Token,
	package_name: string,


	// >= 0: In Expression
	// <  0: In Control Clause
	// NOTE(bill): Used to prevent type literals in control clauses
	expr_level: int,
	allow_newline: bool, // Only valid for expr_level == 0
	allow_range: bool,    // NOTE(bill): Ranges are only allowed in certain cases
	allow_in_expr: bool,  // NOTE(bill): in expression are only allowed in certain cases
	in_foreign_block: bool,
	allow_type: bool,

	total_file_decl_count: int,
	delayed_decl_count: int,
	decls: []^Node,
	imports: [dynamic]^Node, // 'import'
	directive_count: int,

	curr_proc: ^Node,
	error_count: int,
	last_error: Parse_File_Error,
	time_to_tokenize: f64, // seconds
	time_to_parse: f64,   // seconds

	lead_comment: ^Comment_Group,  // Comment (block) before the decl
	line_comment: ^Comment_Group,  // Comment after the semicolon
	docs: ^Comment_Group,           // current docs
	comments: [dynamic]^Comment_Group , // All the comments!

	// This is effectively a queue but does not require any multi-threading capabilities
	delayed_decls_queues: [Ast_Delay_Queue_Kind]^Node,
 
	fix_count: int,
	fix_prev_pos: Token_Pos,

	//struct LLVMOpaqueMetadata *llvm_metadata
	//struct LLVMOpaqueMetadata *llvm_metadata_scope;
}

PARSER_MAX_FIX_COUNT :: 6

 Node_Foreign_File_Kind :: enum {
	Invalid,

	S, // Source,
}

 Node_Foreign_File :: struct {
	 kind: Node_Foreign_File_Kind,
	 source: string,
}


 Node_Package_Exported_Entity :: struct {
	identifier: ^Node,
	entity: ^Entity,
}

Ast_Package :: struct  {
	 kind: Package_Kind,
	 id: int,
	 name: string,
	 fullpath: string,
	 files: [dynamic]^Ast_File,
	 foreign_files: [dynamic]Node_Foreign_File,
	 is_single_file: bool,
	 order: int,
	 files_mutex: sync.Mutex,
	 foreign_files_mutex: sync.Mutex,
	 type_and_value_mutex: sync.Mutex,
	 name_mutex: sync.Mutex,
	// NOTE(bill): This must be a MPMCQueue
	 exported_entity_queue_mpmc: queue.Queue(Node_Package_Exported_Entity),

	// NOTE(bill): Created/set in checker
	scope: ^Scope,
	decl_info: ^Decl_Info,
	is_extra: bool,
};


Parse_File_Error_Node :: struct  {
	next, prev: ^Parse_File_Error_Node,
    err: Parse_File_Error,
};

Parser :: struct  {
	init_fullpath: string,

	imported_files: map[string]bool, // fullpath set
	imported_files_mutex: sync.Mutex,

	packages: [dynamic]^Ast_Package,
	packages_mutex: sync.Mutex,

	file_to_process_count_atomic: int,
	total_token_count_atomic: int,
	total_line_count_atomic: int,

	// TODO(bill): What should this mutex be per?
	//  * Parser
	//  * Package
	//  * File
	file_decl_mutex: sync.Mutex,         

	file_error_mutex: sync.Mutex,
	file_error_head: ^Parse_File_Error_Node,
	file_error_tail: ^Parse_File_Error_Node,
}

Parser_Worker_Data :: struct  {
	parser: ^Parser,
	imported_file: Imported_File,
}

Foreign_File_Worker_Data :: struct  {
	parser: ^Parser,
	imported_file: Imported_File,
	foreign_kind: Node_Foreign_File_Kind,
}



Proc_Inlining :: enum {
	None = 0,
	Inline = 1,
	No_Inline = 2,
}

Proc_Tag :: enum  {
	Bounds_Check    = 1<<0,
	No_Bounds_Check = 1<<1,
	Type_Assert     = 1<<2,
	No_type_Assert  = 1<<3,

	Require_Results = 1<<4,
	Optional_Ok     = 1<<5,
	Optional_Allocator_Error = 1<<6,
}

Proc_Tags :: bit_set[Proc_Tag]

Proc_Calling_Convention :: enum  i32 {
	Invalid     = 0,
	Odin        = 1,
	Contextless = 2,
	CDecl       = 3,
	Std_Call     = 4,
	Fast_Call    = 5,

	None        = 6,
	Naked       = 7,

	Inline_Asm   = 8,

	Win64       = 9,
	SysV        = 10,


	//MAX,


	//Foreign_Block_Default = -1, // Todo(Dragos): Make this part of the enum properly so i can enumare the next array
};

proc_calling_convention_strings := [Proc_Calling_Convention]string {
	.Invalid = "",
	.Odin = "odin",
	.Contextless = "contextless",
	.CDecl = "cdecl",
	.Std_Call = "stdcall",
	.Fast_Call = "fastcall",
	.None = "none",
	.Naked = "naked",
	.Inline_Asm = "inlineasm",
	.Win64 = "win64",
	.SysV = "sysv",
};

  default_calling_convention :: proc() -> Proc_Calling_Convention {
	return .Odin;
}

 State_Flag :: enum u8 {
	Bounds_Check    = 1<<0,
	No_Bounds_Check = 1<<1,
	Type_Assert     = 1<<2,
	No_Type_Assert  = 1<<3,

	Selector_Call_Expr = 1<<5,
	Directive_Was_False = 1<<6,

	Been_Handled = 1<<7,
}

State_Flags :: bit_set[State_Flag]

Viral_State_Flag :: enum u8 {
	ViralStateFlag_ContainsDeferredProcedure = 1<<0,
}

Viral_State_Flags :: bit_set[Viral_State_Flag]

// Todo(Dragos): This is a bit more complicated
Field_Flag :: enum u32 {
	FieldFlag_NONE      = 0,
	FieldFlag_ellipsis  = 1<<0,
	FieldFlag_using     = 1<<1,
	FieldFlag_no_alias  = 1<<2,
	FieldFlag_c_vararg  = 1<<3,

	FieldFlag_const     = 1<<5,
	FieldFlag_any_int   = 1<<6,
	FieldFlag_subtype   = 1<<7,
	FieldFlag_by_ptr    = 1<<8,

	// Internal use by the parser only
	FieldFlag_Tags      = 1<<10,
	FieldFlag_Results   = 1<<16,


	FieldFlag_Unknown   = 1<<30,
	FieldFlag_Invalid   = 1<<31,

	// Parameter List Restrictions
	FieldFlag_Signature = FieldFlag_ellipsis|FieldFlag_using|FieldFlag_no_alias|FieldFlag_c_vararg|FieldFlag_const|FieldFlag_any_int|FieldFlag_by_ptr,
	FieldFlag_Struct    = FieldFlag_using|FieldFlag_subtype|FieldFlag_Tags,
}

 Stmt_Allow_Flag :: enum {
	In      = 1<<0,
	Label   = 1<<1,
}

Stmt_Allow_Flags :: bit_set[Stmt_Allow_Flag]

 Inline_Asm_Dialect_Kind :: enum u8 {
	Default, // ATT is default
	ATT,
	Intel,
};

inline_asm_dialect_strings: [Inline_Asm_Dialect_Kind]string = {
	.Default = "",
	.ATT = "att",
	.Intel = "intel",
}


union_type_kind_strings := [Union_Type_Kind]string {
	.Normal = "(normal)",
	//"#maybe", // Note(Dragos): What this?
	.No_Nil = "#no_nil",
	.Shared_Nil = "#shared_nil",
};

Node_Ident :: struct { // "identifier"
	token: Token,
	entity: ^Entity,
}

Node_Implicit :: struct {
	token: Token,
} // "implicit"
Node_Uninit :: struct {
	token: Token,
} // "uninitialized value"

Node_Basic_Lit :: struct {
	token: Token,
}

Node_Basic_Directive :: struct { // "basic directive"
	token: Token,
	name: Token,
}

Node_Ellipsis :: struct { // "ellipsis"
	token: Token,
	expr: ^Node,
}

Node_Proc_Group :: struct { // "procedure group"
	token: Token,
	open: Token,
	close: Token,
	args: []^Node,
}

Node_Proc_Lit :: struct { // "procedural literal"
	type: ^Node,
	body: ^Node,
	tags: u64,
	inlining: Proc_Inlining,
	where_token: Token,
	where_clauses: []^Node,
	decl: ^Decl_Info,
}

Node_Compound_Lit :: struct { // "compound literal"
	type: ^Node,
	elems: []^Node,
	open, close: Token,
	max_count: i64 ,
	tag: ^Node,
}

Node__ExprBegin :: bool // ""

Node_Bad_Expr :: struct { // "bad expression"
	begin, end: Token,
}

Node_Tag_Expr :: struct { // "tag expression"
	token, name: Token,
	expr: ^Node,
}

Node_Unary_Expr :: struct { // "unary expression"
	op: Token,
	expr: ^Node,
}

Node_Binary_Expr :: struct { // "binary expression"
	op: Token,
	left, right: ^Node,
}

Node_Paren_Expr :: struct { // "parentheses expression"
	expr: ^Node,
	open, close: Token,
}

Node_Selector_Expr :: struct { // "selector expression"
	token: Token,
	expr, selector: ^Node,
	swizzle_count: u8, // maximum of 4 components, if set, count >= 2
	swizzle_indices: u8, // 2 bits per component
}

Node_Implicit_Selector_Expr :: struct {
	token: Token,
	selector: ^Node,
}

Node_Selector_Call_Expr :: struct {
    token: Token,
    expr, call: ^Node,
    modified_call: bool,
}

Node_Index_Expr :: struct { // "index expression"
	expr, index: ^Node,
	open, close: Token,
}

Node_Deref_Expr :: struct { // "dereference expression"
	expr: ^Node,
	op: Token,
}

Node_Slice_Expr :: struct { // "slice expression"
	expr: ^Node,
	open, close: Token,
	interval: Token,
	low, high: ^Node,
}

Node_Call_Expr :: struct { // "call expression"
	procedure: ^Node,
	args: []^Node,
	open: Token,
	close: Token,
	ellipsis: Token,
	inlining: Proc_Inlining,
	optional_ok_one: bool,
	was_selector: bool,
}

Node_Field_Value :: struct { // "field value"
	eq: Token,
	field, value: ^Node,
}

Node_Enum_Field_Value :: struct { // "enum field value"
	name: ^Node,
	value: ^Node,
	docs: ^Comment_Group,
	comment: ^Comment_Group,
}

Node_Ternary_If_Expr :: struct { // "ternary if expression"
	x, cond, y: ^Node,
}

Node_Ternary_When_Expr :: struct { // "ternary when expression"
	x, cond, y: ^Node,
}

Node_Or_Else_Expr :: struct { // "or_else expression"
	x: ^Node,
	token: Token,
	y: ^Node,
}

Node_Or_Return_Expr :: struct { // "or_return expression"
	expr: ^Node,
	token: Token,
}

Node_Type_Assertion :: struct { // "type assertion"
	expr: ^Node,
	dot: Token,
	type: ^Node,
	type_hint: ^Type,
	ignores: [2]bool,
}

Node_Type_Cast :: struct { // "type cast"
	token: Token,
	type, expr: ^Node,
}

Node_Auto_Cast :: struct { // "auto_cast"
	token: Token,
	expr: ^Node,
}

Node_Inline_Asm_Expr :: struct { // "inline asm expression"
	token: Token,
	open, close: Token,
	param_types: []^Node,
	return_type: ^Node,
	asm_string: ^Node,
	constraints_string: ^Node,
	has_side_effects: bool,
	is_align_stack: bool,
	dialect: Inline_Asm_Dialect_Kind,
}

Node_Matrix_Index_Expr :: struct { // "matrix index expression"
	expr, row_index, column_index: ^Node,
	open, close: Token,
}

Node__Expr_End :: bool
Node__Stmt_Begin :: bool

Node_Bad_Stmt :: struct { // "bad statement"
	begin, end: Token,
}

Node_Empty_Stmt :: struct { // "empty statement"
	token: Token,
}

Node_Expr_Stmt :: struct { // "expression statement"
	expr: ^Node,
}

Node_Assign_Stmt :: struct { // "assign statement"
	op: Token,
	lhs, rhs: []^Node,
}

Node__Complex_Stmt_Begin :: bool

Node_Block_Stmt :: struct { // "block statement"
	scope: ^Scope,
	stmts: []^Node,
	label: ^Node,
	open, close: Token,
}

Node_If_Stmt :: struct { // "if statement"
	scope: ^Scope,
	token: Token,
	label: ^Node,
	init: ^Node,
	cond: ^Node,
	body: ^Node,
	else_stmt: ^Node,
}

Node_When_Stmt :: struct { // "when statement"
	token: Token,
	cond: ^Node,
	body: ^Node,
	else_stmt: ^Node,
	is_cond_determined: bool,
	determined_cond: bool,
}

Node_Return_Stmt :: struct { // "return statement"
	token: Token,
	results: []^Node,
}

Node_For_Stmt :: struct { // "for statement"
	scope: ^Scope,
	token: Token,
	label: ^Node,
	init: ^Node,
	cond: ^Node,
	post: ^Node,
	body: ^Node,
}

Node_Range_Stmt :: struct { // "range statement"
	scope: ^Scope,
	token: Token,
	label: ^Node,
	vals: []^Node,
	in_token: Token,
	expr: ^Node,
	body: ^Node,
	reverse: bool,
}

Node_Unroll_Range_Stmt :: struct { // "#unroll range statement"
	scope: ^Scope,
	unroll_token: Token,
	for_token: Token,
	val0, val1: ^Node,
	in_token: Token,
	expr: ^Node,
	body: ^Node,
}

Node_Case_Clause :: struct { // "case clause"
	scope: ^Scope,
	token: Token,
	list: []^Node,
	stmts: []^Node,
	implicit_entity: ^Entity,
}

Node_Switch_Stmt :: struct { // "switch statement"
	scope: ^Scope,
	token: Token,
	label: ^Node,
	init: ^Node,
	tag: ^Node,
	body: ^Node,
	partial: bool,
}

Node_Type_Switch_Stmt :: struct { // "type switch statement"
	scope: ^Scope,
	token: Token,
	label: ^Node,
	tag: ^Node,
	body: ^Node,
	partial: bool,
}

Node_Defer_Stmt :: struct { // "defer statement"
	token: Token,
	stmt: ^Node,
}

Node_Branch_Stmt :: struct {
	token: Token,
	label: ^Node,
}

Node_Using_Stmt :: struct {
	token: Token,
	list: []^Node,
}

Node__Complex_Stmt_End :: bool
Node__Stmt_End :: bool
Node__Decl_Begin :: bool

Node_Bad_Decl :: struct {
	begin, end: Token,
}

Node_Foreign_Block_Decl :: struct {
	token: Token,
	foreign_library: ^Node,
	body: ^Node,
	attributes: [dynamic]^Node,
	docs: ^Comment_Group,
}

Node_Label :: struct {
	token: Token,
	name: ^Node,
}

Node_Value_Decl :: struct {
	names: []^Node,
	type: ^Node,
	values: []^Node,
	attributes: [dynamic]^Node,
	docs: ^Comment_Group,
	comment: ^Comment_Group,
	is_using, is_mutable: bool,
}

Node_Package_Decl :: struct {
	token: Token,
	name: Token,
	docs: ^Comment_Group,
	comment: ^Comment_Group,
}

Node_Import_Decl :: struct {
	pkg: ^Ast_Package,
	token: Token,
	relpath: Token,
	fullpath: string,
	import_name: Token,
	docs: ^Comment_Group,
	comment: ^Comment_Group,
}

Node_Foreign_Import_Decl :: struct {
	token: Token,
	filepaths: []Token,
	library_name: Token,
	collection_name: string,
	fullpaths: []string,
	attributes: [dynamic]^Node,
	docs: ^Comment_Group,
	comment: ^Comment_Group,
}

Node__Decl_End :: bool

Node_Attribute :: struct {
	token: Token,
	elems: []^Node,
	open, close: Token,
}

Node_Field :: struct {
	names: []^Node,
	type: ^Node,
	default_value: ^Node,
	tag: Token,
	flags: u32,
	docs: ^Comment_Group,
	comment: ^Comment_Group,
}

Node_Field_List :: struct {
	token: Token,
	list: []^Node,
}

Node__Type_Begin :: bool

Node_Typeid_Type :: struct {
	token: Token,
	specialization: ^Node,
}

Node_Helper_Type :: struct {
	token: Token,
	type: ^Node,
}

Node_Distinct_Type :: struct {
	token: Token,
	type: ^Node,
}

Node_Poly_Type :: struct {
	token: Token,
	type: ^Node,
	specialization: ^Node,
}

Node_Proc_Type :: struct {
	scope: ^Scope,
	token: Token,
	params: ^Node,
	results: ^Node,
	tags: u64,
	calling_convention: Proc_Calling_Convention,
	generic, diverging: bool,
}

Node_Pointer_Type :: struct {
	token: Token,
	type, tag: ^Node,
}

Node_Relative_Type :: struct {
	tag, type: ^Node,
}

Node_Multi_Pointer_Type :: struct {
	token: Token,
	type: ^Node,
}

Node_Array_Type :: struct {
	token: Token,
	count, elem, tag: ^Node,
}

Node_Dynamic_Array_Type :: struct {
	token: Token,
	elem, tag: ^Node,
}

Node_Struct_Type :: struct {
	scope: ^Scope,
	token: Token,
	fields: []^Node,
	field_count: int,
	polymorphic_params: ^Node,
	align: ^Node,
	where_token: Token,
	where_clauses: []^Node,
	is_packed, is_raw_union, is_no_copy: bool,
}

Node_Union_Type :: struct {
	scope: ^Scope,
	token: Token,
	variants: []^Node,
	polymorphic_params: ^Node,
	align: ^Node,
	kind: Union_Type_Kind,
	where_token: Token,
	where_clauses: []^Node,
}

Node_Enum_Type :: struct {
	scope: ^Scope,
	token: Token,
	base_type: ^Node,
	fields: ^Node, // FieldValue
	is_using: bool,
}

Node_Bit_Set_Type :: struct {
	token: Token,
	elem: ^Node,
	underlying: ^Node,
}

Node_Map_Type :: struct {
	token: Token,
	count, key, value: ^Node, // Note(Dragos): What is count????
}

Node_Matrix_Type :: struct {
	token: Token,
	row_count, column_count, elem: ^Node,
}

Node__TypeEnd :: bool

NodeKind :: enum u16 {
	Invalid,
	Ident,
	Implicit,
	Uninit,
	BasicLit,
	BasicDirective,
	Ellipsis,
	ProcGroup,
	ProcLit,
	CompoundLit,
	_ExprBegin,
		BadExpr,
		TagExpr,
		UnaryExpr,
		BinaryExpr,
		ParenExpr,
		SelectorExpr,
		ImplicitSelectorExpr,
		SelectorCallExpr,
		IndexExpr,
		DerefExpr,
		SliceExpr,
		CallExpr,
		FieldValue,
		EnumFieldValue,
		TernaryIfExpr,
		TernaryWhenExpr,
		OrElseExpr,
		OrReturnExpr,
		TypeAssertion,
		TypeCast,
		AutoCast,
		InlineAsmExpr,
		MatrixIndexExpr,
	_ExprEnd,
	_StmtBegin,
		BadStmt,
		EmptyStmt,
		ExprStmt,
		AssignStmt,
		_ComplexStmtBegin,
			BlockStmt,
			IfStmt,
			WhenStmt,
			ReturnStmt,
			ForStmt,
			RangeStmt,
			UnrollRangeStmt,
			CaseClause,
			SwitchStmt,
			TypeSwitchStmt,
			DeferStmt,
			BranchStmt,
			UsingStmt,
		_ComplexStmtEnd,
	_StmtEnd,
	_DeclBegin,
		BadDecl,
		ForeignBlockDecl,
		Label,
		ValueDecl,
		PackageDecl,
		ImportDecl,
		ForeignImportDecl,
	_DeclEnd,
	Field,
	FieldList,
	_TypeBegin,
		HelperType,
		DistinctType,
		PolyType,
		ProcType,
		PointerType,
		RelativeType,
		MultiPointerType,
		ArrayType,
		DynamicArrayType,
		StructType,
		UnionType,
		EnumType,
		BitSetType,
		MapType,
		MatrixType,
	_TypeEnd,
	COUNT,
}


ast_strings := [NodeKind.COUNT]string {
	// TODO
}

// Note(Dragos) size_of(Node_Whatever)
/*
ast_variant_sizes := [NodeKind.COUNT]int {
	// TODO
}*/

/*
Node_Expr :: struct {
	using expr_base: Node,
	derived_expr: Any_Expr,
}

Node_Stmt :: struct {
	using stmt_base: Node,
	derived_stmt: Any_Stmt,
}

Node_Decl :: struct {
	using decl_base: Node_Stmt,
}
*/

Derived_Node :: union {
	Node_Ident,
	Node_Implicit,
	Node_Uninit,
	Node_Basic_Lit,
	Node_Basic_Directive,
	Node_Ellipsis,
	Node_Proc_Group,
	Node_Proc_Lit,
	Node_Compound_Lit,

	// Expressions
		Node_Bad_Expr,
		Node_Tag_Expr,
		Node_Unary_Expr,
		Node_Binary_Expr,
		Node_Paren_Expr,
		Node_Selector_Expr,
		Node_Implicit_Selector_Expr,
		Node_Selector_Call_Expr,
		Node_Index_Expr,
		Node_Deref_Expr,
		Node_Slice_Expr,
		Node_Call_Expr,
		Node_Field_Value,
		Node_Enum_Field_Value,
		Node_Ternary_If_Expr,
		Node_Ternary_When_Expr,
		Node_Or_Else_Expr,
		Node_Or_Return_Expr,
		Node_Type_Cast,
		Node_Auto_Cast,
		Node_Inline_Asm_Expr,
		Node_Matrix_Index_Expr,
	// Statements
		Node_Bad_Stmt,
		Node_Empty_Stmt,
		Node_Expr_Stmt,
		Node_Assign_Stmt,
	// Complex statements
			Node_Block_Stmt,
			Node_If_Stmt,
			Node_When_Stmt,
			Node_Return_Stmt,
			Node_For_Stmt,
			Node_Range_Stmt,
			Node_Unroll_Range_Stmt,
			Node_Case_Clause,
			Node_Switch_Stmt,
			Node_Type_Switch_Stmt,
			Node_Defer_Stmt,
			Node_Branch_Stmt,
			Node_Using_Stmt,
	// Declarations
		Node_Bad_Decl,
		Node_Foreign_Block_Decl,
		Node_Label,
		Node_Value_Decl,
		Node_Import_Decl,
		Node_Foreign_Import_Decl,
	// Others
		Node_Field,
		Node_Field_List,
	// Types
		Node_Helper_Type,
		Node_Distinct_Type,
		Node_Poly_Type,
		Node_Proc_Type,
		Node_Pointer_Type,
		Node_Relative_Type,
		Node_Multi_Pointer_Type,
		Node_Array_Type,
		Node_Dynamic_Array_Type,
		Node_Struct_Type,
		Node_Union_Type,
		Node_Enum_Type,
		Node_Bit_Set_Type,
		Node_Map_Type,
		Node_Matrix_Type,
}

/*

Any_Expr :: union {
	^Node_Bad_Expr,
	^Node_Tag_Expr,
	^Node_Unary_Expr,
	^Node_Binary_Expr,
	^Node_Paren_Expr,
	^Node_Selector_Expr,
	^Node_Implicit_Selector_Expr,
	^Node_Selector_Call_Expr,
	^Node_Index_Expr,
	^Node_Deref_Expr,
	^Node_Slice_Expr,
	^Node_Call_Expr,
	^Node_Field_Value,
	^Node_Enum_Field_Value,
	^Node_Ternary_If_Expr,
	^Node_Ternary_When_Expr,
	^Node_Or_Else_Expr,
	^Node_Or_Return_Expr,
	^Node_Type_Assertion,
	^Node_Type_Cast,
	^Node_Auto_Cast,
	^Node_Inline_Asm_Expr,
	^Node_Matrix_Index_Expr,
}

Any_Stmt :: union {
	^Node_Block_Stmt,
	^Node_If_Stmt,
	^Node_When_Stmt,
	^Node_Return_Stmt,
	^Node_For_Stmt,
	^Node_Range_Stmt,
	^Node_Unroll_Range_Stmt,
	^Node_Case_Clause,
	^Node_Switch_Stmt,
	^Node_Type_Switch_Stmt,
	^Node_Defer_Stmt,
	^Node_Branch_Stmt,
	^Node_Using_Stmt,

	^Node_Bad_Decl,
	^Node_Value_Decl,
	^Node_Package_Decl,
	^Node_Import_Decl,
	^Node_Foreign_Block_Decl,
	^Node_Foreign_Import_Decl,
}

*/

Node :: struct  {
	/*
	pos: Token_Pos,
	end: Token_Pos,
	*/
	state_flags: State_Flags,
	viral_state_flags: Viral_State_Flags,
	file_id: i32, // Note(Dragos): The file is already in the token. Do we need?
	tav: Type_And_Value, // NOTE(bill): Making this a pointer is slower
	variant: Derived_Node,
}
