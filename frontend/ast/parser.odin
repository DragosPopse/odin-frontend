package frontend_ast

alloc_ast_node :: proc(f: ^AstFile, kind: AstKind) -> ^Ast {
	unimplemented()
}

expr_to_string :: proc(expression: ^Ast) -> string {
	unimplemented()
}

allow_field_separator :: proc(f: ^AstFile) -> bool {
	unimplemented()
}

ALLOW_NEWLINE :: true // !strict_style

token_end_of_line :: proc(f: ^AstFile, tok: Token) -> Token {
	tok := tok
	offset := clamp(tok.pos.offset, 0, len(p.tok.src) - 1)
	s := p.tok.src[offset:]
	tok.pos.column -= 1
	for len(s) != 0 && s[0] != 0 && s[0] != '\n' {
		s = s[1:]
		tok.pos.column += 1
	}
	return tok
}

// Todo: Review
get_file_line_as_string :: proc(pos: Token_Pos) -> (str: string, offset_: i32) {
	file := thread_safe_get_ast_file_from_id(pos.file_id)
	if file == nil {
		return nil
	}
	offset := pos.offset
	if len(file.tokenizer.src) < offset {
		return nil
	}

	//pos_str := file.tokenizer.src[offset:]
	line_start := offset
	line_end := offset
	for line_start >= 0 {
		if file.tokenizer.src[line_start] == '\n' { // Note(Dragos): Should this utf decode?
			line_start += 1
			break
		}
		line_start -= 1
	}

	for line_end < len(file.tokenizer.src) {
		if file.tokenizer.src[line_end] == '\n' {
			break
		}
		line_end += 1
	}

	line := file.tokenizer.src[line_start:line_end]
	line = strings.trim(line, " \t\n\r") // trim whitespaces
	return strings.clone(line), line_start
}

// Todo(Dragos): This needs to be simplified, i have no idea how this works
ast_node_size :: proc(kind: AstKind) -> isize {
	unimplemented()
}

global_total_node_memory_allocated_atomic: isize