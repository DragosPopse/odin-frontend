package frontend

import "core:container/queue"
import "core:sync"
import "core:mem"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"
import "core:intrinsics"

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





Node :: struct  {
	pos: Token_Pos,
	end: Token_Pos,
	
	state_flags: State_Flags,
	viral_state_flags: Viral_State_Flags,
	file_id: i32, // Note(Dragos): The file is already in the token. Do we need?
	tav: Type_And_Value, // NOTE(bill): Making this a pointer is slower
	derived: Any_Node,
}

Expr :: struct {
	using expr_base: Node,
	derived_expr: Any_Expr,
}

Stmt :: struct {
	using stmt_base: Node,
	derived_stmt: Any_Stmt,
}

Decl :: struct {
	using decl_base: Stmt,
}

Bad_Expr :: struct {
	using node: Expr,
}

Ident :: struct {
	using node: Expr,
	name: string,
	entity: ^Entity,
}

Implicit :: struct {
	using node: Expr,
}

Undef :: struct {
	using node: Expr,
	tok: Token_Kind,
}

Basic_Lit :: struct {
	using node: Expr,
	tok: Token,
}

Basic_Directive :: struct {
	using node: Expr,
	tok: Token,
	name: string,
}

Ellipsis :: struct {
	using node: Expr,
	tok: Token_Kind,
	expr: ^Expr,
}

Proc_Lit :: struct {
	using node: Expr,
	type: ^Proc_Type,
	body: ^Stmt,
	tags: Proc_Tags,
	inlining: Proc_Inlining,
	where_token: Token,
	where_clauses: []^Expr,
}

Comp_Lit :: struct {
	using node: Expr,
	type: ^Expr,
	open: Token,
	elems: []^Expr,
	close: Token,
	tag: ^Expr,
}

Tag_Expr :: struct {
	using node: Expr,
	op: Token,
	name: string,
	expr: ^Expr,
}

Unary_Expr :: struct {
	using node: Expr,
	op:   Token,
	expr: ^Expr,
}

Binary_Expr :: struct {
	using node: Expr,
	left:  ^Expr,
	op:    Token,
	right: ^Expr,
}

Paren_Expr :: struct {
	using node: Expr,
	open:  Token,
	expr:  ^Expr,
	close: Token,
}

Selector_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	op:    Token,
	field: ^Ident,
	swizzle_count: u8, // maximum of 4 components, if set, count >= 2
	swizzle_indices: u8, // 2 bits per component
}

Implicit_Selector_Expr :: struct {
	using node: Expr,
	field: ^Ident,
}

Selector_Call_Expr :: struct {
	using node: Expr,
	expr: ^Expr,
	call: ^Call_Expr,
	modified_call: bool,
}

Index_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	open:  Token,
	index: ^Expr,
	close: Token,
}

Deref_Expr :: struct {
	using node: Expr,
	expr: ^Expr,
	op:   Token,
}

Slice_Expr :: struct {
	using node: Expr,
	expr:     ^Expr,
	open:     Token,
	low:      ^Expr,
	interval: Token,
	high:     ^Expr,
	close:    Token,
}

Matrix_Index_Expr :: struct {
	using node: Expr,
	expr:         ^Expr,
	open:         Token,
	row_index:    ^Expr,
	column_index: ^Expr,
	close:        Token,
}

Call_Expr :: struct {
	using node: Expr,
	inlining: Proc_Inlining,
	expr:     ^Expr,
	open:     Token,
	args:     []^Expr,
	ellipsis: Token,
	close:    Token,
}

Field_Value :: struct {
	using node: Expr,
	field: ^Expr,
	sep:   Token,
	value: ^Expr,
}

Ternary_If_Expr :: struct {
	using node: Expr,
	x:    ^Expr,
	op1:  Token,
	cond: ^Expr,
	op2:  Token,
	y:    ^Expr,
}

Ternary_When_Expr :: struct {
	using node: Expr,
	x:    ^Expr,
	op1:  Token,
	cond: ^Expr,
	op2:  Token,
	y:    ^Expr,
}

Or_Else_Expr :: struct {
	using node: Expr,
	x:     ^Expr,
	token: Token,
	y:     ^Expr,
}

Or_Return_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	token: Token,
}

Type_Assertion :: struct {
	using node: Expr,
	expr:  ^Expr,
	dot:   Token,
	open:  Token,
	type:  ^Expr,
	close: Token,
}

Type_Cast :: struct {
	using node: Expr,
	tok:   Token,
	open:  Token,
	type:  ^Expr,
	close: Token,
	expr:  ^Expr,
}

