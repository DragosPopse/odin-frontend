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
	pkg: ^Package,
	fi: File_Info,
	pos: Token_Pos, // import
	index: int,
}

File_Flag :: enum u32 {
	Is_Private_Pkg = 1<<0,
	Is_Private_File = 1<<1,

	Is_Test    = 1<<3,
	Is_Lazy    = 1<<4,
}
File_Flags :: bit_set[File_Flag]

Ast_Delay_Queue_Kind :: enum {
	Import,
	Expr,
}

File :: struct {
	id: i32,
	flags: File_Flags,
	pkg: ^Package,
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

Package :: struct  {
	 kind: Package_Kind,
	 id: int,
	 name: string,
	 fullpath: string,
	 files: [dynamic]^File,
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

	packages: [dynamic]^Package,
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
	No_Type_Assert  = 1<<3,

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

	Foreign_Block_Default,
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
	.Foreign_Block_Default = "", // Is this ok?
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
	Ellipsis  ,
	Using     ,
	No_Alias  ,
	C_Vararg  ,

	Const     ,
	Any_Int   ,
	Subtype   ,
	By_Ptr    ,

	// Internal use by the parser only
	Tags      ,
	Results   ,


	Unknown   ,
	Invalid   ,
}

Field_Flags :: bit_set[Field_Flag]
// Parameter List Restrictions
Field_Flags_Signature := Field_Flags{.Ellipsis, .Using, .No_Alias, .C_Vararg, .Const, .Any_Int, .By_Ptr}
Field_Flags_Struct := Field_Flags{.Using, .Subtype, .Tags}

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
	tags: Proc_Tags,
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
	pkg: ^Package,
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
	flags: Field_Flags,
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
	tags: Proc_Tags,
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
	fields: []^Node, // FieldValue
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
		Node_Type_Assertion,
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
		Node_Package_Decl,
	// Others
		Node_Field,
		Node_Field_List,
		Node_Attribute,
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
		Node_Typeid_Type,
}

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

syntax_error_with_verbose_node :: proc(node: ^Node, msg: string, args: ..any) {
	unimplemented()
}

syntax_error_with_verbose :: proc {
	syntax_error_with_verbose_node,
}

// Todo(Dragos): Talk with bill about refactoring this eventually

new_node :: proc(f: ^File, $Variant: typeid, allocator := context.allocator) -> (node: ^Node, var: ^Variant) {
	context.allocator = allocator
	node = new(Node)
	node.variant = Variant{}
	node.file_id = f.id
	return node, &node.variant.(Variant)
}

make_bad_expr :: proc(f: ^File, begin, end: Token, allocator := context.allocator) -> (node: ^Node, bad_expr: ^Node_Bad_Expr) {
	context.allocator = allocator
	node, bad_expr = new_node(f, Node_Bad_Expr)
	bad_expr.begin = begin
	bad_expr.end = end
	return node, bad_expr
}

make_tag_expr :: proc(f: ^File, token, name: Token, expr: ^Node, allocator := context.allocator) -> (node: ^Node, tag: ^Node_Tag_Expr) {
	context.allocator = allocator
	node, tag = new_node(f, Node_Tag_Expr)
	tag.token = token
	tag.name = name
	tag.expr = expr
	return node, tag
}

make_unary_expr :: proc(f: ^File, op: Token, expr: ^Node, allocator := context.allocator) -> (node: ^Node, unary_expr: ^Node_Unary_Expr) {
	context.allocator = allocator
	node, unary_expr = new_node(f, Node_Unary_Expr)
	#partial switch in expr.variant {
	case Node_Or_Return_Expr: 
		syntax_error_with_verbose(expr, "'or_return' within an unary expression not wrapped in parantheses (...)")
	}

	unary_expr.op = op
	unary_expr.expr = expr
	return node, unary_expr
}

