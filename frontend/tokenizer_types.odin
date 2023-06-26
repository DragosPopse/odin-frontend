package frontend

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
    Mod_Mod,
    And,   
    Or,    
    Xor,   
    And_Not,
    Shl,   
    Shr,   
    Cmp_And,
    Cmp_Or,

    Assign_Op_Begin,
    Add_Eq,   
    Sub_Eq,   
    Mul_Eq,   
    Quo_Eq,   
    Mod_Eq,   
    Mod_Mod_Eq,
    And_Eq,   
    Or_Eq,    
    Xor_Eq,   
    And_Not_Eq,
    Shl_Eq,   
    Shr_Eq,   
    Cmp_And_Eq,
    Cmp_Or_Eq,
    Assign_Op_End,

    Increment, 
    Decrement, 
    Arrow_Right,
    Uninit,
    
    Comparison_Begin,
    Cmp_Eq,
    Not_Eq,
    Lt,   
    Gt,   
    Lt_Eq, 
    Gt_Eq,
    Comparison_End,

    Open_Paren,  
    Close_Paren, 
    Open_Bracket,
    Close_Bracket,
    Open_Brace,  
    Close_Brace, 
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

Tokenizer_Init_Error :: enum {
    None,

    Invalid,
    Not_Exists,
    Permission,
    Empty,
    File_Too_Large,
}

Tokenizer_Error_Handler :: #type proc(pos: Token_Pos, fmt: string, args: ..any)

Tokenizer :: struct {
    curr_file_id: int,
    fullpath: string,
    src: string,
    err: Tokenizer_Error_Handler,

    // State
    ch: rune, // current char
    offset: int, // char pos
    read_offset: int, // pos from start
    line_offset: int,
    line_count: int,
    insert_semicolon: bool,

    error_count: int,


    //loaded_file: Loaded_File, // Todo(Dragos): Figure this out
}

Token_Pos :: struct {
    file_id: int,
    offset: int,
    line: int, // starting at 1
    column: int, // starting at 1
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