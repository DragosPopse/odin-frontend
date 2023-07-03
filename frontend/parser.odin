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
	token := f.curr_token
	if allow_token(f, .Comma) do return true
	if token.kind == .Semicolon {
		ok := false
		if ALLOW_NEWLINE && token_is_newline(token) {
			next := peek_token(f).kind
			#partial switch next {
			case .Close_Brace, .Close_Paren: ok = true
			}
		}
		if !ok {
			p := token_to_string(token)
			syntax_error(token_end_of_line(f, f.prev_token), "Expected a comma, got a %s", p)
		}
		advance_token(f)
		return true
	}
	return false
}

token_to_string :: proc(tok: Token) -> string {
	if token_is_newline(tok) do return "newline"
	return token_strings[tok.kind]
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

	pd, _ := make_package_decl(f, f.package_token, package_name, docs, f.line_comment)
	expect_semicolon(f)
	f.pkg_decl = pd

	if f.error_count == 0 {
		decls := make([dynamic]^Node)
		for f.curr_token.kind != .EOF {
			stmt := parse_stmt(f)
			if stmt != nil {
				if _, is_empty_stmt := stmt.variant.(Node_Empty_Stmt); !is_empty_stmt {
					append(&decls, stmt)
					if expr_stmt, is_expr_stmt := &stmt.variant.(Node_Expr_Stmt); is_expr_stmt && expr_stmt.expr != nil {
						if proc_lit, is_proc_lit := &expr_stmt.expr.variant.(Node_Proc_Lit); is_proc_lit  {
							syntax_error(stmt, "Procedure literal evaluated but not used")
						}
					}

					f.total_file_decl_count += calc_decl_count(stmt)
					#partial switch in stmt.variant {
					case Node_When_Stmt, Node_Expr_Stmt, Node_Import_Decl: f.delayed_decl_count += 1
					}
				}
			}
		}

		f.decls = decls[:]

		// parse_setup_file_decls(p, f, base_dir, f->decls);
	}
	

	unimplemented()
}

calc_decl_count :: proc(decl: ^Node) -> int {
	count := 0
	#partial switch var in decl.variant {
	case Node_Block_Stmt: 
		for stmt in var.stmts {
			count += calc_decl_count(stmt)
		}

	case Node_When_Stmt: 
		inner_count := calc_decl_count(var.body)
		if var.else_stmt != nil {
			inner_count = max(inner_count, calc_decl_count(var.else_stmt))
		}
		count += inner_count

	case Node_Value_Decl: 
		count = len(var.names)

	case Node_Foreign_Block_Decl: 
		count = calc_decl_count(var.body)
	
	case Node_Import_Decl, Node_Foreign_Import_Decl: count = 1
	}

	return count
}

parse_stmt :: proc(f: ^File) -> ^Node {
	s: ^Node
	token := f.curr_token
	#partial switch token.kind {
	case .Context, // Allows for `context = `
		.Proc, .Ident, .Integer,
		.Float, .Imag, .Rune,
		.String, .Open_Paren, .Pointer, .Asm,

		.Add, .Sub, .Xor,
		.Not, .And:
		s = parse_simple_stmt(f, {.Label})
		expect_semicolon(f)
		return s
	}
	
	unimplemented()
}

parse_simple_stmt :: proc(f: ^File, allow_flags: Stmt_Allow_Flags) -> ^Node {
	token := f.curr_token
	docs := f.lead_comment

	unimplemented()
}

parse_expr_list :: proc(f: ^File, lhs: bool) -> [dynamic]^Node {
	allow_newline := f.allow_newline
	defer f.allow_newline = allow_newline
	f.allow_newline = ALLOW_NEWLINE

	list := make([dynamic]^Node)
	for {
		e := parse_expr(f, lhs)
		append(&list, e)
		if f.curr_token.kind != .Comma || f.curr_token.kind == .EOF do break
		advance_token(f)
	}
	
	return list
}

parse_expr :: proc(f: ^File, lhs: bool) -> ^Node {
	return parse_binary_expr(f, lhs, 1)
}

