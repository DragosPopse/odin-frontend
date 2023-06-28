package frontend

import "core:strings"
import "core:path/filepath"
import "core:unicode"
import "core:unicode/utf8"
import "core:os"

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

consume_comment_group :: proc(f: ^File, n: int) -> (group: ^Comment_Group, end_line: int) {
	unimplemented()
}

consume_comment_groups :: proc(f: ^File, prev_token: Token) {
	unimplemented()
}

next_token0 :: proc(f: ^File) -> bool {
	if f.curr_token_index + 1 < len(f.tokens) {
		f.curr_token_index += 1
		f.curr_token = f.tokens[f.curr_token_index]
		return true
	}
	syntax_error(f.curr_token, "Token is EOF")
	
	return false
	
}

ignore_newlines :: proc(f: ^File) -> bool {
	unimplemented()
}

skip_possible_newline :: proc(f: ^File) -> bool {
	if token_is_newline(f.curr_token) {
		advance_token(f)
		return true
	}
	return false
}

skip_possible_newline_for_literal :: proc(f: ^File) -> bool {
	curr := f.curr_token
	if token_is_newline(curr) {
		next := peek_token(f)
		if curr.pos.line + 1 >= next.pos.line {
			#partial switch next.kind {
				case .Open_Brace, .Else, .Where: {
					advance_token(f)
					return true
				}
			}
		}
	}

	return false
}

advance_token :: proc(f: ^File) -> Token {
	f.lead_comment = nil
	f.line_comment = nil
	f.prev_token_index = f.curr_token_index
	prev := f.curr_token
	f.prev_token = prev

	ok := next_token0(f)
	if ok {
		#partial switch f.curr_token.kind {
			case .Comment: {
				consume_comment_groups(f, prev)
			}

			case .Semicolon: {
				if ignore_newlines(f) && f.curr_token.text == "\n" {
					advance_token(f)
				}
			}
		}
	}

	return prev
}

peek_token :: proc(f: ^File) -> Token {
	for i := f.curr_token_index + 1; i < len(f.tokens); i += 1 {
		tok := f.tokens[i]
		if tok.kind == .Comment {
			continue
		}
		return tok
	}
	return {}
}


expect_token :: proc(f: ^File, kind: Token_Kind) -> Token {
	prev := f.curr_token
	if prev.kind != kind {
		c := token_strings[kind]
		syntax_error(f.curr_token, "Expected %v, got %v", c, prev.text) // this good?
		if prev.kind == .EOF {
			os.exit(1) // Note(Dragos): This may be good for a standalone, but not for this shit.
		}
	}
	advance_token(f)
	return prev
}

expect_token_after :: proc(f: ^File, kind: Token_Kind, msg: string) -> Token {
	prev := f.curr_token
	if prev.kind != kind {
		token := f.curr_token
		if token_is_newline(prev) {
			token = prev
			token.pos.column -= 1
			skip_possible_newline(f)
		}
		syntax_error(token, "Expected '%v' after %v, got '%v'", token_strings[kind], msg, token_strings[prev.kind])
	}
	advance_token(f)
	return prev
}

expect_operator :: proc(f: ^File) -> Token {
	prev := f.curr_token
	if (prev.kind == .In || prev.kind == .Not_in) && (f.expr_level >= 0 || f.allow_in_expr) {
		// ok
	} else if prev.kind == .If || prev.kind == .When {
		// ok
	} else if !(prev.kind > .Operator_Begin && prev.kind < .Operator_End) {
		syntax_error(f.curr_token, "Expected an operator, got '%v'", token_strings[prev.kind])
	} else if !(f.allow_range && token_is_range(prev)) {
		syntax_error(f.curr_token, "expected a non-range operator, got '%v'", token_strings[prev.kind])
	}

	if f.curr_token.kind == .Ellipsis {
		syntax_warning(f.curr_token, "'..' for ranges has now been deprecated, prefer '..='")
		f.tokens[f.curr_token_index].flags += {.Replace}
	}

	advance_token(f)
	return prev
}