make_binary_expr :: proc(f: ^File, op: Token, left, right: ^Node, allocator := context.allocator) -> (node: ^Node, binary_expr: ^Node_Binary_Expr) {
	context.allocator = allocator
	node, binary_expr = new_node(f, Node_Binary_Expr)
	if left == nil {
		syntax_error(op, "No lhs expression for binary expression '%v'", op.text)
		binary_expr.left, _ = make_bad_expr(f, op, op)
	}

	if right == nil {
		syntax_error(op, "No rhs expression for binary expression '%v'", op.text)
		binary_expr.right, _ = make_bad_expr(f, op, op)
	}

	#partial switch in left.variant {
	case Node_Or_Return_Expr: 
		syntax_error_with_verbose(left, "'or_return' within a binary expression not wrapped in parantheses (...)")
	}

	#partial switch in left.variant {
	case Node_Or_Return_Expr: 
		syntax_error_with_verbose(left, "'or_return' within a binary expression not wrapped in parantheses (...)")
	}

	binary_expr.op = op

	return node, binary_expr
}

make_paren_expr :: proc(f: ^File, expr: ^Node, open, close: Token, allocator := context.allocator) -> (node: ^Node, paren_expr: ^Node_Paren_Expr) {
	context.allocator = allocator
	node, paren_expr = new_node(f, Node_Paren_Expr)
	paren_expr.expr = expr
	paren_expr.open = open
	paren_expr.close = close
	return node, paren_expr
}

make_call_expr :: proc(f: ^File, procedure: ^Node, args: []^Node, open, close: Token, ellipsis: Token, allocator := context.allocator) -> (node: ^Node, call_expr: ^Node_Call_Expr) {
	context.allocator = allocator
	node, call_expr = new_node(f, Node_Call_Expr)
	call_expr.procedure = procedure
	call_expr.args = args
	call_expr.open = open
	call_expr.close = close
	call_expr.ellipsis = ellipsis
	return node, call_expr
}

make_selector_expr :: proc(f: ^File, token: Token, expr: ^Node, selector: ^Node, allocator := context.allocator) -> (node: ^Node, selector_expr: ^Node_Selector_Expr) {
	context.allocator = allocator
	node, selector_expr = new_node(f, Node_Selector_Expr)
	selector_expr.token = token
	selector_expr.selector = selector
	return node, selector_expr
}

make_implicit_selector_expr :: proc(f: ^File, token: Token, selector: ^Node, allocator := context.allocator) -> (node: ^Node, selector_expr: ^Node_Implicit_Selector_Expr) {
	context.allocator = allocator
	node, selector_expr = new_node(f, Node_Implicit_Selector_Expr)
	selector_expr.token = token
	selector_expr.selector = selector
	return node, selector_expr
}

make_selector_call_expr :: proc(f: ^File, token: Token, expr: ^Node, call: ^Node, allocator := context.allocator) -> (node: ^Node, selector_call_expr: ^Node_Selector_Call_Expr) {
	context.allocator = allocator
	node, selector_call_expr = new_node(f, Node_Selector_Call_Expr)
	selector_call_expr.token = token
	selector_call_expr.expr = expr
	selector_call_expr.call = call
	return node, selector_call_expr
}

make_index_expr :: proc(f: ^File, expr: ^Node, index: ^Node, open, close: Token, allocator := context.allocator) -> (node: ^Node, index_expr: ^Node_Index_Expr) {
	context.allocator = allocator
	node, index_expr = new_node(f, Node_Index_Expr)
	index_expr.expr = expr
	index_expr.index = index
	index_expr.open = open
	index_expr.close = close
	return node, index_expr
}

// note(dragos): what is interval?
make_slice_expr :: proc(f: ^File, expr: ^Node, open, close, interval: Token, low, high: ^Node, allocator := context.allocator) -> (node: ^Node, slice_expr: ^Node_Slice_Expr) {
	context.allocator = allocator
	node, slice_expr = new_node(f, Node_Slice_Expr)
	slice_expr.expr = expr
	slice_expr.open = open
	slice_expr.close = close
	slice_expr.interval = interval
	slice_expr.low = low
	slice_expr.high = high
	return node, slice_expr
}

make_deref_expr :: proc(f: ^File, expr: ^Node, op: Token, allocator := context.allocator) -> (node: ^Node, deref_expr: ^Node_Deref_Expr) {
	context.allocator = allocator
	node, deref_expr = new_node(f, Node_Deref_Expr)
	deref_expr.expr = expr
	deref_expr.op = op
	return node, deref_expr
}