parse_binary_expr :: proc(f: ^File, lhs: bool, prec_in: int) -> ^Node {
	lhs := lhs
	expr := parse_unary_expr(f, lhs)
	loop: for {
		op := f.curr_token
		op_prec := token_precedence(f, op.kind)
		if op_prec < prec_in do break // this will also catch invalid binary operators
		prev := f.prev_token
		#partial switch op.kind {
		case .If, .When: if prev.pos.line < op.pos.line do break loop
		}

		expect_operator(f)

		if op.kind == .Question {
			cond := expr
			x := parse_expr(f, lhs)
			token_c := expect_token(f, .Colon)
			y := parse_expr(f, lhs)
			expr, _ = make_ternary_if_expr(f, x, cond, y)
		} else if op.kind == .If || op.kind == .When { // Note(Dragos): Could we move the other switch in here?
			x := expr
			cond := parse_expr(f, lhs)
			tok_else := expect_token(f, .Else)
			y := parse_expr(f, lhs)

			if op.kind == .If do expr, _ = make_ternary_if_expr(f, x, cond, y)
			else if op.kind == .When do expr, _ = make_ternary_when_expr(f, x, cond, y) 
		} else {
			right := parse_binary_expr(f, false, op_prec + 1)
			if right == nil {
				syntax_error(op, "Expected expression on the right-hand side of the binary operator '%s'", op.text)
			}
			if op.kind == .Or_else {
				expr, _ = make_or_else_expr(f, expr, op, right)
			} else {
				expr, _ = make_binary_expr(f, op, expr, right) 
			}
		}

		lhs = false
	}

	return expr
}

parse_unary_expr :: proc(f: ^File, lhs: bool) -> ^Node {
	#partial switch f.curr_token.kind {
	case .Transmute, .Cast: 
		token := advance_token(f)
		expect_token(f, .Open_Paren)
		type := parse_type(f)
		expect_token(f, .Close_Paren)
		expr := parse_unary_expr(f, lhs)
		result, _ := make_type_cast(f, token, type, expr)
		return result
	
	case .Auto_cast: // maybe ols will help me rename things after i finish with this. god bless
		token := advance_token(f)
		expr := parse_unary_expr(f, lhs)
		result, _ := make_auto_cast(f, token, expr)
		return result
	
	case .Add, .Sub, .Xor, .And, .Not: 
		token := advance_token(f)
		expr := parse_unary_expr(f, lhs)
		result, _ := make_unary_expr(f, token, expr)
		return result
	
	case .Increment, .Decrement:
		token := advance_token(f)
		syntax_error(token, "Unary '%s' operator is not supported", token.text)
		expr := parse_unary_expr(f, lhs)
		result, _ := make_unary_expr(f, token, expr)
		return result

	case .Period: 
		token := expect_token(f, .Period)
		ident := parse_ident(f)
		result, _ := make_implicit_selector_expr(f, token, ident)
		return result
	}

	return parse_atom_expr(f, parse_operand(f, lhs), lhs)
}

token_precedence :: proc(f: ^File, t: Token_Kind) -> (priority: int) {
	#partial switch t {
	case .Question, .If, .When, .Or_else: return 1
	case .Ellipsis, .Range_Full, .Range_Half: 
		if !f.allow_range do return 0
		return 2
	case .Cmp_Or: return 3
	case .Cmp_And: return 4
	case .Cmp_Eq, .Not_Eq, .Lt, .Gt, .Lt_Eq, .Gt_Eq: return 5
	case .In, .Not_in: 
		if f.expr_level < 0 && !f.allow_in_expr do return 0
		return 6
	case .Add, .Sub, .Or, .Xor: return 6
	case .Mul, .Quo, .Mod, .Mod_Mod, .And, .And_Not, .Shl, .Shr: return 7
	}
	return 0
}

parse_type :: proc(f: ^File) -> ^Node {
	type := parse_type_or_ident(f)
	if type == nil {
		token := advance_token(f)
		syntax_error(token, "Expected a type")
		result, _ := make_bad_expr(f, token, f.curr_token)
		return result
	}
	return type
}

parse_type_or_ident :: proc(f: ^File) -> ^Node {
	prev_allow_type := f.allow_type
	prev_expr_level := f.expr_level
	defer {
		f.allow_type = prev_allow_type
		f.expr_level = prev_expr_level
	}

	f.allow_type = true
	f.expr_level = -1
	lhs := true
	operand := parse_operand(f, lhs)
	type := parse_atom_expr(f, operand, lhs)
	return type 
}

parse_atom_expr :: proc(f: ^File, operand: ^Node, lhs: bool) -> ^Node {
	unimplemented()
}