allow_token :: proc(f: ^File, kind: Token_Kind) -> bool {
	prev := f.curr_token 
	if prev.kind == kind {
		advance_token(f)
		return true
	}
	return false
}

expect_closing_brace_of_field_list :: proc(f: ^File) -> Token {
	token := f.curr_token
	if allow_token(f, .Close_Brace) {
		return token
	}
	ok := true
	if f.allow_newline {
		ok = !skip_possible_newline(f)
	}
	if ok && allow_token(f, .Semicolon) {
		syntax_error(token_end_of_line(f, f.prev_token), "Expected a comma, got a %v", token_strings[token.kind])
	}

	return expect_token(f, .Close_Brace)
}


is_blank_ident_string :: proc(str: string) -> bool {
	if str == "_" do return true
	return false
}

is_blank_ident_token :: proc(token: Token) -> bool {
	if token.kind == .Ident do is_blank_ident_string(token.text)
	return false
}

is_blank_ident_node :: proc(node: ^Node) -> bool {
	unimplemented()
}

is_blank_ident :: proc {
	is_blank_ident_string,
	is_blank_ident_token,
	is_blank_ident_node,
}

expect_closing :: proc(f: ^File, kind: Token_Kind, ctx: string) -> Token {
	if f.curr_token.kind != kind && f.curr_token.kind == .Semicolon && (f.curr_token.text == "\n" || f.curr_token.kind == .EOF) {
		if f.allow_newline {
			tok := f.prev_token
			tok.pos.column += len(tok.text)
			syntax_error(tok, "Missing ',' before newline in %v", ctx)
		}
		advance_token(f)
	}
	return expect_token(f, kind)
}

assign_removal_flag_to_semicolon :: proc(f: ^File) {
	// this is used for rewriting files to strip unneeded semicolons
	prev_token := &f.tokens[f.prev_token_index]
	curr_token := &f.tokens[f.curr_token_index]
	assert(prev_token.kind == .Semicolon)
	if prev_token.text == ";" {
		ok := false
		if curr_token.pos.line > prev_token.pos.line {
			ok = true
		} else if curr_token.pos.line == prev_token.pos.line {
			#partial switch curr_token.kind {
				case .Close_Brace, .Close_Paren, .EOF: ok = true
			}
		}

		if ok {
			if build_context.strict_style {
				syntax_error(prev_token^, "Found unneeded semicolon")
			} else if build_context.strict_style_init_only && f.pkg.kind == .Init {
				syntax_error(prev_token^, "Found unneeded semicolon")
			}
			prev_token.flags += {.Remove}
		}
	}
}

token_pos_end :: proc(token: Token) -> Token_Pos {
	unimplemented()
}

expect_semicolon :: proc(f: ^File) {
	prev_token: Token
	if allow_token(f, .Semicolon) {
		assign_removal_flag_to_semicolon(f)
		return
	}

	#partial switch f.curr_token.kind {
		case .Close_Brace, .Close_Paren: {
			if f.curr_token.pos.line == f.prev_token.pos.line do return
		}
	}

	prev_token = f.prev_token
	if prev_token.kind == .Semicolon {
		assign_removal_flag_to_semicolon(f)
		return
	}

	if f.curr_token.kind == .EOF do return

	if f.curr_token.pos.line == f.prev_token.pos.line {
		prev_token.pos = token_pos_end(prev_token)
		syntax_error(prev_token, "Expected ';', got %v", token_strings[prev_token.kind])
		fix_advance_to_next_stmt(f)
	}
}

// go to next statement to prevent numerous error messages popping up
fix_advance_to_next_stmt :: proc(f: ^File) {
	unimplemented()
}

