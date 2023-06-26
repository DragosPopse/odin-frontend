package frontend_ast

import "core:strings"

expr_to_string :: proc(expression: ^Node) -> string {
	unimplemented()
}

allow_field_separator :: proc(f: ^File) -> bool {
	unimplemented()
}

ALLOW_NEWLINE :: true // !strict_style

thread_safe_get_ast_file_from_id :: proc(id: int) -> ^File {
	unimplemented()
}

// Note(Dragos): Is this correct?
token_end_of_line :: proc(f: ^File, tok: Token) -> Token {
	tok := tok
	offset := clamp(tok.pos.offset, 0, len(f.tokenizer.src) - 1)
	s := f.tokenizer.src[offset:]
	tok.pos.column -= 1
	for len(s) != 0 && s[0] != 0 && s[0] != '\n' {
		s = s[1:]
		tok.pos.column += 1
	}
	return tok
}

// Todo: Review
get_file_line_as_string :: proc(pos: Token_Pos) -> (str: string, offset_: int) {
	file := thread_safe_get_ast_file_from_id(pos.file_id)
	if file == nil {
		return
	}
	offset := pos.offset
	if len(file.tokenizer.src) < offset {
		return
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


global_total_node_memory_allocated_atomic: int