parse_operand :: proc(f: ^File, lhs: bool) -> ^Node {
	operand: ^Node
	#partial switch f.curr_token.kind {
	case .Ident:
		return parse_ident(f)
	
	case .Uninit: 
		result, _ := make_uninit(f, expect_token(f, .Uninit))
		return result

	case .Context: 
		result, _ := make_implicit(f, expect_token(f, .Context))
		return result

	case .Integer, .Float, .Imag, .Rune: 
		result, _ := make_basic_lit(f, advance_token(f))
		return result

	case .String: 
		result, _ := make_basic_lit(f, advance_token(f))
		return result

	case .Open_Brace: 
		if !lhs do return parse_literal_value(f, nil)		
	
	case .Open_Paren: 
		allow_newline: bool
		prev_expr_level: int
		open, close: Token
		open = expect_token(f, .Open_Paren)
		if f.prev_token.kind == .Close_Paren {
			close = expect_token(f, .Close_Paren)
			syntax_error(open, "Invalid parantheses expression with no inside expression")
			bad_expr, _ := make_bad_expr(f, open, close)
			return bad_expr
		}
		prev_expr_level = f.expr_level
		allow_newline = f.allow_newline
		if f.expr_level < 0 do f.allow_newline = false

		// enforce it to be >0
		f.expr_level = max(f.expr_level, 0) + 1
		operand = parse_expr(f, false)
		f.allow_newline = allow_newline
		f.expr_level = prev_expr_level
		close = expect_token(f, .Close_Paren)
		result, _ := make_paren_expr(f, operand, open, close)
		return result

	case .Distinct: 
		token := expect_token(f, .Distinct)
		type := parse_type(f)
		result, _ := make_distinct_type(f, token, type)
		return result

	case .Hash: // #stuff
		token := expect_token(f, .Hash)
		name := expect_token(f, .Ident)
		
		if name.text == "type" { // Note(Dragos): So a "helper type" is basically #type proc shit
			result, _ := make_helper_type(f, token, parse_type(f))
			return result
		} else if name.text == "simd" {
			tag, _ := make_basic_directive(f, token, name)
			original_type := parse_type(f)
			type := unparen_expr(original_type)
			#partial switch &var in type.variant {
			case Node_Array_Type: var.tag = tag
			case: syntax_error(type, "Expected a fixed array type after #%s, got %T", name.text, var) // Todo(Dragos): Figure some conversion from union to string
			}
			return original_type
		} else if name.text == "soa" {
			tag, _ := make_basic_directive(f, token, name)
			original_type := parse_type(f)
			type := unparen_expr(original_type) // What this do scooby doo?
			#partial switch &var in type.variant {
			case Node_Array_Type: var.tag = tag
			case Node_Dynamic_Array_Type: var.tag = tag
			case Node_Pointer_Type: var.tag = tag
			case: syntax_error(type, "Expected an array or pointer type after #%s, got %T", name.text, var)
			}
			return original_type
		} else if name.text == "partial" {
			tag, _ := make_basic_directive(f, token, name)
			original_expr := parse_expr(f, lhs)
			expr := unparen_expr(original_expr)
			#partial switch &var in expr.variant {
			case Node_Array_Type: syntax_error(expr, "#partial has been replaced with #sparse for non-contiguous enumerated array types")
			case Node_Compound_Lit: var.tag = tag
			case: syntax_error(expr, "Expected a compound literal after #%s, got %T", name.text, var)
			}
			return original_expr
		} else if name.text == "sparse" {
			tag, _ := make_basic_directive(f, token, name)
			original_type := parse_type(f)
			type := unparen_expr(original_type)
			#partial switch &var in type.variant {
			case Node_Array_Type: var.tag = tag
			case: syntax_error(type, "Expected an enumerated array type after #%s, got %T", name.text, var)
			}
			return original_type
		} else if name.text == "bounds_check" {
			operand := parse_expr(f, lhs)
			return parse_check_directive_for_statement(operand, name, {.Bounds_Check})
		} else if name.text == "no_bounds_check" {
			operand := parse_expr(f, lhs)
			return parse_check_directive_for_statement(operand, name, {.No_Bounds_Check})
		} else if name.text == "type_assert" {
			operand := parse_expr(f, lhs)
			return parse_check_directive_for_statement(operand, name, {.Type_Assert})
		} else if name.text == "no_type_assert" {
			operand := parse_expr(f, lhs)
			return parse_check_directive_for_statement(operand, name, {.No_Type_Assert})
		} else if name.text == "relative" {
			tag, _ := make_basic_directive(f, token, name)
			tag = parse_call_expr(f, tag) // Note(dragos): is this a leak? Looks goofed up
			type := parse_type(f)
			result, _ := make_relative_type(f, tag, type)
			return result
		} else if name.text == "force_inline" || name.text == "force_no_inline" {
			return parse_force_inline_operand(f, name) 
		}
		result, _ := make_basic_directive(f, token, name)
		return result

	case .Proc: // Procedure Type, Literal, Group
		token := expect_token(f, .Proc)
		if f.curr_token.kind == .Open_Brace { // Proc_Group
			open := expect_token(f, .Open_Brace)
			args := make([dynamic]^Node) // Note(Dragos): These are fo sure leaks smh

			for f.curr_token.kind != .Close_Brace && f.curr_token.kind != .EOF {
				elem := parse_expr(f, false)
				append(&args, elem)
				if !allow_field_separator(f) do break
			}

			close := expect_token(f, .Close_Paren)
			if len(args) == 0 {
				syntax_error(token, "Expected at least 1 argument in a procedure group")
			}

			result, _ := make_proc_group(f, token, open, close, args[:])
			return result
		}

		type := parse_proc_type(f, token)
		where_token: Token

		// Refactor(Dragos): So this dynamic arrays could be easily stored in the ast itself....
		where_clauses: [dynamic]^Node
		tags: Proc_Tags

		skip_possible_newline_for_literal(f)

		if f.curr_token.kind == .Where {
			where_token = expect_token(f, .Where)
			prev_level := f.expr_level
			f.expr_level = -1
			where_clauses = parse_rhs_expr_list(f)
			f.expr_level = prev_level
		}

		parse_proc_tags(f, &tags)
		if .Require_Results in tags {
			syntax_error(f.curr_token, "#require_results has now been replaced as an attribute @(require_results) on the declaration");
			tags -= {.Require_Results}
		}
		proc_type, is_proc_type := &type.variant.(Node_Proc_Type)
		assert(is_proc_type)
		proc_type.tags = tags
		if f.allow_type && f.expr_level < 0 {
			if tags != {} {
				syntax_error(token, "A procedure type cannot have suffix tags")
			}
			if where_token.kind != .Invalid {
				syntax_error(where_token, "'where' clauses are not allowed on procedure types")
			}
			return type
		}

		skip_possible_newline_for_literal(f)
		
		if !allow_token(f, .Uninit) { // proc() --- stuff
			if where_token.kind != .Invalid {
				syntax_error(where_token, "'where' clauses are not allowed on procedure literals without a defined body (replaced with ---)")
			}
			result, _ := make_proc_lit(f, type, nil, tags, where_token, where_clauses[:])
			return result
		} else if f.curr_token.kind == .Open_Brace { // actual proc finally
			curr_proc := f.curr_proc
			f.curr_proc = type // set the state temporarly 
			body := parse_body(f)
			f.curr_proc = curr_proc

			// apply the tags directly to the body rather than the type
			if .No_Bounds_Check in tags do body.state_flags += {.No_Bounds_Check}
			if .Bounds_Check in tags do body.state_flags += {.Bounds_Check}
			// Note(Dragos): So no_type_assert can be put at the proc level?!?! Bill document your language pls
			if .No_Type_Assert in tags do body.state_flags += {.No_Type_Assert}
			if .Type_Assert in tags do body.state_flags += {.Type_Assert}
			result, _ := make_proc_lit(f, type, body, tags, where_token, where_clauses[:])
			return result
		} else if allow_token(f, .Do) { // we don't allow this unforch
			curr_proc := f.curr_proc
			f.curr_proc = type
			body := convert_stmt_to_body(f, parse_stmt(f))
			f.curr_proc = curr_proc
			syntax_error(body, "'do' for procedure bodies is not allowed, prefer {}")
			result, _ := make_proc_lit(f, type, body, tags, where_token, where_clauses[:])
			return result 
		}

		if tags != {} do syntax_error(token, "A procedure type cannot have suffix tags")
		if where_token.kind != .Invalid do syntax_error(where_token, "'where' clauses are not allowed on procedure types")

		return type

		// Check for types
	case .Dollar: 
		token := expect_token(f, .Dollar)
		type := parse_ident(f)
		if is_blank_ident(type) {
			syntax_error(type, "Invalid polymorphic type definition with a blank identifier")
		}
		specialization: ^Node
		if allow_token(f, .Quo) { // $T/the_shit_here
			specialization = parse_type(f)
		}
		result, _ := make_poly_type(f, token, type, specialization)
		return result

	case .Typeid: 
		token := expect_token(f, .Typeid)
		result, _ := make_typeid_type(f, token, nil)
		return result

	case .Pointer: 
		token := expect_token(f, .Typeid) 
		result, _ := make_typeid_type(f, token, nil)
		return result

	case .Open_Bracket: 
		token := expect_token(f, .Open_Bracket)
		count_expr: ^Node
		if f.curr_token.kind == .Pointer {
			expect_token(f, .Pointer)
			expect_token(f, .Close_Bracket)
			result, _ := make_multi_pointer_type(f, token, parse_type(f))
			return result
		} else if f.curr_token.kind == .Question {
			count_expr, _ = make_unary_expr(f, expect_token(f, .Question), nil)
		} else if allow_token(f, .Dynamic) {
			expect_token(f, .Close_Bracket)
			result, _ := make_dynamic_array_type(f, token, parse_type(f))
			return result
		} else if f.curr_token.kind != .Close_Bracket {
			f.expr_level += 1
			count_expr = parse_expr(f, false)
			f.expr_level -= 1
		}
		
		expect_token(f, .Close_Bracket)
		result, _ := make_array_type(f, token, count_expr, parse_type(f))
		return result

	case .Map: 
		token := expect_token(f, .Map)

		open := expect_token_after(f, .Open_Bracket, "map")
		key := parse_expr(f, true) // Question(Dragos): Why is the key LHS?
		close := expect_token(f, .Close_Bracket)
		value := parse_type(f)

		result, _ := make_map_type(f, token, key, value)
		return result

	case .Matrix: 
		token := expect_token(f, .Matrix)
		
		open := expect_token_after(f, .Open_Bracket, "matrix")
		row_count := parse_expr(f, true)
		expect_token(f, .Comma)
		column_count := parse_expr(f, true)
		close := expect_token(f, .Close_Bracket)
		type := parse_type(f)

		result, _ := make_matrix_type(f, token, row_count, column_count, type)
		return result

	case .Struct: 
		token := expect_token(f, .Struct)
		polymorphic_params: ^Node
		is_packed, is_raw_union, no_copy: bool
		align: ^Node

		if allow_token(f, .Open_Paren) { // poly struct shit
			param_count := 0
			polymorphic_params := parse_field_list(f, &param_count, {}, .Close_Paren, true, true)
			if param_count == 0 {
				syntax_error(polymorphic_params, "Expected at least 1 polymorphic parameter")
			}
			expect_token_after(f, .Close_Paren, "parameter list")
			check_polymorphic_params_for_type(f, polymorphic_params, token) 
		}

		prev_level := f.expr_level
		f.expr_level = -1

		for allow_token(f, .Hash) {
			tag := expect_token_after(f, .Ident, "#")
			if tag.text == "packed" {
				if is_packed do syntax_error(tag, "Duplicate struct tag '#s'", tag.text)
				is_packed = true
			} else if tag.text == "align" {
				if align != nil do syntax_error(tag, "Duplicate struct tag '#s'", tag.text)
				align = parse_expr(f, true)
			} else if tag.text == "raw_union" {
				if is_raw_union do syntax_error(tag, "Duplicate struct tag '#s'", tag.text)
				is_raw_union = true
			} else if tag.text == "no_copy" {
				if no_copy do syntax_error(tag, "Duplicate struct tag '#s'", tag.text)
				no_copy = true
			} else {
				syntax_error(tag, "Invalid struct tag '#s'", tag.text)
			}
		}

		f.expr_level = prev_level

		if is_raw_union && is_packed {
			is_packed = false
			syntax_error(token, "'#raw_union' cannot also be '#packed'")
		}

		where_token: Token
		where_clauses: [dynamic]^Node

		skip_possible_newline_for_literal(f)

		if f.curr_token.kind == .Where {
			where_token = expect_token(f, .Where)
			prev_level = f.expr_level 
			f.expr_level = -1
			where_clauses = parse_rhs_expr_list(f)
			f.expr_level = prev_level
		}

		skip_possible_newline_for_literal(f)

		open := expect_token_after(f, .Open_Brace, "struct")
		name_count := 0
		fields := parse_struct_field_list(f, &name_count)
		close := expect_closing_brace_of_field_list(f)

		decls: []^Node
		if fields != nil {
			field_list, is_field_list := &fields.variant.(Node_Field_List)
			assert(is_field_list)
			decls = field_list.list
		}

		result, _ := make_struct_type(f, token, decls, name_count, polymorphic_params, is_packed, is_raw_union, no_copy, align, where_token, where_clauses[:])

	case .Union: 
		token := expect_token(f, .Union)
		polymorphic_params, align: ^Node
		no_nil, maybe, shared_nil: bool

		union_kind: Union_Type_Kind = .Normal

		start_token := f.curr_token

		if allow_token(f, .Open_Paren) { // Poly union nonsense. Note(Dragos): This reminds me that there is a type checking bug somewhere around this...
			param_count := 0
			polymorphic_params = parse_field_list(f, &param_count, {}, .Close_Paren, true, true)
			if param_count == 0 {
				syntax_error(polymorphic_params, "Expected at least 1 polymorphic parameter")
				polymorphic_params = nil
			}
			expect_token_after(f, .Close_Paren, "parameter list")
			check_polymorphic_params_for_type(f, polymorphic_params, token)
		}

		for allow_token(f, .Hash) { // Refactor(Dragos): Maybe this hashes can be separated somehow, it seems like a lot of code repetition
			tag := expect_token_after(f, .Ident, "#")
			if tag.text == "align" {
				if align != nil do syntax_error(tag, "Duplicate union tag '#%s'", tag.text)
				align = parse_expr(f, true)
			} else if tag.text == "no_nil" {
				if no_nil do syntax_error(tag, "Duplicate union tag '#%s'", tag.text)
				no_nil = true
			} else if tag.text == "shared_nil" {
				if shared_nil do syntax_error(tag, "Duplicate union tag '#%s'", tag.text)
				shared_nil = true
			} else if tag.text == "maybe" {
				if maybe do syntax_error(tag, "Duplicate union tag '#%s'", tag.text)
				maybe = true
			} else {
				syntax_error(tag, "Invalid union tag '#%s'", tag.text)
			}
		}

		if no_nil && shared_nil {
			syntax_error(f.curr_token, "#shared_nil and #no_nil cannot be applied together (be more decissive in your choices and pick one please)")
		}

		if maybe {
			syntax_error(f.curr_token, "#maybe functionality has been merged with normal union functionality (legacy nonsense)")
		}

		if no_nil do union_kind = .No_Nil
		else if shared_nil do union_kind = .Shared_Nil

		skip_possible_newline_for_literal(f)

		where_token: Token
		where_clauses: [dynamic]^Node

		if f.curr_token.kind == .Where {
			where_token = expect_token(f, .Where)
			prev_level := f.expr_level
			f.expr_level = -1
			where_clauses = parse_rhs_expr_list(f)
			f.expr_level = prev_level
		}

		skip_possible_newline_for_literal(f)

		open := expect_token_after(f, .Open_Brace, "union")
		variants := parse_union_variant_list(f) 
		close := expect_closing_brace_of_field_list(f)

		result, _ := make_union_type(f, token, variants[:], polymorphic_params, align, union_kind, where_token, where_clauses[:])
		return result

	case .Enum: 
		token := expect_token(f, .Enum)
		base_type: ^Node
		if f.curr_token.kind != .Open_Brace {
			base_type = parse_type(f) 
		}

		skip_possible_newline_for_literal(f)
		open := expect_token(f, .Open_Brace)
		values := parse_enum_field_list(f)
		close := expect_closing_brace_of_field_list(f)

		result, _ := make_enum_type(f, token, base_type, values[:])
		return result

	case .Bit_set:
		token := expect_token(f, .Bit_set)
		expect_token(f, .Open_Bracket)

		elem, underlying: ^Node
		prev_allow_range := f.allow_range
		f.allow_range = true
		elem = parse_expr(f, true)
		f.allow_range = prev_allow_range

		if allow_token(f, .Semicolon) {
			underlying = parse_type(f)
		} else if allow_token(f, .Comma) {
			syntax_error(token_end_of_line(f, f.prev_token), "Expected a semicolon, got %s", f.prev_token.text) // Note(Dragos): Thi
			underlying = parse_type(f)
		}

		expect_token(f, .Close_Bracket)
		
		result, _ := make_bit_set_type(f, token, elem, underlying)
		return result

	case .Asm: panic("TODO: Return here and implement this....I am lazy...")
	}

	return nil
}

