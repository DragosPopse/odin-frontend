package frontend_ast

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
	SoaVariable   = 12,   // Struct-Of-Arrays indexed variable

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

 AstFile :: struct {
	id: i32,
	flags: u32,
	pkg: ^AstPackage,
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
	decls: []^Ast,
	imports: [dynamic]^Ast, // 'import'
	directive_count: int,

	curr_proc: ^Ast,
	error_count: int,
	last_error: Parse_File_Error,
	time_to_tokenize: f64, // seconds
	time_to_parse: f64,   // seconds

	lead_comment: ^Comment_Group,  // Comment (block) before the decl
	line_comment: ^Comment_Group,  // Comment after the semicolon
	docs: ^Comment_Group,           // current docs
	comments: [dynamic]^Comment_Group , // All the comments!

	// This is effectively a queue but does not require any multi-threading capabilities
	delayed_decls_queues: [Ast_Delay_Queue_Kind]^Ast,
 
	fix_count: int,
	fix_prev_pos: Token_Pos,

	//struct LLVMOpaqueMetadata *llvm_metadata
	//struct LLVMOpaqueMetadata *llvm_metadata_scope;
}

PARSER_MAX_FIX_COUNT :: 6

 Ast_Foreign_File_Kind :: enum {
	Invalid,

	S, // Source,
}

 Ast_Foreign_File :: struct {
	 kind: Ast_Foreign_File_Kind,
	 source: string,
}


 Ast_Package_Exported_Entity :: struct {
	identifier: ^Ast,
	entity: ^Entity,
}

AstPackage:: struct  {
	 kind: Package_Kind,
	 id: int,
	 name: string,
	 fullpath: string,
	 files: [dynamic]^Ast_File,
	 foreign_files: [dynamic]Ast_Foreign_File,
	 is_single_file: bool,
	 order: int,
	 files_mutex: sync.Mutex,
	 foreign_files_mutex: sync.Mutex,
	 type_and_value_mutex: sync.Mutex,
	 name_mutex: sync.Mutex,
	// NOTE(bill): This must be a MPMCQueue
	 exported_entity_queue_mpmc: queue.Queue(Ast_Package_Exported_Entity),

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
	foreign_kind: Ast_Foreign_File_Kind,
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


	MAX,


	Foreign_Block_Default = -1, // Todo(Dragos): Make this part of the enum properly so i can enumare the next array
};

proc_calling_convention_strings := [ProcCC_MAX]string {
	"",
	"odin",
	"contextless",
	"cdecl",
	"stdcall",
	"fastcall",
	"none",
	"naked",
	"inlineasm",
	"win64",
	"sysv",
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
};

 StmtAllowFlag :: enum {
	StmtAllowFlag_None    = 0,
	StmtAllowFlag_In      = 1<<0,
	StmtAllowFlag_Label   = 1<<1,
};

 InlineAsmDialectKind :: enum u8 {
	InlineAsmDialect_Default, // ATT is default
	InlineAsmDialect_ATT,
	InlineAsmDialect_Intel,

	InlineAsmDialect_COUNT,
};

inline_asm_dialect_strings: [InlineAsmDialect_COUNT]string = {
	"",
	"att",
	"intel",
};

 UnionTypeKind :: enum u8 {
	UnionType_Normal     = 0,
	UnionType_no_nil     = 2,
	UnionType_shared_nil = 3,

	UnionType_COUNT,
};

union_type_kind_strings := [UnionType_COUNT]string {
	"(normal)",
	"#maybe",
	"#no_nil",
	"#shared_nil",
};

Ast_Ident :: struct { // "identifier"
	token: Token,
	entity: ^Entity,
}

Ast_Implicit :: Token // "implicit"
Ast_Uninit :: Token // "uninitialized value"

Ast_BasicLit :: struct {
	token: Token,
}

Ast_BasicDirective :: struct { // "basic directive"
	token: Token,
	name: Token,
}

Ast_Ellipsis :: struct { // "ellipsis"
	token: Token,
	expr: ^Ast,
}

Ast_ProcGroup :: struct { // "procedure group"
	token: Token,
	open: Token,
	close: Token,
	args: []^Ast,
}

Ast_ProcLit :: struct { // "procedural literal"
	type: ^Ast,
	body: ^Ast,
	tags: u64,
	inlining: ProcInlining,
	where_token: Token,
	where_clauses: []^Ast,
	decl: ^DeclInfo,
}

Ast_CompoundLit :: struct { // "compound literal"
	type: ^Ast,
	elems: []^Ast,
	open, close: Token,
	max_count: i64 ,
	tag: ^Ast,
}