make_matrix_index_expr :: proc(f: ^File, expr: ^Node, open, close, interval: Token, row, column: ^Node, allocator := context.allocator) -> (node: ^Node, matrix_index_expr: ^Node_Matrix_Index_Expr) {
	context.allocator = allocator
	node, matrix_index_expr = new_node(f, Node_Matrix_Index_Expr)
	matrix_index_expr.expr = expr
	matrix_index_expr.row_index = row
	matrix_index_expr.column_index = column
	matrix_index_expr.open = open
	matrix_index_expr.close = close
	return node, matrix_index_expr
}

make_ident :: proc(f: ^File, token: Token, allocator := context.allocator) -> (node: ^Node, ident: ^Node_Ident) {
	context.allocator = allocator
	node, ident = new_node(f, Node_Ident)
	ident.token = token
	return node, ident
}

make_implicit :: proc(f: ^File, token: Token, allocator := context.allocator) -> (node: ^Node, implicit: ^Node_Implicit) {
	context.allocator = allocator
	node, implicit = new_node(f, Node_Implicit)
	implicit.token = token
	return node, implicit
}

make_uninit :: proc(f: ^File, token: Token, allocator := context.allocator) -> (node: ^Node, uninit: ^Node_Uninit) {
	context.allocator = allocator
	node, uninit = new_node(f, Node_Uninit)
	uninit.token = token
	return node, uninit
}

exact_value_from_token :: proc(f: ^File, token: Token) -> Exact_Value {
	unimplemented()
}

make_basic_lit :: proc(f: ^File, basic_lit: Token, allocator := context.allocator) -> (node: ^Node, lit: ^Node_Basic_Lit) {
	context.allocator = allocator
	node, lit = new_node(f, Node_Basic_Lit)
	lit.token = basic_lit
	node.tav.mode = .Constant
	node.tav.value = exact_value_from_token(f, basic_lit)
	return node, lit
}

make_basic_directive :: proc(f: ^File, token, name: Token, allocator := context.allocator) -> (node: ^Node, basic_directive: ^Node_Basic_Directive) {
	context.allocator = allocator
	node, basic_directive = new_node(f, Node_Basic_Directive)
	basic_directive.token = token
	basic_directive.name = name
	return node, basic_directive
}

make_ellipsis :: proc(f: ^File, token: Token, expr: ^Node, allocator := context.allocator) -> (node: ^Node, ellipsis: ^Node_Ellipsis) {
	context.allocator = allocator
	node, ellipsis = new_node(f, Node_Ellipsis)
	ellipsis.token = token
	ellipsis.expr = expr
	return node, ellipsis
}

make_proc_group :: proc(f: ^File, token, open, close: Token, args: []^Node, allocator := context.allocator) -> (node: ^Node, proc_group: ^Node_Proc_Group) {
	context.allocator = allocator
	node, proc_group = new_node(f, Node_Proc_Group)
	proc_group.token = token
	proc_group.open = open
	proc_group.close = close
	proc_group.args = args
	return node, proc_group
}

make_proc_lit :: proc(f: ^File, type, body: ^Node, tags: Proc_Tags, where_token: Token, where_clauses: []^Node, allocator := context.allocator) -> (node: ^Node, proc_lit: ^Node_Proc_Lit) {
	context.allocator = allocator
	node, proc_lit = new_node(f, Node_Proc_Lit)
	proc_lit.type = type
	proc_lit.body = body
	proc_lit.tags = tags
	proc_lit.where_token = where_token
	proc_lit.where_clauses = where_clauses
	return node, proc_lit
}

make_field_value :: proc(f: ^File, field, value: ^Node, eq: Token, allocator := context.allocator) -> (node: ^Node, field_value: ^Node_Field_Value) {
	context.allocator = allocator
	node, field_value = new_node(f, Node_Field_Value)
	field_value.field = field
	field_value.value = value
	field_value.eq = eq
	return node, field_value
}

make_enum_field_value :: proc(f: ^File, name, value: ^Node, docs, comment: ^Comment_Group, allocator := context.allocator) -> (node: ^Node, enum_field_value: ^Node_Enum_Field_Value) {
	context.allocator = allocator
	node, enum_field_value = new_node(f, Node_Enum_Field_Value)
	enum_field_value.name = name
	enum_field_value.value = value
	enum_field_value.docs = docs
	enum_field_value.comment = comment
	return node, enum_field_value
}

