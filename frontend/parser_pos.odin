package frontend

ast_token :: proc(node: ^Ast) -> Token {
    unimplemented()
}

token_pos_end :: proc(token: Token) -> Token_Pos {
    unimplemented()
}

ast_end_token :: proc(node: ^Ast) -> Token {
    unimplemented()
}

ast_end_pos :: proc(node: ^Ast) -> Token_Pos {
    return token_pos_end(ast_end_token(node))
}