Ast__ExprBegin :: bool // ""

Ast_BadExpr :: struct { // "bad expression"
	begin, end: Token,
}

Ast_TagExpr :: struct { // "tag expression"
	token, name: Token,
	expr: ^Ast,
}

Ast_UnaryExpr :: struct { // "unary expression"
	op: Token,
	expr: ^Ast,
}

Ast_BinaryExpr :: struct { // "binary expression"
	op: Token,
	left, right: ^Ast,
}

Ast_ParenExpr :: struct { // "parentheses expression"
	expr: ^Ast,
	open, close: Token,
}

Ast_SelectorExpr :: struct { // "selector expression"
	token: Token,
	expr, selector: ^Ast,
	swizzle_count: u8, // maximum of 4 components, if set, count >= 2
	swizzle_indices: u8, // 2 bits per component
}

Ast_ImplicitSelectorExpr :: struct {
	token: Token,
	selector: ^Ast,
}

Ast_SelectorCallExpr :: struct {
    token: Token,
    expr, call: ^Ast,
    modified_call: bool,
}

Ast_IndexExpr :: struct { // "index expression"
	expr, index: ^Ast,
	open, close: Token,
}

Ast_DerefExpr :: struct { // "dereference expression"
	expr: ^Ast,
	op: Token,
}

Ast_SliceExpr :: struct { // "slice expression"
	expr: ^Ast,
	open, close: Token,
	interval: Token,
	low, high: ^Ast,
}

Ast_CallExpr :: struct { // "call expression"
	procedure: ^Ast,
	args: []^Ast,
	open: Token,
	close: Token,
	ellipsis: Token,
	inlining: ProcInlining,
	optional_ok_one: bool,
	was_selector: bool,
}

Ast_FieldValue :: struct { // "field value"
	eq: Token,
	field, value: ^Ast,
}

Ast_EnumFieldValue :: struct { // "enum field value"
	name: ^Ast,
	value: ^Ast,
	docs: ^CommentGroup,
	comment: ^CommentGroup,
}

Ast_TernaryIfExpr :: struct { // "ternary if expression"
	x, cond, y: ^Ast,
}

Ast_TernaryWhenExpr :: struct { // "ternary when expression"
	x, cond, y: ^Ast,
}

Ast_OrElseExpr :: struct { // "or_else expression"
	x: ^Ast,
	token: Token,
	y: ^Ast,
}

Ast_OrReturnExpr :: struct { // "or_return expression"
	expr: ^Ast,
	token: Token,
}

Ast_TypeAssertion :: struct { // "type assertion"
	expr: ^Ast,
	dot: Token,
	type: ^Ast,
	type_hint: ^Type,
	ignores: [2]bool,
}

Ast_TypeCast :: struct { // "type cast"
	token: Token,
	type, expr: ^Ast,
}

Ast_AutoCast :: struct { // "auto_cast"
	token: Token,
	expr: ^Ast,
}

Ast_InlineAsmExpr :: struct { // "inline asm expression"
	token: Token,
	open, close: Token,
	param_types: []^Ast,
	return_type: ^Ast,
	asm_string: ^Ast,
	constraints_string: ^Ast,
	has_side_effects: bool,
	is_align_stack: bool,
	dialect: InlineAsmDialectKind,
}

Ast_MatrixIndexExpr :: struct { // "matrix index expression"
	expr, row_index, column_index: ^Ast,
	open, close: Token,
}

Ast__ExprEnd :: bool
Ast__StmtBegin :: bool

Ast_BadStmt :: struct { // "bad statement"
	begin, end: Token,
}

Ast_EmptyStmt :: struct { // "empty statement"
	token: Token,
}

Ast_ExprStmt :: struct { // "expression statement"
	expr: ^Ast,
}

Ast_AssignStmt :: struct { // "assign statement"
	op: Token,
	lhs, rhs: []^Ast,
}

Ast__ComplexStmtBegin :: bool

Ast_BlockStmt :: struct { // "block statement"
	scope: ^Scope,
	stmts: []^Ast,
	label: ^Ast,
	open, close: Token,
}

Ast_IfStmt :: struct { // "if statement"
	scope: ^Scope,
	token: Token,
	label: ^Ast,
	init: ^Ast,
	cond: ^Ast,
	body: ^Ast,
	else_stmt: ^Ast,
}