parse_call_expr :: proc(f: ^File, operand: ^Node) -> ^Node {
	args := make([dynamic]^Node)
	open_paren, close_paren, ellipsis: Token
	prev_expr_level := f.expr_level
	prev_allow_newline := f.allow_newline
	f.expr_level = 0
	f.allow_newline = ALLOW_NEWLINE

	open_paren = expect_token(f, .Open_Paren)

	seen_ellipsis := false
	for f.curr_token.kind != .Close_Paren && f.curr_token.kind != .EOF {
		if f.curr_token.kind == .Comma {
			syntax_error(f.curr_token, "Expected an expression not ,")
		} else if f.curr_token.kind == .Eq {
			syntax_error(f.curr_token, "Expected an expression not =")
		}

		prefix_ellipsis := false
		if f.curr_token.kind == .Ellipsis {
			prefix_ellipsis = true
			ellipsis = expect_token(f, .Ellipsis)
		}

		arg := parse_expr(f, false)
		if f.curr_token.kind == .Eq {
			eq := expect_token(f, .Eq)

			if prefix_ellipsis {
				syntax_error(ellipsis, "'..' must be applied to value rather than the field name")
			}

			value := parse_value(f) 
			arg, _ = make_field_value(f, arg, value, eq)
		} else if seen_ellipsis {
			syntax_error(arg, "Positional arguments are not allowed after '..'")
		}
		append(&args, arg)

		if ellipsis.pos.line != 0 do seen_ellipsis = true
		if !allow_field_separator(f) do break
	}

	f.allow_newline = prev_allow_newline
	f.expr_level = prev_expr_level
	
	close_paren = expect_closing(f, .Close_Paren, "argument list")

	call, _ := make_call_expr(f, operand, args[:], open_paren, close_paren, ellipsis)

	o := unparen_expr(operand)
	selector_expr, is_selector_expr := &o.variant.(Node_Selector_Expr)
	if is_selector_expr && selector_expr.token.kind == .Arrow_Right {
		result, _ := make_selector_call_expr(f, selector_expr.token, o, call)
		return result
	}

	return call
}