make_compound_lit :: proc(f: ^File, type: ^Node, elems: []^Node, open, close: Token, allocator := context.allocator) -> (node: ^Node, compound_lit: ^Node_Compound_Lit) {
	context.allocator = allocator
	node, compound_lit = new_node(f, Node_Compound_Lit)
	compound_lit.type = type
	compound_lit.elems = elems
	compound_lit.open = open
	compound_lit.close = close
	return node, compound_lit
}

make_ternary_if_expr :: proc(f: ^File, x, cond, y: ^Node, allocator := context.allocator) -> (node: ^Node, expr: ^Node_Ternary_If_Expr) {
	context.allocator = allocator
	node, expr = new_node(f, Node_Ternary_If_Expr)
	expr.x = x
	expr.cond = cond 
	expr.y = y
	return node, expr
}

make_ternary_when_expr :: proc(f: ^File, x, cond, y: ^Node, allocator := context.allocator) -> (node: ^Node, expr: ^Node_Ternary_When_Expr) {
	context.allocator = allocator
	node, expr = new_node(f, Node_Ternary_When_Expr)
	expr.x = x
	expr.cond = cond 
	expr.y = y
	return node, expr
}

make_or_else_expr :: proc(f: ^File, x: ^Node, token: Token, y: ^Node, allocator := context.allocator) -> (node: ^Node, expr: ^Node_Or_Else_Expr) {
	context.allocator = allocator
	node, expr = new_node(f, Node_Or_Else_Expr)
	expr.x = x
	expr.token = token
	expr.y = y
	return node, expr
}

make_or_return_expr :: proc(f: ^File, expr: ^Node, token: Token, allocator := context.allocator) -> (node: ^Node, or_expr: ^Node_Or_Return_Expr) {
	context.allocator = allocator
	node, or_expr = new_node(f, Node_Or_Return_Expr)
	or_expr.expr = expr
	or_expr.token = token
	return node, or_expr
}

make_type_assertion :: proc(f: ^File, expr: ^Node, dot: Token, type: ^Node, allocator := context.allocator) -> (node: ^Node, type_assertion: ^Node_Type_Assertion) {
	context.allocator = allocator
	node, type_assertion = new_node(f, Node_Type_Assertion)
	type_assertion.expr = expr
	type_assertion.dot = dot
	type_assertion.type = type
	return node, type_assertion
}

make_type_cast :: proc(f: ^File, token: Token, type: ^Node, expr: ^Node, allocator := context.allocator) -> (node: ^Node, var: ^Node_Type_Cast) {
	context.allocator = allocator
	node, var = new_node(f, Node_Type_Cast)
	var.token = token
	var.type = type
	var.expr = expr
	return node, var
}

make_auto_cast :: proc(f: ^File, token: Token, expr: ^Node, allocator := context.allocator) -> (node: ^Node, var: ^Node_Auto_Cast) {
	context.allocator = allocator
	node, var = new_node(f, Node_Auto_Cast)
	var.token = token
	var.expr = expr
	return node, var
}

make_inline_asm_expr :: proc() {
	unimplemented("add parameters too... it's just too long... i'm lazy...")
}

make_bad_stmt :: proc(f: ^File, begin, end: Token, allocator := context.allocator) -> (node: ^Node, bad_stmt: ^Node_Bad_Stmt) {
	node, bad_stmt = new_node(f, Node_Bad_Stmt, allocator)
	bad_stmt.begin = begin
	bad_stmt.end = end
	return node, bad_stmt
}

make_empty_stmt :: proc(f: ^File, token: Token, allocator := context.allocator) -> (node: ^Node, empty_stmt: ^Node_Empty_Stmt) {
	node, empty_stmt = new_node(f, Node_Empty_Stmt, allocator)
	empty_stmt.token = token
	return node, empty_stmt
}

make_expr_stmt :: proc(f: ^File, expr: ^Node, allocator := context.allocator) -> (node: ^Node, expr_stmt: ^Node_Expr_Stmt) {
	node, expr_stmt = new_node(f, Node_Expr_Stmt, allocator)
	expr_stmt.expr = expr
	return node, expr_stmt
}