Ast_WhenStmt :: struct { // "when statement"
	token: Token,
	cond: ^Ast,
	body: ^Ast,
	else_stmt: ^Ast,
	is_cond_determined: bool,
	determined_cond: bool,
}

Ast_ReturnStmt :: struct { // "return statement"
	token: Token,
	results: []^Ast,
}

Ast_ForStmt :: struct { // "for statement"
	scope: ^Scope,
	token: Token,
	label: ^Ast,
	init: ^Ast,
	cond: ^Ast,
	post: ^Ast,
	body: ^Ast,
}

Ast_RangeStmt :: struct { // "range statement"
	scope: ^Scope,
	token: Token,
	label: ^Ast,
	vals: []^Ast,
	in_token: Token,
	expr: ^Ast,
	body: ^Ast,
	reverse: bool,
}

Ast_UnrollRangeStmt :: struct { // "#unroll range statement"
	scope: ^Scope,
	unroll_token: Token,
	for_token: Token,
	val0, val1: ^Ast,
	in_token: Token,
	expr: ^Ast,
	body: ^Ast,
}

Ast_CaseClause :: struct { // "case clause"
	scope: ^Scope,
	token: Token,
	list: []^Ast,
	stmts: []^Ast,
	implicit_entity: ^Entity,
}

Ast_SwitchStmt :: struct { // "switch statement"
	scope: ^Scope,
	token: Token,
	label: ^Ast,
	init: ^Ast,
	tag: ^Ast,
	body: ^Ast,
	partial: bool,
}

Ast_TypeSwitchStmt :: struct { // "type switch statement"
	scope: ^Scope,
	token: Token,
	label: ^Ast,
	tag: ^Ast,
	body: ^Ast,
	partial: bool,
}

Ast_DeferStmt :: struct { // "defer statement"
	token: Token,
	stmt: ^Ast,
}

Ast_BranchStmt :: struct {
	token: Token,
	label: ^Ast,
}

Ast_UsingStmt :: struct {
	token: Token,
	list: []^Ast,
}

Ast__ComplexStmtEnd :: bool
Ast__StmtEnd :: bool
Ast__DeclBegin :: bool

Ast_BadDecl :: struct {
	begin, end: Token,
}

Ast_ForeignBlockDecl :: struct {
	token: Token,
	foreign_library: ^Ast,
	body: ^Ast,
	attributes: [dynamic]^Ast,
	docs: ^CommentGroup,
}

Ast_Label :: struct {
	token: Token,
	name: ^Ast,
}

Ast_ValueDecl :: struct {
	names: []^Ast,
	type: ^Ast,
	values: []^Ast,
	attributes: [dynamic]^Ast,
	docs: ^CommentGroup,
	comment: ^CommentGroup,
	is_using, is_mutable: bool,
}

Ast_PackageDecl :: struct {
	token: Token,
	name: Token,
	docs: ^CommentGroup,
	comment: ^CommentGroup,
}

Ast_ImportDecl :: struct {
	pkg: ^AstPackage,
	token: Token,
	relpath: Token,
	fullpath: string,
	import_name: Token,
	docs: ^CommentGroup,
	comment: ^CommentGroup,
}

Ast_ForeignImportDecl :: struct {
	token: Token,
	filepaths: []Token,
	library_name: Token,
	collection_name: string,
	fullpaths: []string,
	attributes: [dynamic]^Ast,
	docs: ^CommentGroup,
	comment: ^CommentGroup,
}

Ast__DeclEnd :: bool

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
	flags: u32,
	docs: ^CommentGroup,
	comment: ^CommentGroup,
}

Ast_FieldList :: struct {
	token: Token,
	list: []^Ast,
}

Ast__TypeBegin :: bool

Ast_TypeidType :: struct {
	token: Token,
	specialization: ^Ast,
}

Ast_HelperType :: struct {
	token: Token,
	type: ^Ast,
}

Ast_DistinctType :: struct {
	token: Token,
	type: ^Ast,
}

Ast_PolyType :: struct {
	token: Token,
	type: ^Ast,
	specialization: ^Ast,
}

Ast_ProcType :: struct {
	scope: ^Scope,
	token: Token,
	params: ^Ast,
	results: ^Ast,
	tags: u64,
	calling_convention: ProcCallingConvention,
	generic, diverging: bool,
}

Ast_PointerType :: struct {
	token: Token,
	type, tag: ^Ast,
}

Ast_RelativeType :: struct {
	tag, type: ^Ast,
}

Ast_MultiPointerType :: struct {
	token: Token,
	type: ^Ast,
}

Ast_ArrayType :: struct {
	token: Token,
	count, elem, tag: ^Ast,
}