parse_value :: proc(f: ^File) -> ^Node {
	unimplemented()
}

parse_enum_field_list :: proc(f: ^File) -> [dynamic]^Node {
	unimplemented()
}

parse_union_variant_list :: proc(f: ^File) -> [dynamic]^Node {
	unimplemented()
}

parse_struct_field_list :: proc(f: ^File, name_count_: ^int) -> ^Node {
	start_token := f.curr_token
	decls := make([dynamic]^Node) // Note(Dragos): Why is this here ?
	total_name_count := 0
	params := parse_field_list(f, &total_name_count, Field_Flags_Struct, .Close_Brace, false, false)
	if name_count_ != nil do name_count_^ = total_name_count
	return params
}

// Note(Dragos): This can be simplified. The logic looks a bit goofy.
check_procedure_name_list :: proc(names: []^Node) -> bool {
	if len(names) == 0 do return false
	_, first_is_polymorphic := names[0].variant.(Node_Poly_Type)
	any_polymorphic_names := first_is_polymorphic
	for i in 1..<len(names) {
		name := names[i]
		_, is_poly := name.variant.(Node_Poly_Type)
		if first_is_polymorphic {
			if is_poly { 
				any_polymorphic_names = true
			} else {
				syntax_error(name, "Mixture of polymorphic and non-polymorphic identifiers")
				return any_polymorphic_names
			}
		} else {
			if is_poly {
				any_polymorphic_names = true
				syntax_error(name, "Mixture of polymorphic and non-polymorphic identifiers")
				return any_polymorphic_names
			}
		}
	} 
	return any_polymorphic_names
}

