package frontend

import "core:hash"
import "core:strings"
import "core:mem"
import "core:slice"
import "core:fmt"

Token_Kind :: enum {
    Invalid,
    EOF,
    Comment,

    Literal_Begin,
    Ident,
    Integer,
    Float,
    Imag,
    Rune,
    String,
    Literal_End,

    Operator_Begin,
    Eq,
    Not,
    Hash,
    At,
    Dollar,
    Pointer,
    Question,
    Add,
    Sub,
    Mul,
    Quo,   
    Mod,   
    ModMod,
    And,   
    Or,    
    Xor,   
    AndNot,
    Shl,   
    Shr,   
    CmpAnd,
    CmpOr,

    Assign_Op_Begin,
    AddEq,   
    SubEq,   
    MulEq,   
    QuoEq,   
    ModEq,   
    ModModEq,
    AndEq,   
    OrEq,    
    XorEq,   
    AndNotEq,
    ShlEq,   
    ShrEq,   
    CmpAndEq,
    CmpOrEq,
    Assign_Op_End,

    Increment, 
    Decrement, 
    ArrowRight,
    Uninit,
    
    Comparison_Begin,
    Cmp_Eq,
    Not_Eq,
    Lt,   
    Gt,   
    Lt_Eq, 
    Gt_Eq,
    Comparison_End,

    OpenParen,  
    CloseParen, 
    OpenBracket,
    CloseBracket,
    OpenBrace,  
    CloseBrace, 
    Colon,      
    Semicolon,  
    Period,     
    Comma,      
    Ellipsis,   
    Range_Full,  
    Range_Half,  
    Backslash,
    Operator_End,

    Keyword_Begin,
    Import,    
    Foreign,   
    Package,   
    Typeid,    
    When,      
    Where,     
    If,        
    Else,      
    For,       
    Switch,    
    In,        
    Not_in,    
    Do,        
    Case,      
    Break,     
    Continue,  
    Fallthrough,
    Defer,     
    Return,    
    Proc,      
    Struct,    
    Union,     
    Enum,      
    Bit_set,   
    Map,       
    Dynamic,   
    Auto_cast, 
    Cast,      
    Transmute, 
    Distinct,  
    Using,     
    Context,   
    Or_else,   
    Or_return, 
    Asm,       
    Matrix,
    Keyword_End,
}