Ast_DynamicArrayType :: struct {
	token: Token,
	elem, tag: ^Ast,
}

Ast_StructType :: struct {
	scope: ^Scope,
	token: Token,
	fields: []^Ast,
	field_count: isize,
	polymorphic_params: ^Ast,
	align: ^Ast,
	where_token: Token,
	where_clauses: []^Ast,
	is_packed, is_raw_union, is_no_copy: bool,
}

Ast_UnionType :: struct {
	scope: ^Scope,
	token: Token,
	variants: []^Ast,
	polymorphic_params: ^Ast,
	align: ^Ast,
	kind: UnionTypeKind,
	where_token: Token,
	where_clauses: []^Ast,
}

Ast_EnumType :: struct {
	scope: ^Scope,
	token: Token,
	base_type: ^Ast,
	fields: ^Ast, // FieldValue
	is_using: bool,
}

Ast_BitSetType :: struct {
	token: Token,
	elem: ^Ast,
	underlying: ^Ast,
}

Ast_MapType :: struct {
	token: Token,
	count, key, value: ^Ast, // Note(Dragos): What is count????
}

Ast_MatrixType :: struct {
	token: Token,
	row_count, column_count, elem: ^Ast,
}

Ast__TypeEnd :: bool

AstKind :: enum u16 {
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

/*#define AST_KINDS \
	AST_KIND(Ident,          "identifier",      struct { \
		Token   token;  \
		Entity *entity; \
	}) \
	AST_KIND(Implicit,       "implicit",        Token) \
	AST_KIND(Uninit,         "uninitialized value", Token) \
	AST_KIND(BasicLit,       "basic literal",   struct { \
		Token token; \
	}) \
	AST_KIND(BasicDirective, "basic directive", struct { \
		Token token; \
		Token name; \
	}) \
	AST_KIND(Ellipsis,       "ellipsis", struct { \
		Token    token; \
		Ast *expr; \
	}) \
	AST_KIND(ProcGroup, "procedure group", struct { \
		Token        token; \
		Token        open;  \
		Token        close; \
		Slice<Ast *> args;  \
	}) \
	AST_KIND(ProcLit, "procedure literal", struct { \
		Ast *type; \
		Ast *body; \
		u64  tags; \
		ProcInlining inlining; \
		Token where_token; \
		Slice<Ast *> where_clauses; \
		DeclInfo *decl; \
	}) \
	AST_KIND(CompoundLit, "compound literal", struct { \
		Ast *type; \
		Slice<Ast *> elems; \
		Token open, close; \
		i64 max_count; \
		Ast *tag; \
	}) \
AST_KIND(_ExprBegin,  "",  bool) \
	AST_KIND(BadExpr,      "bad expression",         struct { Token begin, end; }) \
	AST_KIND(TagExpr,      "tag expression",         struct { Token token, name; Ast *expr; }) \
	AST_KIND(UnaryExpr,    "unary expression",       struct { Token op; Ast *expr; }) \
	AST_KIND(BinaryExpr,   "binary expression",      struct { Token op; Ast *left, *right; } ) \
	AST_KIND(ParenExpr,    "parentheses expression", struct { Ast *expr; Token open, close; }) \
	AST_KIND(SelectorExpr, "selector expression",    struct { \
		Token token; \
		Ast *expr, *selector; \
		u8 swizzle_count; /*maximum of 4 components, if set, count >= 2*/ \
		u8 swizzle_indices; /*2 bits per component*/ \
	}) \
	AST_KIND(ImplicitSelectorExpr, "implicit selector expression",    struct { Token token; Ast *selector; }) \
	AST_KIND(SelectorCallExpr, "selector call expression", struct { \
		Token token; \
		Ast *expr, *call;  \
		bool modified_call; \
	}) \
	AST_KIND(IndexExpr,    "index expression",       struct { Ast *expr, *index; Token open, close; }) \
	AST_KIND(DerefExpr,    "dereference expression", struct { Ast *expr; Token op; }) \
	AST_KIND(SliceExpr,    "slice expression", struct { \
		Ast *expr; \
		Token open, close; \
		Token interval; \
		Ast *low, *high; \
	}) \
	AST_KIND(CallExpr,     "call expression", struct { \
		Ast *        proc; \
		Slice<Ast *> args; \
		Token        open; \
		Token        close; \
		Token        ellipsis; \
		ProcInlining inlining; \
		bool         optional_ok_one; \
		bool         was_selector; \
	}) \
	AST_KIND(FieldValue,      "field value",              struct { Token eq; Ast *field, *value; }) \
	AST_KIND(EnumFieldValue,  "enum field value",         struct { \
		Ast *name;          \
		Ast *value;         \
		CommentGroup *docs; \
		CommentGroup *comment; \
	}) \
	AST_KIND(TernaryIfExpr,   "ternary if expression",    struct { Ast *x, *cond, *y; }) \
	AST_KIND(TernaryWhenExpr, "ternary when expression",  struct { Ast *x, *cond, *y; }) \
	AST_KIND(OrElseExpr,      "or_else expression",       struct { Ast *x; Token token; Ast *y; }) \
	AST_KIND(OrReturnExpr,    "or_return expression",     struct { Ast *expr; Token token; }) \
	AST_KIND(TypeAssertion, "type assertion", struct { \
		Ast *expr; \
		Token dot; \
		Ast *type; \
		Type *type_hint; \
		bool ignores[2]; \
	}) \
	AST_KIND(TypeCast,      "type cast",           struct { Token token; Ast *type, *expr; }) \
	AST_KIND(AutoCast,      "auto_cast",           struct { Token token; Ast *expr; }) \
	AST_KIND(InlineAsmExpr, "inline asm expression", struct { \
		Token token; \
		Token open, close; \
		Slice<Ast *> param_types; \
		Ast *return_type; \
		Ast *asm_string; \
		Ast *constraints_string; \
		bool has_side_effects; \
		bool is_align_stack; \
		InlineAsmDialectKind dialect; \
	}) \
	AST_KIND(MatrixIndexExpr, "matrix index expression",       struct { Ast *expr, *row_index, *column_index; Token open, close; }) \