// Refactor(Dragos): Maybe rename this check thing, since check should be type checker stuff
check_polymorphic_params_for_type :: proc(f: ^File, polymorphic_params: ^Node, token: Token) {
	unimplemented()
}

parse_field_list :: proc(f: ^File, name_count_: ^int, allowed_flags: Field_Flags, follow: Token_Kind, allow_default_parameters: bool, allow_typeid_token: bool) -> ^Node {
	prev_allow_newline := f.allow_newline
	defer f.allow_newline = prev_allow_newline
	f.allow_newline = ALLOW_NEWLINE

	start_token := f.curr_token
	docs := f.lead_comment

	params := make([dynamic]^Node)
	// This needs the weird AstAndFlags. Apparently it's coming from parse_field_prefixes, so Field_Flag
	return nil
}

convert_stmt_to_body :: proc(f: ^File, stmt: ^Node) -> ^Node {
	unimplemented()
}

parse_body :: proc(f: ^File) -> ^Node {
	prev_expr_level := f.expr_level
	prev_allow_newline := f.allow_newline

	f.expr_level = 0
	open := expect_token(f, .Open_Brace)
	stmts := parse_stmt_list(f)
	close := expect_token(f, .Close_Brace)

	f.expr_level = prev_expr_level
	f.allow_newline = prev_allow_newline

	result, _ := make_block_stmt(f, stmts[:], open, close)
	return result
}