token_strings := [Token_Kind]string{
    .Invalid            = "Invalid",
    .EOF                = "EOF",
    .Comment            = "Comment",

    .Literal_Begin      = "",
    .Ident              = "identifier",
    .Integer            = "integer",
    .Float              = "float",
    .Imag               = "imaginary",
    .Rune               = "rune",
    .String             = "string",
    .Literal_End        = "",

    .Operator_Begin     = "",
    .Eq                 = "=",
    .Not                = "!",
    .Hash               = "#",
    .At                 = "@",
    .Dollar             = "$",
    .Pointer            = "^",
    .Question           = "?",
    .Add                = "+",
    .Sub                = "-",
    .Mul                = "*",
    .Quo                = "/",   
    .Mod                = "%",   
    .ModMod             = "%%",
    .And                = "&",   
    .Or                 = "|",    
    .Xor                = "~",   
    .AndNot             = "&~",
    .Shl                = "<<",   
    .Shr                = ">>",   
    .CmpAnd             = "&&",
    .CmpOr              = "||",

    .Assign_Op_Begin    = "",
    .AddEq              = "+=",   
    .SubEq              = "-=",   
    .MulEq              = "*=",   
    .QuoEq              = "/=",   
    .ModEq              = "%=",   
    .ModModEq           = "%%=",
    .AndEq              = "&=",   
    .OrEq               = "|=",    
    .XorEq              = "~=",   
    .AndNotEq           = "&~=",
    .ShlEq              = "<<=",   
    .ShrEq              = ">>=",   
    .CmpAndEq           = "&&=",
    .CmpOrEq            = "||=",
    .Assign_Op_End      = "",

    .Increment          = "++", 
    .Decrement          = "--", 
    .ArrowRight         = "-?",
    .Uninit             = "---",
    
    .Comparison_Begin   = "",
    .Cmp_Eq             = "==",
    .Not_Eq             = "!=",
    .Lt                 = "<",   
    .Gt                 = ">",   
    .Lt_Eq              = "<=", 
    .Gt_Eq              = ">=",
    .Comparison_End     = "",

    .OpenParen          = "(",  
    .CloseParen         = ")", 
    .OpenBracket        = "[",
    .CloseBracket       = "]",
    .OpenBrace          = "{",  
    .CloseBrace         = "}", 
    .Colon              = ":",  
    .Semicolon          = ";",  
    .Period             = ".", 
    .Comma              = ",",  
    .Ellipsis           = "..",   
    .Range_Full          = "..=",  
    .Range_Half          = "..<",  
    .Backslash          = "\\",
    .Operator_End       = "",

    .Keyword_Begin      = "",
    .Import             = "import",    
    .Foreign            = "foreign",   
    .Package            = "package",   
    .Typeid             = "typeid",    
    .When               = "when",  
    .Where              = "where", 
    .If                 = "if",  
    .Else               = "else",  
    .For                = "for",  
    .Switch             = "switch",    
    .In                 = "in",  
    .Not_in             = "not_in",    
    .Do                 = "do",
    .Case               = "case",      
    .Break              = "break",     
    .Continue           = "continue",  
    .Fallthrough        = "fallthrough",
    .Defer              = "defer",     
    .Return             = "return",    
    .Proc               = "proc",      
    .Struct             = "struct",    
    .Union              = "union",  
    .Enum               = "enum",   
    .Bit_set            = "bit_set", 
    .Map                = "map",  
    .Dynamic            = "dynamic",  
    .Auto_cast          = "auto_cast", 
    .Cast               = "cast",      
    .Transmute          = "transmute", 
    .Distinct           = "distinct",  
    .Using              = "using",     
    .Context            = "context",   
    .Or_else            = "or_else",   
    .Or_return          = "or_return", 
    .Asm                = "asm",       
    .Matrix             = "matrix",
    .Keyword_End        = "",
}

Keyword_Hash_Entry :: struct {
    hash: u32,
    kind: Token_Kind,
    text: string,
}

KEYWORD_HASH_TABLE_COUNT :: 1 << 9
KEYWORD_HASH_TABLE_MASK :: KEYWORD_HASH_TABLE_COUNT - 1
keyword_hash_table: [KEYWORD_HASH_TABLE_COUNT]Keyword_Hash_Entry
MIN_KEYWORD_SIZE :: 2
MAX_KEYWORD_SIZE :: 11
keyword_indices: [16]bool

keyword_hash :: proc(text: string) -> u32 {
    return hash.fnv32a(transmute([]byte)text)
}

add_keyword_hash_entry :: proc(s: string, kind: Token_Kind) {
    unimplemented()
}

init_keyword_hash_table :: proc() {
    unimplemented()
}

global_file_path_strings: [dynamic]string // index is file id
global_files: [dynamic]^Ast_File

get_file_path_string :: proc(index: int) -> string {
    unimplemented()
}

Token_Pos :: struct {
    file_id: int,
    offset: int,
    line: int, // starting at 1
    column: int, // starting at 1
}

token_pos_cmp :: proc(a, b: Token_Pos) -> int {
    unimplemented()
}

token_pos_eq :: proc(a, b: Token_Pos) -> bool {
    return token_pos_cmp(a, b) == 0
}

token_pos_neq :: proc(a, b: Token_Pos) -> bool {
    return token_pos_cmp(a, b) != 0
}

token_pos_lt :: proc(a, b: Token_Pos) -> bool {
    return token_pos_cmp(a, b) < 0
}

token_pos_lteq :: proc(a, b: Token_Pos) -> bool {
    return token_pos_cmp(a, b) <= 0
}