make_assign_stmt :: proc(f: ^File, op: Token, lhs: []^Node, rhs: []^Node, allocator := context.allocator) -> (node: ^Node, assign_stmt: ^Node_Assign_Stmt) {
	node, assign_stmt = new_node(f, Node_Assign_Stmt, allocator)
	assign_stmt.op = op
	assign_stmt.lhs = lhs
	assign_stmt.rhs = rhs
	return node, assign_stmt
}

make_block_stmt :: proc(f: ^File, stmts: []^Node, open, close: Token, allocator := context.allocator) -> (node: ^Node, block_stmt: ^Node_Block_Stmt) {
	node, block_stmt = new_node(f, Node_Block_Stmt, allocator)
	block_stmt.stmts = stmts
	block_stmt.open = open
	block_stmt.close = close
	return node, block_stmt
}

make_if_stmt :: proc(f: ^File, token: Token, init: ^Node, cond: ^Node, body: ^Node, else_stmt: ^Node, allocator := context.allocator) -> (node: ^Node, if_stmt: ^Node_If_Stmt) {
	node, if_stmt = new_node(f, Node_If_Stmt, allocator)
	if_stmt.token = token
	if_stmt.init = init 
	if_stmt.cond = cond
	if_stmt.body = body
	if_stmt.else_stmt = else_stmt
	return node, if_stmt
}

make_when_stmt :: proc(f: ^File, token: Token, cond, body, else_stmt: ^Node, allocator := context.allocator) -> (node: ^Node, when_stmt: ^Node_When_Stmt) {
	node, when_stmt = new_node(f, Node_When_Stmt, allocator)
	when_stmt.token = token
	when_stmt.cond = cond
	when_stmt.body = body
	when_stmt.else_stmt = else_stmt
	return node, when_stmt
}

make_return_stmt :: proc(f: ^File, token: Token, results: []^Node, allocator := context.allocator) -> (node: ^Node, return_stmt: ^Node_Return_Stmt) {
	node, return_stmt = new_node(f, Node_Return_Stmt, allocator)
	return_stmt.token = token
	return_stmt.results = results
	return node, return_stmt
}

make_for_stmt :: proc(f: ^File, token: Token, init, cond, post, body: ^Node, allocator := context.allocator) -> (node: ^Node, for_stmt: ^Node_For_Stmt) {
	node, for_stmt = new_node(f, Node_For_Stmt, allocator)
	for_stmt.token = token
	for_stmt.init = init
	for_stmt.cond = cond
	for_stmt.post = post
	for_stmt.body = body
	return node, for_stmt
}

make_range_stmt :: proc(f: ^File, token: Token, vals: []^Node, in_token: Token, expr, body: ^Node, allocator := context.allocator) -> (node: ^Node, range_stmt: ^Node_Range_Stmt) {
	node, range_stmt = new_node(f, Node_Range_Stmt, allocator)
	range_stmt.token = token
	range_stmt.vals = vals
	range_stmt.in_token = in_token
	range_stmt.expr = expr
	range_stmt.body = body
	return node, range_stmt
}

make_unroll_range_stmt :: proc(f: ^File, unroll_token: Token, for_token: Token, val0, val1: ^Node, in_token: Token, expr, body: ^Node, allocator := context.allocator) -> (node: ^Node, range_stmt: ^Node_Unroll_Range_Stmt) {
	node, range_stmt = new_node(f, Node_Unroll_Range_Stmt, allocator)
	range_stmt.unroll_token = unroll_token
	range_stmt.for_token = for_token
	range_stmt.val0 = val0
	range_stmt.val1 = val1
	range_stmt.in_token = in_token
	range_stmt.expr = expr
	range_stmt.body = body
	return node, range_stmt
}

make_switch_stmt :: proc(f: ^File, token: Token, init, tag, body: ^Node, allocator := context.allocator) -> (node: ^Node, switch_stmt: ^Node_Switch_Stmt) {
	node, switch_stmt = new_node(f, Node_Switch_Stmt)
	switch_stmt.token = token
	switch_stmt.init = init
	switch_stmt.tag = tag
	switch_stmt.body = body
	switch_stmt.partial = false
	return node, switch_stmt
}