Auto_Cast :: struct {
	using node: Expr,
	op:   Token,
	expr: ^Expr,
}

Bad_Stmt :: struct {
	using node: Stmt,
}

Empty_Stmt :: struct {
	using node: Stmt,
	semicolon: Token, // Position of the following ';'
}

Expr_Stmt :: struct {
	using node: Stmt,
	expr: ^Expr,
}

Tag_Stmt :: struct {
	using node: Stmt,
	op:      Token,
	name:    string,
	stmt:    ^Stmt,
}

Assign_Stmt :: struct {
	using node: Stmt,
	lhs:    []^Expr,
	op:     Token,
	rhs:    []^Expr,
}


Block_Stmt :: struct {
	using node: Stmt,
	label: ^Expr,
	open:  Token,
	stmts: []^Stmt,
	close: Token,
	uses_do: bool,
}

If_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	if_pos:    Token,
	init:      ^Stmt,
	cond:      ^Expr,
	body:      ^Stmt,
	else_pos:  Token,
	else_stmt: ^Stmt,
}

When_Stmt :: struct {
	using node: Stmt,
	when_pos:  Token,
	cond:      ^Expr,
	body:      ^Stmt,
	else_stmt: ^Stmt,
}

Return_Stmt :: struct {
	using node: Stmt,
	results: []^Expr,
}

Defer_Stmt :: struct {
	using node: Stmt,
	stmt: ^Stmt,
}

For_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	for_pos:   Token,
	init:      ^Stmt,
	cond:      ^Expr,
	post:      ^Stmt,
	body:      ^Stmt,
}

Range_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	for_pos:   Token,
	vals:      []^Expr,
	in_pos:    Token,
	expr:      ^Expr,
	body:      ^Stmt,
	reverse:   bool,
}

Inline_Range_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	inline_pos: Token,
	for_pos:    Token,
	val0:       ^Expr,
	val1:       ^Expr,
	in_pos:     Token,
	expr:       ^Expr,
	body:       ^Stmt,
}




Case_Clause :: struct {
	using node: Stmt,
	case_pos:   Token,
	list:       []^Expr,
	terminator: Token,
	body:       []^Stmt,
}

Switch_Stmt :: struct {
	using node: Stmt,
	label:      ^Expr,
	switch_pos: Token,
	init:       ^Stmt,
	cond:       ^Expr,
	body:       ^Stmt,
	partial:    bool,
}

Type_Switch_Stmt :: struct {
	using node: Stmt,
	label:      ^Expr,
	switch_pos: Token,
	tag:        ^Stmt,
	expr:       ^Expr,
	body:       ^Stmt,
	partial:    bool,
}

Branch_Stmt :: struct {
	using node: Stmt,
	tok:   Token,
	label: ^Ident,
}

Using_Stmt :: struct {
	using node: Stmt,
	list: []^Expr,
}


// Declarations

Bad_Decl :: struct {
	using node: Decl,
}

Value_Decl :: struct {
	using node: Decl,
	docs:       ^Comment_Group,
	attributes: [dynamic]^Attribute, // dynamic as parsing will add to them lazily
	names:      []^Expr,
	type:       ^Expr,
	values:     []^Expr,
	comment:    ^Comment_Group,
	is_using:   bool,
	is_mutable: bool,
}

Package_Decl :: struct {
	using node: Decl,
	docs:    ^Comment_Group,
	token:   Token,
	name:    string,
	comment: ^Comment_Group,
}

Import_Decl :: struct {
	using node: Decl,
	docs:       ^Comment_Group,
	is_using:    bool,
	import_tok:  Token,
	name:        Token,
	relpath:     Token,
	fullpath:    string,
	comment:     ^Comment_Group,
}

Foreign_Block_Decl :: struct {
	using node: Decl,
	docs:            ^Comment_Group,
	attributes:      [dynamic]^Attribute, // dynamic as parsing will add to them lazily
	tok:             Token,
	foreign_library: ^Expr,
	body:            ^Stmt,
}

Foreign_Import_Decl :: struct {
	using node: Decl,
	docs:            ^Comment_Group,
	attributes:      [dynamic]^Attribute, // dynamic as parsing will add to them lazily
	foreign_tok:     Token,
	import_tok:      Token,
	name:            ^Ident,
	collection_name: string,
	fullpaths:       []string,
	comment:         ^Comment_Group,
}


Proc_Group :: struct {
	using node: Expr,
	tok:   Token,
	open:  Token,
	args:  []^Expr,
	close: Token,
}