parse_control_statement_semicolon_separator :: proc(f: ^File) -> bool {
	tok := peek_token(f)
	if tok.kind != .Open_Brace do return allow_token(f, .Semicolon)
	if f.curr_token.text == ";" do return allow_token(f, .Semicolon)
	return false
}

parse_do_body :: proc(f: ^File, token: Token, msg: string) -> ^Node {
	unimplemented()
}

parse_stmt_list :: proc(f: ^File) -> [dynamic]^Node {
	unimplemented()
}

parse_proc_tags :: proc(f: ^File, tags: ^Proc_Tags) -> ^Node {
	unimplemented()
}

parse_lhs_expr_list :: proc(f: ^File) -> [dynamic]^Node {
	return parse_expr_list(f, true)
}

parse_rhs_expr_list :: proc(f: ^File) -> [dynamic]^Node {
	return parse_expr_list(f, false)
}

parse_ident_list :: proc(f: ^File, allow_poly_names: bool) -> [dynamic]^Node {
	list := make([dynamic]^Node)

	for {
		append(&list, parse_ident(f, allow_poly_names))
		if f.curr_token.kind != .Comma || f.curr_token.kind == .EOF {
			break
		}
		advance_token(f)
	}

	return list
}

parse_proc_type :: proc(f: ^File, proc_token: Token) -> ^Node {
	params, results: ^Node
	diverging := false
	cc: Proc_Calling_Convention = .Invalid
	if f.curr_token.kind == .String {
		token := expect_token(f, .String)
		c := string_to_calling_convention(string_value_from_token(f, token))
		if c == .Invalid {
			syntax_error(token, "Unknown procedure calling convention '%s'", token.text)
		} else {
			cc = c
		}
	}

	if cc == .Invalid {
		if f.in_foreign_block do cc = .Foreign_Block_Default
		else do cc = default_calling_convention()
	}

	expect_token(f, .Open_Paren)
	params = parse_field_list(f, nil, Field_Flags_Signature, .Close_Paren, true, true)
	if ALLOW_NEWLINE do skip_possible_newline(f)
	
	expect_token_after(f, .Close_Paren, "parameter list")
	results = parse_results(f, &diverging)

	tags: Proc_Tags
	is_generic := false

	field_list := &params.variant.(Node_Field_List)
	loop: for &param in field_list.list {
		field := &param.variant.(Node_Field)
		if field.type != nil {
			if _, is_poly_type := field.type.variant.(Node_Poly_Type); is_poly_type {
				is_generic = true
				break loop
			}
			for name in field.names {
				if _, is_poly_type := name.variant.(Node_Poly_Type); is_poly_type {
					is_generic = true
					break loop
				}
			}
		}
	}
	
	result, _ := make_proc_type(f, proc_token, params, results, tags, cc, is_generic, diverging)
	return result
}