make_type_switch_stmt :: proc(f: ^File, token: Token, tag, body: ^Node, allocator := context.allocator) -> (node: ^Node, type_switch_stmt: ^Node_Type_Switch_Stmt) {
	node, type_switch_stmt = new_node(f, Node_Type_Switch_Stmt, allocator)
	type_switch_stmt.token = token
	type_switch_stmt.tag = tag
	type_switch_stmt.body = body
	type_switch_stmt.partial = false
	return node, type_switch_stmt
}

// Note(Dragos): Should we leave these dynamic arrays? Or make them dynamic arrays in the node themselves?
make_case_clause :: proc(f: ^File, token: Token, list: []^Node, stmts: []^Node, allocator := context.allocator) -> (node: ^Node, case_clause: ^Node_Case_Clause) {
	node, case_clause = new_node(f, Node_Case_Clause, allocator)
	case_clause.token = token
	case_clause.list = list
	case_clause.stmts = stmts
	return node, case_clause
}

make_defer_stmt :: proc(f: ^File, token: Token, stmt: ^Node, allocator := context.allocator) -> (node: ^Node, defer_stmt: ^Node_Defer_Stmt) {
	node, defer_stmt = new_node(f, Node_Defer_Stmt, allocator)
	defer_stmt.token = token
	defer_stmt.stmt = stmt
	return node, defer_stmt
}

make_branch_stmt :: proc(f: ^File, token: Token, label: ^Node, allocator := context.allocator) -> (node: ^Node, branch_stmt: ^Node_Branch_Stmt) {
	node, branch_stmt = new_node(f, Node_Branch_Stmt, allocator)
	branch_stmt.token = token
	branch_stmt.label = label
	return node, branch_stmt
}

make_using_stmt :: proc(f: ^File, token: Token, list: []^Node, allocator := context.allocator) -> (node: ^Node, using_stmt: ^Node_Using_Stmt) {
	node, using_stmt = new_node(f, Node_Using_Stmt, allocator)
	using_stmt.token = token
	using_stmt.list = list
	return node, using_stmt
}

make_bad_decl :: proc(f: ^File, begin, end: Token, allocator := context.allocator) -> (node: ^Node, bad_decl: ^Node_Bad_Decl) {
	node, bad_decl = new_node(f, Node_Bad_Decl, allocator)
	bad_decl.begin = begin
	bad_decl.end = end
	return node, bad_decl
}

make_field :: proc(f: ^File, names: []^Node, type: ^Node, default_value: ^Node, flags: Field_Flags, tag: Token, docs, comment: ^Comment_Group, allocator := context.allocator) -> (node: ^Node, field: ^Node_Field) {
	node, field = new_node(f, Node_Field, allocator)
	field.names = names
	field.type = type
	field.default_value = default_value
	field.flags = flags
	field.tag = tag
	field.docs = docs
	field.comment = comment
	return node, field
}

make_field_list :: proc(f: ^File, token: Token, list: []^Node, allocator := context.allocator) -> (node: ^Node, field_list: ^Node_Field_List) {
	node, field_list = new_node(f, Node_Field_List, allocator)
	field_list.token = token
	field_list.list = list
	return node, field_list
}

make_typeid_type :: proc(f: ^File, token: Token, specialization: ^Node, allocator := context.allocator) -> (node: ^Node, typeid_type: ^Node_Typeid_Type) {
	node, typeid_type = new_node(f, Node_Typeid_Type, allocator)
	typeid_type.token = token
	typeid_type.specialization = specialization
	return node, typeid_type
}

make_helper_type :: proc(f: ^File, token: Token, type: ^Node, allocator := context.allocator) -> (node: ^Node, helper: ^Node_Helper_Type) {
	node, helper = new_node(f, Node_Helper_Type, allocator)
	helper.token = token
	helper.type = type
	return node, helper
}

make_distinct_type :: proc(f: ^File, token: Token, type: ^Node, allocator := context.allocator) -> (node: ^Node, distinct_type: ^Node_Distinct_Type) {
	node, distinct_type = new_node(f, Node_Distinct_Type, allocator)
	distinct_type.token = token
	distinct_type.type = type
	return node, distinct_type
}

make_poly_type :: proc(f: ^File, token: Token, type: ^Node, specialization: ^Node, allocator := context.allocator) -> (node: ^Node, poly_type: ^Node_Poly_Type) {
	node, poly_type = new_node(f, Node_Poly_Type, allocator)
	poly_type.token = token
	poly_type.type = type
	poly_type.specialization = specialization
	return node, poly_type
}