AST_KIND(_ExprEnd,       "", bool) \
AST_KIND(_StmtBegin,     "", bool) \
	AST_KIND(BadStmt,    "bad statement",                 struct { Token begin, end; }) \
	AST_KIND(EmptyStmt,  "empty statement",               struct { Token token; }) \
	AST_KIND(ExprStmt,   "expression statement",          struct { Ast *expr; } ) \
	AST_KIND(AssignStmt, "assign statement", struct { \
		Token op; \
		Slice<Ast *> lhs, rhs; \
	}) \
AST_KIND(_ComplexStmtBegin, "", bool) \
	AST_KIND(BlockStmt, "block statement", struct { \
		Scope *scope; \
		Slice<Ast *> stmts; \
		Ast *label;         \
		Token open, close; \
	}) \
	AST_KIND(IfStmt, "if statement", struct { \
		Scope *scope; \
		Token token;     \
		Ast *label;      \
		Ast * init;      \
		Ast * cond;      \
		Ast * body;      \
		Ast * else_stmt; \
	}) \
	AST_KIND(WhenStmt, "when statement", struct { \
		Token token; \
		Ast *cond; \
		Ast *body; \
		Ast *else_stmt; \
		bool is_cond_determined; \
		bool determined_cond; \
	}) \
	AST_KIND(ReturnStmt, "return statement", struct { \
		Token token; \
		Slice<Ast *> results; \
	}) \
	AST_KIND(ForStmt, "for statement", struct { \
		Scope *scope; \
		Token token; \
		Ast *label; \
		Ast *init; \
		Ast *cond; \
		Ast *post; \
		Ast *body; \
	}) \
	AST_KIND(RangeStmt, "range statement", struct { \
		Scope *scope; \
		Token token; \
		Ast *label; \
		Slice<Ast *> vals; \
		Token in_token; \
		Ast *expr; \
		Ast *body; \
		bool reverse; \
	}) \
	AST_KIND(UnrollRangeStmt, "#unroll range statement", struct { \
		Scope *scope; \
		Token unroll_token; \
		Token for_token; \
		Ast *val0; \
		Ast *val1; \
		Token in_token; \
		Ast *expr; \
		Ast *body; \
	}) \
	AST_KIND(CaseClause, "case clause", struct { \
		Scope *scope; \
		Token token;             \
		Slice<Ast *> list;   \
		Slice<Ast *> stmts;  \
		Entity *implicit_entity; \
	}) \
	AST_KIND(SwitchStmt, "switch statement", struct { \
		Scope *scope; \
		Token token;  \
		Ast *label;   \
		Ast *init;    \
		Ast *tag;     \
		Ast *body;    \
		bool partial; \
	}) \
	AST_KIND(TypeSwitchStmt, "type switch statement", struct { \
		Scope *scope; \
		Token token; \
		Ast *label;  \
		Ast *tag;    \
		Ast *body;   \
		bool partial; \
	}) \
	AST_KIND(DeferStmt,  "defer statement",  struct { Token token; Ast *stmt; }) \
	AST_KIND(BranchStmt, "branch statement", struct { Token token; Ast *label; }) \
	AST_KIND(UsingStmt,  "using statement",  struct { \
		Token token; \
		Slice<Ast *> list; \
	}) \