parse_var_type :: proc(f: ^File, allow_ellipsis: bool, allow_typeid_token: bool) -> ^Node {
	if allow_ellipsis && f.curr_token.kind == .Ellipsis {
		tok := advance_token(f) 
		type := parse_type_or_ident(f)
		if type == nil {
			syntax_error(tok, "Variadic field missing type after '..'")
			type, _ = make_bad_expr(f, tok, f.curr_token)
		}
		result, _ := make_ellipsis(f, tok, type)
		return result 
	}
	type: ^Node
	if allow_typeid_token && f.curr_token.kind == .Typeid {
		token := expect_token(f, .Typeid)
		specialization: ^Node
		if allow_token(f, .Quo) {
			specialization = parse_type(f)
		}
		type, _ = make_typeid_type(f, token, specialization)
	} else {
		type = parse_type(f)
	}
	return type
}

Parse_Field_Prefix_Mapping :: struct {
	name: string,
	token_kind: Token_Kind,
	flag: Field_Flag,
}

parse_field_prefix_mappings := [?]Parse_Field_Prefix_Mapping { // Note(Dragos): I could maybe make a sparse version of this using the Field_Flag
	{"using", .Using, .Using},
	{"no_alias", .Hash, .No_Alias},
	{"c_vararg", .Hash, .C_Vararg},
	{"const", .Hash, .Const},
	{"any_int", .Hash, .Any_Int},
	{"subtype", .Hash, .Subtype},
	{"by_ptr", .Hash, .By_Ptr},
}

is_token_field_prefix :: proc(f: ^File) -> Field_Flag {
	#partial switch f.curr_token.kind {
	case .EOF: return .Invalid
	case .Using: return .Using
	case .Hash:
		advance_token(f)
		#partial switch f.curr_token.kind {
		case .Ident: 
			for field_prefix in parse_field_prefix_mappings {
				if field_prefix.token_kind == .Hash {
					if f.curr_token.text == field_prefix.name {
						return field_prefix.flag
					}
				}
			}
		}
		return .Unknown
	}
	return .Invalid
}

parse_field_prefixes :: proc(f: ^File) -> Field_Flags {
	counts: [len(parse_field_prefix_mappings)]int
	for {
		flag := is_token_field_prefix(f)
		if flag == .Invalid do break
		if flag == .Unknown {
			syntax_error(f.curr_token, "Unknown prefix kind '#%s'", f.curr_token.text)
			advance_token(f)
			continue
		}

		for field_prefix, i in parse_field_prefix_mappings {
			if field_prefix.flag == flag {
				counts[i] += 1
				advance_token(f)
				break
			}
		}
	}

	field_flags: Field_Flags
	for field_flag, i in parse_field_prefix_mappings {
		if counts[i] > 0 {
			field_flags += {field_flag.flag}

			if counts[i] != 1 {
				prefix := ""
				if field_flag.token_kind == .Hash do prefix = "#"
				syntax_error(f.curr_token, "Multiple '%s%s' in this field list", prefix, field_flag.name)
			}
		}
	}

	return field_flags
}

parse_results :: proc(f: ^File, diverging: ^bool) -> ^Node {
	unimplemented()
}

string_value_from_token :: proc(f: ^File, token: Token) -> string {
	unimplemented()
}

string_to_calling_convention :: proc(str: string) -> Proc_Calling_Convention {
	unimplemented()
}

parse_force_inline_operand :: proc(f: ^File, token: Token) -> ^Node {
	unimplemented()
}

parse_check_directive_for_statement :: proc(s: ^Node, tag_token: Token, state_flags: State_Flags) -> ^Node {
	unimplemented()
}

unparen_expr :: proc(node: ^Node) -> ^Node {
	unimplemented()
}

parse_literal_value :: proc(f: ^File, type: ^Node) -> ^Node {
	unimplemented()
}

parse_ident :: proc(f: ^File, allow_poly_name := false) -> ^Node {
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
	prefix := "+build-project-name"
	assert(strings.has_prefix(s, prefix))
	s := strings.trim_space(s[len(prefix):])
	if len(s) == 0 do return true

	any_correct := false

	for len(s) > 0 {
		this_kind_correct := true
		for len(s) > 0 { // this needs to be a do while
			
		}
	}
	unimplemented()
}

process_imported_file :: proc(p: ^Parser, imported_file: Imported_File) -> Parse_File_Error {
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