make_proc_type :: proc(f: ^File, token: Token, params: ^Node, results: ^Node, tags: Proc_Tags, calling_convention: Proc_Calling_Convention, generic, diverging: bool, allocator := context.allocator) -> (node: ^Node, proc_type: ^Node_Proc_Type) {
	node, proc_type = new_node(f, Node_Proc_Type, allocator)
	proc_type.token = token
	proc_type.params = params
	proc_type.results = results
	proc_type.tags = tags
	proc_type.calling_convention = calling_convention
	proc_type.generic = generic 
	proc_type.diverging = diverging
	return node, proc_type
}

make_relative_type :: proc(f: ^File, tag: ^Node, type: ^Node, allocator := context.allocator) -> (node: ^Node, rel_type: ^Node_Relative_Type) {
	node, rel_type = new_node(f, Node_Relative_Type, allocator)
	rel_type.tag = tag
	rel_type.type = type
	return node, rel_type
}

make_pointer_type :: proc(f: ^File, token: Token, type: ^Node, allocator := context.allocator) -> (node: ^Node, pointer_type: ^Node_Pointer_Type) {
	node, pointer_type = new_node(f, Node_Pointer_Type, allocator)
	pointer_type.token = token
	pointer_type.type = type
	return node, pointer_type
}

make_multi_pointer_type :: proc(f: ^File, token: Token, type: ^Node, allocator := context.allocator) -> (node: ^Node, pointer_type: ^Node_Multi_Pointer_Type) {
	node, pointer_type = new_node(f, Node_Multi_Pointer_Type, allocator)
	pointer_type.token = token
	pointer_type.type = type
	return node, pointer_type
}

make_array_type :: proc(f: ^File, token: Token, count, elem: ^Node, allocator := context.allocator) -> (node: ^Node, array_type: ^Node_Array_Type) {
	node, array_type = new_node(f, Node_Array_Type, allocator)
	array_type.token = token
	array_type.count = count
	array_type.elem = elem
	return node, array_type
}

make_dynamic_array_type :: proc(f: ^File, token: Token, elem: ^Node, allocator := context.allocator) -> (node: ^Node, array_type: ^Node_Dynamic_Array_Type) {
	node, array_type = new_node(f, Node_Dynamic_Array_Type, allocator)
	array_type.token = token
	array_type.elem = elem
	return node, array_type
}

// Hmm some have slices some actually have dyn arrays. wtf?
make_struct_type :: proc(f: ^File, token: Token, fields: []^Node, field_count: int, polymorphic_params: ^Node, is_packed, is_raw_union, is_no_copy: bool, align: ^Node, where_token: Token, where_clauses: []^Node, allocator := context.allocator) -> (node: ^Node, struct_type: ^Node_Struct_Type) {
	node, struct_type = new_node(f, Node_Struct_Type, allocator)
	struct_type.token = token
	struct_type.fields = fields
	struct_type.field_count = field_count
	struct_type.polymorphic_params = polymorphic_params
	struct_type.is_packed = is_packed
	struct_type.is_raw_union = is_raw_union
	struct_type.is_no_copy = is_no_copy
	struct_type.align = align
	struct_type.where_token = where_token
	struct_type.where_clauses = where_clauses
	return node, struct_type
}

make_union_type :: proc(f: ^File, token: Token, variants: []^Node, polymorphic_params: ^Node, align: ^Node, kind: Union_Type_Kind, where_token: Token, where_clauses: []^Node, allocator := context.allocator) -> (node: ^Node, union_type: ^Node_Union_Type) {
	node, union_type = new_node(f, Node_Union_Type, allocator)
	union_type.token = token
	union_type.variants = variants
	union_type.polymorphic_params = polymorphic_params
	union_type.align = align
	union_type.kind = kind 
	union_type.where_token = where_token
	union_type.where_clauses = where_clauses
	return node, union_type
}

make_enum_type :: proc(f: ^File, token: Token, base_type: ^Node, fields: []^Node, allocator := context.allocator) -> (node: ^Node, enum_type: ^Node_Enum_Type) {
	node, enum_type = new_node(f, Node_Enum_Type, allocator)
	enum_type.token = token
	enum_type.base_type = base_type
	enum_type.fields = fields
	return node, enum_type
}

