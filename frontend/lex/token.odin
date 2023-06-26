package frontend_lex

import "core:hash"
import "core:fmt"




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
    .Mod_Mod             = "%%",
    .And                = "&",   
    .Or                 = "|",    
    .Xor                = "~",   
    .And_Not             = "&~",
    .Shl                = "<<",   
    .Shr                = ">>",   
    .Cmp_And             = "&&",
    .Cmp_Or              = "||",

    .Assign_Op_Begin    = "",
    .Add_Eq              = "+=",   
    .Sub_Eq              = "-=",   
    .Mul_Eq              = "*=",   
    .Quo_Eq              = "/=",   
    .Mod_Eq              = "%=",   
    .Mod_Mod_Eq           = "%%=",
    .And_Eq              = "&=",   
    .Or_Eq               = "|=",    
    .Xor_Eq              = "~=",   
    .And_Not_Eq           = "&~=",
    .Shl_Eq              = "<<=",   
    .Shr_Eq              = ">>=",   
    .Cmp_And_Eq           = "&&=",
    .Cmp_Or_Eq            = "||=",
    .Assign_Op_End      = "",

    .Increment          = "++", 
    .Decrement          = "--", 
    .Arrow_Right         = "->",
    .Uninit             = "---",
    
    .Comparison_Begin   = "",
    .Cmp_Eq             = "==",
    .Not_Eq             = "!=",
    .Lt                 = "<",   
    .Gt                 = ">",   
    .Lt_Eq              = "<=", 
    .Gt_Eq              = ">=",
    .Comparison_End     = "",

    .Open_Paren          = "(",  
    .Close_Paren         = ")", 
    .Open_Bracket        = "[",
    .Close_Bracket       = "]",
    .Open_Brace          = "{",  
    .Close_Brace         = "}", 
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
max_keyword_size := 11
keyword_indices: [16]bool

keyword_hash :: proc(text: string) -> u32 {
    return hash.fnv32a(transmute([]byte)text)
}

@(private = "file")
add_keyword_hash_entry :: proc(s: string, kind: Token_Kind) {
    max_keyword_size = max(max_keyword_size, len(s))
    keyword_indices[len(s)] = true
    hash := keyword_hash(s)
    index := hash & KEYWORD_HASH_TABLE_MASK
    entry := &keyword_hash_table[index]
    fmt.assertf(entry.kind == .Invalid, "Keyword hash table initialization collision: %s %s %d %d", s, token_strings[entry.kind], hash, entry.hash)
    entry.hash = hash
    entry.kind = kind
    entry.text = s
}

@(init, private = "file")
init_keyword_hash_table :: proc() {
    for kind: Token_Kind = .Keyword_Begin + cast(Token_Kind)1; kind < Token_Kind.Keyword_End; kind += cast(Token_Kind)1 {
        add_keyword_hash_entry(token_strings[kind], kind)
    }

    assert(max_keyword_size < 16)
}

global_file_path_strings: [dynamic]string // index is file id
global_files: [dynamic]^File

get_file_path_string :: proc(index: int) -> string {
    unimplemented()
}



empty_token := Token{
    kind = .Invalid,
}

blank_token := Token{
    kind = .Ident,
    text = "_",
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