AST_KIND(_ComplexStmtEnd, "", bool) \
AST_KIND(_StmtEnd,        "", bool) \
AST_KIND(_DeclBegin,      "", bool) \
	AST_KIND(BadDecl,     "bad declaration",     struct { Token begin, end; }) \
	AST_KIND(ForeignBlockDecl, "foreign block declaration", struct { \
		Token token;             \
		Ast *foreign_library;    \
		Ast *body;               \
		Array<Ast *> attributes; \
		CommentGroup *docs;      \
	}) \
	AST_KIND(Label, "label", struct { 	\
		Token token; \
		Ast *name; \
	}) \
	AST_KIND(ValueDecl, "value declaration", struct { \
		Slice<Ast *> names;       \
		Ast *        type;        \
		Slice<Ast *> values;      \
		Array<Ast *> attributes;  \
		CommentGroup *docs;       \
		CommentGroup *comment;    \
		bool          is_using;   \
		bool          is_mutable; \
	}) \
	AST_KIND(PackageDecl, "package declaration", struct { \
		Token token;           \
		Token name;            \
		CommentGroup *docs;    \
		CommentGroup *comment; \
	}) \
	AST_KIND(ImportDecl, "import declaration", struct { \
		AstPackage *package;    \
		Token    token;         \
		Token    relpath;       \
		String   fullpath;      \
		Token    import_name;   \
		CommentGroup *docs;     \
		CommentGroup *comment;  \
	}) \
	AST_KIND(ForeignImportDecl, "foreign import declaration", struct { \
		Token    token;           \
		Slice<Token> filepaths;   \
		Token    library_name;    \
		String   collection_name; \
		Slice<String> fullpaths;  \
		Array<Ast *> attributes;  \
		CommentGroup *docs;       \
		CommentGroup *comment;    \
	}) \
AST_KIND(_DeclEnd,   "", bool) \
	AST_KIND(Attribute, "attribute", struct { \
		Token token;        \
		Slice<Ast *> elems; \
		Token open, close;  \
	}) \
	AST_KIND(Field, "field", struct { \
		Slice<Ast *> names;         \
		Ast *        type;          \
		Ast *        default_value; \
		Token        tag;           \
		u32              flags;     \
		CommentGroup *   docs;      \
		CommentGroup *   comment;   \
	}) \
	AST_KIND(FieldList, "field list", struct { \
		Token token;       \
		Slice<Ast *> list; \
	}) \
AST_KIND(_TypeBegin, "", bool) \
	AST_KIND(TypeidType, "typeid", struct { \
		Token token; \
		Ast *specialization; \
	}) \
	AST_KIND(HelperType, "helper type", struct { \
		Token token; \
		Ast *type; \
	}) \
	AST_KIND(DistinctType, "distinct type", struct { \
		Token token; \
		Ast *type; \
	}) \
	AST_KIND(PolyType, "polymorphic type", struct { \
		Token token; \
		Ast * type;  \
		Ast * specialization;  \
	}) \
	AST_KIND(ProcType, "procedure type", struct { \
		Scope *scope; \
		Token token;   \
		Ast *params;  \
		Ast *results; \
		u64 tags;    \
		ProcCallingConvention calling_convention; \
		bool generic; \
		bool diverging; \
	}) \
	AST_KIND(PointerType, "pointer type", struct { \
		Token token; \
		Ast *type;   \
		Ast *tag;    \
	}) \
	AST_KIND(RelativeType, "relative type", struct { \
		Ast *tag; \
		Ast *type; \
	}) \
	AST_KIND(MultiPointerType, "multi pointer type", struct { \
		Token token; \
		Ast *type; \
	}) \
	AST_KIND(ArrayType, "array type", struct { \
		Token token; \
		Ast *count; \
		Ast *elem; \
		Ast *tag;  \
	}) \
	AST_KIND(DynamicArrayType, "dynamic array type", struct { \
		Token token; \
		Ast *elem; \
		Ast *tag;  \
	}) \
	AST_KIND(StructType, "struct type", struct { \
		Scope *scope; \
		Token token;                \
		Slice<Ast *> fields;        \
		isize field_count;          \
		Ast *polymorphic_params;    \
		Ast *align;                 \
		Token where_token;          \
		Slice<Ast *> where_clauses; \
		bool is_packed;             \
		bool is_raw_union;          \
		bool is_no_copy;            \
	}) \
	AST_KIND(UnionType, "union type", struct { \
		Scope *scope; \
		Token        token;         \
		Slice<Ast *> variants;      \
		Ast *polymorphic_params;    \
		Ast *        align;         \
		UnionTypeKind kind;       \
		Token where_token;          \
		Slice<Ast *> where_clauses; \
	}) \
	AST_KIND(EnumType, "enum type", struct { \
		Scope *scope; \
		Token        token; \
		Ast *        base_type; \
		Slice<Ast *> fields; /* FieldValue */ \
		bool         is_using; \
	}) \
	AST_KIND(BitSetType, "bit set type", struct { \
		Token token; \
		Ast * elem;  \
		Ast * underlying; \
	}) \
	AST_KIND(MapType, "map type", struct { \
		Token token; \
		Ast *count; \
		Ast *key; \
		Ast *value; \
	}) \
	AST_KIND(MatrixType, "matrix type", struct { \
		Token token;       \
		Ast *row_count;    \
		Ast *column_count; \
		Ast *elem;         \
	}) \