Attribute :: struct {
	using node: Node,
	tok:   Token,
	open:  Token,
	elems: []^Expr,
	close: Token,
}

Field :: struct {
	using node: Node,
	docs:          ^Comment_Group,
	names:         []^Expr, // Could be polymorphic
	type:          ^Expr,
	default_value: ^Expr,
	tag:           Token,
	flags:         Field_Flags,
	comment:       ^Comment_Group,
}

Field_List :: struct {
	using node: Node,
	open:  Token,
	list:  []^Field,
	close: Token,
}


// Types
Typeid_Type :: struct {
	using node: Expr,
	tok:            Token,
	specialization: ^Expr,
}

Helper_Type :: struct {
	using node: Expr,
	tok:  Token,
	type: ^Expr,
}

Distinct_Type :: struct {
	using node: Expr,
	tok:  Token,
	type: ^Expr,
}

Poly_Type :: struct {
	using node: Expr,
	dollar:         Token,
	type:           ^Ident,
	specialization: ^Expr,
}

Proc_Type :: struct {
	using node: Expr,
	tok:       Token,
	calling_convention: Proc_Calling_Convention,
	params:    ^Field_List,
	arrow:     Token,
	results:   ^Field_List,
	tags:      Proc_Tags,
	generic:   bool,
	diverging: bool,
}

Pointer_Type :: struct {
	using node: Expr,
	tag:     ^Expr,
	pointer: Token,
	elem:    ^Expr,
}

Multi_Pointer_Type :: struct {
	using node: Expr,
	open:    Token,
	pointer: Token,
	close:   Token,
	elem:    ^Expr,
}

Array_Type :: struct {
	using node: Expr,
	open:  Token,
	tag:   ^Expr,
	len:   ^Expr, // Ellipsis node for [?]T arrray types, nil for slice types
	close: Token,
	elem:  ^Expr,
}

Dynamic_Array_Type :: struct {
	using node: Expr,
	tag:         ^Expr,
	open:        Token,
	dynamic_pos: Token,
	close:       Token,
	elem:        ^Expr,
}

Struct_Type :: struct {
	using node: Expr,
	tok_pos:       Token,
	poly_params:   ^Field_List,
	align:         ^Expr,
	where_token:   Token,
	where_clauses: []^Expr,
	is_packed:     bool,
	is_raw_union:  bool,
	is_no_copy:    bool,
	fields:        ^Field_List,
	name_count:    int,
}


Union_Type :: struct {
	using node: Expr,
	tok_pos:       Token_Pos,
	poly_params:   ^Field_List,
	align:         ^Expr,
	kind:          Union_Type_Kind,
	where_token:   Token,
	where_clauses: []^Expr,
	variants:      []^Expr,
}

Enum_Type :: struct {
	using node: Expr,
	tok_pos:  Token_Pos,
	base_type: ^Expr,
	open:      Token,
	fields:    []^Expr,
	close:     Token,

	is_using:  bool,
}

Bit_Set_Type :: struct {
	using node: Expr,
	tok_pos:    Token_Pos,
	open:       Token,
	elem:       ^Expr,
	underlying: ^Expr,
	close:      Token,
}

Map_Type :: struct {
	using node: Expr,
	tok_pos: Token_Pos,
	key:     ^Expr,
	value:   ^Expr,
}


Relative_Type :: struct {
	using node: Expr,
	tag:  ^Expr,
	type: ^Expr,
}

Matrix_Type :: struct {
	using node: Expr,
	tok_pos:      Token_Pos,
	row_count:    ^Expr,
	column_count: ^Expr,
	elem:         ^Expr,
}

Inline_Asm_Expr :: struct {
	using node: Expr,
	tok:                Token,
	param_types:        []^Expr,
	return_type:        ^Expr,
	has_side_effects:   bool,
	is_align_stack:     bool,
	dialect:            Inline_Asm_Dialect_Kind,
	open:               Token,
	constraints_string: ^Expr,
	asm_string:         ^Expr,
	close:              Token,
}