make_bit_set_type :: proc(f: ^File, token: Token, elem, underlying: ^Node, allocator := context.allocator) -> (node: ^Node, bs_type: ^Node_Bit_Set_Type) {
	node, bs_type = new_node(f, Node_Bit_Set_Type, allocator)
	bs_type.token = token
	bs_type.elem = elem
	bs_type.underlying = underlying
	return node, bs_type
}

make_map_type :: proc(f: ^File, token: Token, key, value: ^Node, allocator := context.allocator) -> (node: ^Node, map_type: ^Node_Map_Type) {
	node, map_type = new_node(f, Node_Map_Type, allocator)
	map_type.token = token
	map_type.key = key
	map_type.value = value
	return node, map_type
}

make_matrix_type :: proc(f: ^File, token: Token, row_count, column_count, elem: ^Node, allocator := context.allocator) -> (node: ^Node, matrix_type: ^Node_Matrix_Type) {
	node, matrix_type = new_node(f, Node_Matrix_Type, allocator)
	matrix_type.token = token
	matrix_type.row_count = row_count
	matrix_type.column_count = column_count
	matrix_type.elem = elem
	return node, matrix_type
}

make_foreign_block_decl :: proc(f: ^File, token: Token, foreign_lib: ^Node, body: ^Node, docs: ^Comment_Group, allocator := context.allocator) -> (node: ^Node, decl: ^Node_Foreign_Block_Decl) {
	node, decl = new_node(f, Node_Foreign_Block_Decl, allocator)
	decl.token = token
	decl.foreign_library = foreign_lib
	decl.body = body
	decl.docs = docs
	return node, decl
}

make_label_decl :: proc(f: ^File, token: Token, name: ^Node, allocator := context.allocator) -> (node: ^Node, decl: ^Node_Label) {
	node, decl = new_node(f, Node_Label, allocator)
	decl.token = token
	decl.name = name
	return node, decl
}

make_value_decl :: proc(f: ^File, names: []^Node, type: ^Node, values: []^Node, is_mutable: bool, docs, comment: ^Comment_Group, allocator := context.allocator) -> (node: ^Node, decl: ^Node_Value_Decl) {
	node, decl = new_node(f, Node_Value_Decl, allocator)
	decl.names = names
	decl.type = type
	decl.values = values
	decl.is_mutable = is_mutable
	decl.docs = docs
	decl.comment = comment
	// Note(Dragos): Bill sets the allocator of attributes, but do we needs to? 
	return node, decl
}

make_package_decl :: proc(f: ^File, token, name: Token, docs, comment: ^Comment_Group, allocator := context.allocator) -> (node: ^Node, decl: ^Node_Package_Decl) {
	node, decl = new_node(f, Node_Package_Decl, allocator)
	decl.token = token
	decl.name = name
	decl.docs = docs
	decl.comment = comment
	return node, decl
}

make_import_decl :: proc(f: ^File, token, relpath, import_name: Token, docs, comment: ^Comment_Group, allocator := context.allocator) -> (node: ^Node, decl: ^Node_Import_Decl) {
	node, decl = new_node(f, Node_Import_Decl, allocator)
	decl.token = token
	decl.relpath = relpath
	decl.import_name = import_name
	decl.docs = docs
	decl.comment = comment
	return node, decl
}

make_foreign_import_decl :: proc(f: ^File, token: Token, filepaths: []Token, library_name: Token, docs, comment: ^Comment_Group, allocator := context.allocator) -> (node: ^Node, decl: ^Node_Foreign_Import_Decl) {
	node, decl = new_node(f, Node_Foreign_Import_Decl, allocator)
	decl.token = token
	decl.filepaths = filepaths
	decl.library_name = library_name
	decl.docs = docs
	decl.comment = comment
	return node, decl
}

make_attribute :: proc(f: ^File, token, open, close: Token, elems: []^Node, allocator := context.allocator) -> (node: ^Node, attribute: ^Node_Attribute) {
	node, attribute = new_node(f, Node_Attribute, allocator)
	attribute.token = token
	attribute.open = open
	attribute.close = close
	attribute.elems = elems
	return node, attribute
}