AST_KIND(_TypeEnd,  "", bool)
*/

ast_strings := [AstKind.COUNT]string {
	// TODO
}

// Note(Dragos) size_of(Ast_Whatever)
ast_variant_sizes := [AstKind.COUNT]isize {
	// TODO
}

AstCommonStuff :: struct  {
	kind: AstKind      ,					// u16
	state_flags: u8           ,
	viral_state_flags: u8           ,
	file_id: i32          ,
	 tav: TypeAndValue,			// NOTE(bill): Making this a pointer is slower
};

Ast :: struct  {
	      kind: AstKind, // u16
	           state_flags: u8,
	           viral_state_flags: u8,
	          file_id: i32,
	 tav: TypeAndValue, // NOTE(bill): Making this a pointer is slower

	// IMPORTANT NOTE(bill): This must be at the end since the AST is allocated to be size of the variant
	using _: struct #raw_union {
		Ident: Ast_Ident,
		Implicit: Ast_Implicit,
		Uninit: Ast_Uninit,
		BasicLit: Ast_BasicLit,
		BasicDirective: Ast_BasicDirective,
		Ellipsis: Ast_Ellipsis,
		ProcGroup: Ast_ProcGroup,
		ProcLit: Ast_ProcLit,
		CompoundLit: Ast_CompoundLit,
		_ExprBegin: Ast__ExprBegin,
			BadExpr: 	Ast_BadExpr,
			TagExpr: 	Ast_TagExpr,
			UnaryExpr: 	Ast_UnaryExpr,
			BinaryExpr: 	Ast_BinaryExpr,
			ParenExpr: 	Ast_ParenExpr,
			SelectorExpr: 	Ast_SelectorExpr,
			ImplicitSelectorExpr: 	Ast_ImplicitSelectorExpr,
			SelectorCallExpr: 	Ast_SelectorCallExpr,
			IndexExpr: 	Ast_IndexExpr,
			DerefExpr: 	Ast_DerefExpr,
			SliceExpr: 	Ast_SliceExpr,
			CallExpr: 	Ast_CallExpr,
			FieldValue: 	Ast_FieldValue,
			EnumFieldValue: 	Ast_EnumFieldValue,
			TernaryIfExpr: 	Ast_TernaryIfExpr,
			TernaryWhenExpr: 	Ast_TernaryWhenExpr,
			OrElseExpr: 	Ast_OrElseExpr,
			OrReturnExpr: 	Ast_OrReturnExpr,
			TypeAssertion: 	Ast_TypeAssertion,
			TypeCast: 	Ast_TypeCast,
			AutoCast: 	Ast_AutoCast,
			InlineAsmExpr: 	Ast_InlineAsmExpr,
			MatrixIndexExpr: 	Ast_MatrixIndexExpr,
		_ExprEnd: Ast__ExprEnd,
		_StmtBegin: Ast__StmtBegin,
			BadStmt: 	Ast_BadStmt,
			EmptyStmt: 	Ast_EmptyStmt,
			ExprStmt: 	Ast_ExprStmt,
			AssignStmt: 	Ast_AssignStmt,
			_ComplexStmtBegin: 	Ast__ComplexStmtBegin,
				BlockStmt: 		Ast_BlockStmt,
				IfStmt: 		Ast_IfStmt,
				WhenStmt: 		Ast_WhenStmt,
				ReturnStmt: 		Ast_ReturnStmt,
				ForStmt: 		Ast_ForStmt,
				RangeStmt: 		Ast_RangeStmt,
				UnrollRangeStmt: 		Ast_UnrollRangeStmt,
				CaseClause: 		Ast_CaseClause,
				SwitchStmt: 		Ast_SwitchStmt,
				TypeSwitchStmt: 		Ast_TypeSwitchStmt,
				DeferStmt: 		Ast_DeferStmt,
				BranchStmt: 		Ast_BranchStmt,
				UsingStmt: 		Ast_UsingStmt,
			_ComplexStmtEnd: 	Ast__ComplexStmtEnd,
		_StmtEnd: Ast__StmtEnd,
		_DeclBegin: Ast__DeclBegin,
			BadDecl: 	Ast_BadDecl,
			ForeignBlockDecl: 	Ast_ForeignBlockDecl,
			Label: 	Ast_Label,
			ValueDecl: 	Ast_ValueDecl,
			PackageDecl: 	Ast_PackageDecl,
			ImportDecl: 	Ast_ImportDecl,
			ForeignImportDecl: 	Ast_ForeignImportDecl,
		_DeclEnd: Ast__DeclEnd,
		Field: Ast_Field,
		FieldList: Ast_FieldList,
		_TypeBegin: Ast__TypeBegin,
			HelperType: 	Ast_HelperType,
			DistinctType: 	Ast_DistinctType,
			PolyType: 	Ast_PolyType,
			ProcType: 	Ast_ProcType,
			PointerType: 	Ast_PointerType,
			RelativeType: 	Ast_RelativeType,
			MultiPointerType: 	Ast_MultiPointerType,
			ArrayType: 	Ast_ArrayType,
			DynamicArrayType: 	Ast_DynamicArrayType,
			StructType: 	Ast_StructType,
			UnionType: 	Ast_UnionType,
			EnumType: 	Ast_EnumType,
			BitSetType: 	Ast_BitSetType,
			MapType: 	Ast_MapType,
			MatrixType: 	Ast_MatrixType,
		_TypeEnd: Ast__TypeEnd,
	},
}