parse_file :: proc(p: ^Parser, f: ^File) -> bool {
	if len(f.tokens) == 0 do return true
	if len(f.tokens) > 0 && f.tokens[0].kind == .EOF do return true

	file_path := f.tokenizer.fullpath
	
	base_dir := filepath.dir(file_path) // Is this ok?

	if f.curr_token.kind == .Comment {
		consume_comment_groups(f, f.prev_token)
	}

	docs := f.lead_comment

	if f.curr_token.kind != .Package {
		syntax_error(f.curr_token, "Expected a package declaration at the beginning of the file")
	}

	f.package_token = expect_token(f, .Package)

	if f.package_token.kind != .Package {
		return false
	}

	if docs != nil {
		end := token_pos_end(docs.list[len(docs.list) - 1])
		if end.line == f.package_token.pos.line || end.line + 1 == f.package_token.pos.line {
			// ok
		} else {
			docs = nil
		}
	}

	package_name := expect_token_after(f, .Ident, "package")

	if package_name.kind == .Ident {
		if package_name.text == "_" {
			syntax_error(package_name, "Invalid package name '_'")
		} else if f.pkg.kind != .Runtime && package_name.text == "runtime" {
			syntax_error(package_name, "Use of reserved package name '%v'", package_name.text)
		} else if is_package_name_reserved(package_name.text) {
			syntax_error(package_name, "Use of reserved package name '%v'", package_name.text)
		}
	}

	f.package_name = package_name.text

	if !f.pkg.is_single_file && docs != nil && len(docs.list) > 0 {
		for tok in docs.list {
			assert(tok.kind == .Comment)
			if strings.has_prefix(tok.text, "//") {
				lc := strings.trim_space(tok.text[2:])
				if len(lc) > 0 && lc[0] == '+' { // Build command thing
					if strings.has_prefix(lc, "+build-project-name") {
						if !parse_build_project_directory_tag(tok, lc) {
							return false
						}
					} else if strings.has_prefix(lc, "+build") {
						if !parse_build_tag(tok, lc) {
							return false
						}
					} else if strings.has_prefix(lc, "+ignore") {
						return false
					} else if strings.has_prefix(lc, "+private") {
						f.flags += {.Is_Private_Pkg}
						command := strings.trim_left(lc, "+private ")
						command = strings.trim_space(command)
						// Note(Dragos): It's redundant to check lc == "+private", since we already know
						if command == "package" do f.flags += {.Is_Private_Pkg}
						else if command == "file" do f.flags += {.Is_Private_File}
						// Note(Dragos): Isn't this supposed to have some error checking for non package non file command?
					} else if strings.has_prefix(lc, "+lazy") {
						if build_context.ignore_lazy {
							// ignore
						} else if .Is_Test in f.flags {
							// ignore
						} else if f.pkg.kind == .Init && build_context.command_kind == .Doc {
							// ignore
						} else {
							f.flags += {.Is_Lazy}
						}
					} else {
						warning(tok, "Ignoring unknown tag '%v'", lc)
					}
				}
			}
		}
	}

	

	unimplemented()
}

warning_tok :: proc(tok: Token, msg: string, args: ..any) {
	unimplemented()
}

warning :: proc {
	warning_tok,
}

// Parse +build
parse_build_tag :: proc(token_for_pos: Token, s: string) -> bool {
	unimplemented()
}


// Parse +build-project-name
parse_build_project_directory_tag :: proc(token_for_pos: Token, s: string) -> bool {
	unimplemented()
}

is_package_name_reserved :: proc(name: string) -> bool {
	if name == "builtin" do return true
	else if name == "intrinsics" do return true
	return false
}

syntax_error_node :: proc(node: ^Node, format: string, args: ..any) {
	unimplemented()
}

syntax_error_token :: proc(token: Token, format: string, args: ..any) {
	unimplemented()
}

syntax_error_token_pos :: proc(pos: Token_Pos, format: string, args: ..any) {
	unimplemented()
}

syntax_error :: proc {
	syntax_error_node,
	syntax_error_token,
	syntax_error_token_pos,
}

syntax_warning_node :: proc(node: ^Node, format: string, args: ..any) {
	unimplemented()
}

syntax_warning_token :: proc(token: Token, format: string, args: ..any) {
	unimplemented()
}

syntax_warning_token_pos :: proc(pos: Token_Pos, format: string, args: ..any) {
	unimplemented()
}

syntax_warning :: proc {
	syntax_warning_node,
	syntax_warning_token,
	syntax_warning_token_pos,
}