token_pos_gt :: proc(a, b: Token_Pos) -> bool {
    return token_pos_cmp(a, b) > 0
}

token_pos_gteq :: proc(a, b: Token_Pos) -> bool {
    return token_pos_cmp(a, b) >= 0
}

token_pos_add_column :: proc(pos: Token_Pos) -> Token_Pos {
    pos := pos
    pos.column += 1
    pos.offset += 1
    return pos
}

Token_Flag :: enum {
    Remove,
    Replace,
}

Token_Flags :: bit_set[Token_Flag]

Token :: struct {
    kind: Token_Kind,
    flags: Token_Flags,
    text: string,
    pos: Token_Pos,
}

empty_token := Token{
    kind = .Invalid,
}

blank_token := Token{
    kind = .Ident,
    text = "_",
}

make_token_ident :: proc(text: string) -> (token: Token) {
    token.kind = .Ident
    token.text = text
    return token
}

token_is_newline :: proc(tok: Token) -> bool {
    return tok.kind == .Semicolon && tok.text == "\n"
}

token_is_literal :: proc(t: Token_Kind) -> bool {
    return t > .Literal_Begin && t < .Literal_End
}

token_is_operator :: proc(t: Token_Kind) -> bool {
    return t > .Operator_Begin && t < .Operator_End
}

token_is_keyword :: proc(t: Token_Kind) -> bool {
    return t > .Keyword_Begin && t < .Keyword_End
}

token_is_comparison :: proc(t: Token_Kind) -> bool {
    return t > .Comparison_Begin && t < .Comparison_End
}

token_is_shift :: proc(t: Token_Kind) -> bool {
    return t == .Shl || t == .Shr
}

print_token :: proc(t: Token) {
    fmt.printf("%v\n", t.text)
}

Tokenizer_Init_Error :: enum {
    None,

    Invalid,
    NotExists,
    Permission,
    Empty,
    FileTooLarge,
}

Tokenizer :: struct {
    curr_file_id: int,
    fullpath: string,
    src: string,

    // State
    ch: rune, // current char
    ch_offset: int, // char pos
    read_offset: int, // pos from start
    column_minus_one: int,
    line_count: int,

    error_count: int,

    insert_semicolon: bool,

    loaded_file: Loaded_File,
}

tokenizer_err_msg :: proc(t: ^Tokenizer, msg: string) {
    unimplemented()
}

tokenizer_err_pos_msg :: proc(t: ^Tokenizer, pos: Token_Pos, msg: string) {
    unimplemented()
}

tokenizer_err :: proc { 
    tokenizer_err_msg,
    tokenizer_err_pos_msg,
}

advance_to_next_rune :: proc(t: ^Tokenizer) {
    unimplemented()
}

digit_value :: proc(r: rune) -> int {
    switch r {
        case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9': {
            return int(r - '0')
        }

        case 'a', 'b', 'c', 'd', 'e', 'f': {
            return int(r - 'a' + 10)
        }
        case 'A', 'B', 'C', 'D', 'E', 'F': {
            return int(r - 'A' + 10)
        }
    }
    return 16 // larger than highest possible
}

scan_mantissa :: proc(t: ^Tokenizer, base: int) {
    unimplemented()
}

peek_byte :: proc(t: ^Tokenizer, offset := 0) {
    unimplemented()
}

scan_number_to_token :: proc(t: ^Tokenizer, token: ^Token, seen_decimal_point: bool) {
    unimplemented()
}

scan_escape :: proc(t: ^Tokenizer) -> bool {
    unimplemented()
}

tokenizer_skip_line :: proc(t: ^Tokenizer) {
    unimplemented()
}

tokenizer_skip_whitespace :: proc(t: ^Tokenizer, on_newline: bool) {
    unimplemented()
}

tokenizer_get_token :: proc(t: ^Tokenizer, token: ^Token, repeat := 0) {
    unimplemented()
}