/*
	// NOTE(bill): I know I dislike methods but this is hopefully a temporary thing 
	// for refactoring purposes
	gb_inline AstFile *file() const {
		// NOTE(bill): This doesn't need to call get_ast_file_from_id which 
		return global_files[this->file_id];
	}
	gb_inline AstFile *thread_safe_file() const {
		return thread_safe_get_ast_file_from_id(this->file_id);
	}*/

/*
#define ast_node(n_, Kind_, node_) GB_JOIN2(Ast, Kind_) *n_ = &(node_)->Kind_; gb_unused(n_); GB_ASSERT_MSG((node_)->kind == GB_JOIN2(Ast_, Kind_), \
	"expected '%.*s' got '%.*s'", \
	LIT(ast_strings[GB_JOIN2(Ast_, Kind_)]), LIT(ast_strings[(node_)->kind]))
#define case_ast_node(n_, Kind_, node_) case GB_JOIN2(Ast_, Kind_): { ast_node(n_, Kind_, node_);
#ifndef case_end
#define case_end } break;
#endif
*/

is_ast_expr :: #force_inline proc(node: ^Ast) -> bool {
	return node.kind > ._ExprBegin && node.kind < ._ExprEnd
}
is_ast_stmt :: #force_inline proc(node: ^Ast) -> bool {
	return node.kind > ._StmtBegin && node.kind < ._stmtEnd
}

is_ast_complex_stmt :: #force_inline proc(node: ^Ast) -> bool {
	return node.kind > ._ComplexStmtBegin && node.kind < .ComplexStmtEnd
}

is_ast_decl :: #force_inline proc(node: ^Ast) -> bool {
	return node.kind > ._DeclBegin && node.kind < ._DeclEnd
}

is_ast_type :: #force_inline proc(node: ^Ast) -> bool {
	return node.kind > ._TypeBegin && node.kind < ._TypeEnd
}

is_ast_when_stmt :: #force_inline proc(node: ^Ast) -> bool {
	return node.kind == .WhenStmt
}

@thread_local 
global_thread_local_ast_arena: mem.Arena


ast_allocator :: #force_inline proc(f: ^AstFile) -> mem.Allocator {
	return arena_allocator(&global_thread_local_ast_arena);
}