Any_Node :: union {
	^Package,
	^File,
	^Comment_Group,

	^Bad_Expr,
	^Ident,
	^Implicit,
	^Undef,
	^Basic_Lit,
	^Basic_Directive,
	^Ellipsis,
	^Proc_Lit,
	^Comp_Lit,
	^Tag_Expr,
	^Unary_Expr,
	^Binary_Expr,
	^Paren_Expr,
	^Selector_Expr,
	^Implicit_Selector_Expr,
	^Selector_Call_Expr,
	^Index_Expr,
	^Deref_Expr,
	^Slice_Expr,
	^Matrix_Index_Expr,
	^Call_Expr,
	^Field_Value,
	^Ternary_If_Expr,
	^Ternary_When_Expr,
	^Or_Else_Expr,
	^Or_Return_Expr,
	^Type_Assertion,
	^Type_Cast,
	^Auto_Cast,
	^Inline_Asm_Expr,

	^Proc_Group,

	^Typeid_Type,
	^Helper_Type,
	^Distinct_Type,
	^Poly_Type,
	^Proc_Type,
	^Pointer_Type,
	^Multi_Pointer_Type,
	^Array_Type,
	^Dynamic_Array_Type,
	^Struct_Type,
	^Union_Type,
	^Enum_Type,
	^Bit_Set_Type,
	^Map_Type,
	^Relative_Type,
	^Matrix_Type,

	^Bad_Stmt,
	^Empty_Stmt,
	^Expr_Stmt,
	^Tag_Stmt,
	^Assign_Stmt,
	^Block_Stmt,
	^If_Stmt,
	^When_Stmt,
	^Return_Stmt,
	^Defer_Stmt,
	^For_Stmt,
	^Range_Stmt,
	^Inline_Range_Stmt,
	^Case_Clause,
	^Switch_Stmt,
	^Type_Switch_Stmt,
	^Branch_Stmt,
	^Using_Stmt,

	^Bad_Decl,
	^Value_Decl,
	^Package_Decl,
	^Import_Decl,
	^Foreign_Block_Decl,
	^Foreign_Import_Decl,

	^Attribute,
	^Field,
	^Field_List,
}

Any_Expr :: union {
	^Bad_Expr,
	^Ident,
	^Implicit,
	^Undef,
	^Basic_Lit,
	^Basic_Directive,
	^Ellipsis,
	^Proc_Lit,
	^Comp_Lit,
	^Tag_Expr,
	^Unary_Expr,
	^Binary_Expr,
	^Paren_Expr,
	^Selector_Expr,
	^Implicit_Selector_Expr,
	^Selector_Call_Expr,
	^Index_Expr,
	^Deref_Expr,
	^Slice_Expr,
	^Matrix_Index_Expr,
	^Call_Expr,
	^Field_Value,
	^Ternary_If_Expr,
	^Ternary_When_Expr,
	^Or_Else_Expr,
	^Or_Return_Expr,
	^Type_Assertion,
	^Type_Cast,
	^Auto_Cast,
	^Inline_Asm_Expr,

	^Proc_Group,

	^Typeid_Type,
	^Helper_Type,
	^Distinct_Type,
	^Poly_Type,
	^Proc_Type,
	^Pointer_Type,
	^Multi_Pointer_Type,
	^Array_Type,
	^Dynamic_Array_Type,
	^Struct_Type,
	^Union_Type,
	^Enum_Type,
	^Bit_Set_Type,
	^Map_Type,
	^Relative_Type,
	^Matrix_Type,
}

Any_Stmt :: union {
	^Bad_Stmt,
	^Empty_Stmt,
	^Expr_Stmt,
	^Tag_Stmt,
	^Assign_Stmt,
	^Block_Stmt,
	^If_Stmt,
	^When_Stmt,
	^Return_Stmt,
	^Defer_Stmt,
	^For_Stmt,
	^Range_Stmt,
	^Inline_Range_Stmt,
	^Case_Clause,
	^Switch_Stmt,
	^Type_Switch_Stmt,
	^Branch_Stmt,
	^Using_Stmt,

	^Bad_Decl,
	^Value_Decl,
	^Package_Decl,
	^Import_Decl,
	^Foreign_Block_Decl,
	^Foreign_Import_Decl,
}

syntax_error_with_verbose_node :: proc(node: ^Node, msg: string, args: ..any) {
	unimplemented()
}

syntax_error_with_verbose :: proc {
	syntax_error_with_verbose_node,
}

// Todo(Dragos): Talk with bill about refactoring this eventually

new_node :: proc($T: typeid, f: ^File, pos, end: Token, allocator := context.allocator) -> ^T {
	t := new(T, allocator)
	t.pos = pos
	t.end = end
	t.derived = t
	t.file_id = f.id
	when intrinsics.type_has_field(T, "derived_stmt") {
		t.derived_stmt = t
	}
	when intrinsics.type_has_field(T, "derived_expr") {
		t.derived_expr = t
	}
	return t
}