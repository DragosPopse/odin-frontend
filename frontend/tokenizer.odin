package frontend

import "core:hash"
import "core:strings"
import "core:mem"
import "core:slice"
import "core:fmt"
import "core:unicode"
import "core:unicode/utf8"
import "core:os"




Error_Handler :: #type proc(pos: Token_Pos, fmt: string, args: ..any)

default_error_handler :: proc(pos: Token_Pos, msg: string, args: ..any) {
    fmt.eprintf("%v(%d:%d) ", pos.file_id, pos.line, pos.column) // Note(Dragos): Need to get the file from id
    fmt.eprintf(msg, ..args)
    fmt.eprintf("\n")
}

error :: proc(t: ^Tokenizer, offset: int, msg: string, args: ..any) {
    pos := offset_to_pos(t, offset)
    if t.err != nil {
        t.err(pos, msg, ..args)
    }
    t.error_count += 1
}

Tokenizer_Init_Error :: enum {
    None,

    Invalid,
    Not_Exists,
    Permission,
    Empty,
    File_Too_Large,
}

Tokenizer :: struct {
    curr_file_id: int,
    fullpath: string,
    src: string,
    err: Error_Handler,

    // State
    ch: rune, // current char
    offset: int, // char pos
    read_offset: int, // pos from start
    line_offset: int,
    line_count: int,
    insert_semicolon: bool,

    error_count: int,


    loaded_file: Loaded_File,
}

tokenizer_init :: proc(t: ^Tokenizer, src: string, path: string, err: Error_Handler = default_error_handler) {
    t.src = src
    t.err = err
    t.ch = ' '
    t.offset = 0
    t.read_offset = 0
    t.line_offset = 0
    t.line_count = 1 if len(src) > 0 else 0
    t.error_count = 0
    t.fullpath = path // Todo(Dragos): Solve this too

    advance_rune(t)
    if t.ch == utf8.RUNE_BOM {
        advance_rune(t) 
    }
}

tokenizer_init_from_fullpath :: proc(t: ^Tokenizer, src: string, path: string, err: Error_Handler = default_error_handler) -> Tokenizer_Init_Error {
    t.err = err
    t.ch = ' '
    t.offset = 0
    t.read_offset = 0
    t.line_offset = 0
    data, file_error := os.read_entire_file(path)
    if file_error do return .Invalid

    t.src = string(data)
    t.line_count = 1 if len(src) > 0 else 0
    t.error_count = 0
    t.fullpath = path

    return .None
}

offset_to_pos :: proc(t: ^Tokenizer, offset: int) -> Token_Pos {
    line := t.line_count
    column := offset - t.line_offset + 1
    return Token_Pos {
        file_id = 0, //Todo(Dragos): Implement this shit
        offset = offset,
        line = line,
        column = column,
    }
}

advance_rune :: proc(t: ^Tokenizer) {
    if t.read_offset < len(t.src) {
        t.offset = t.read_offset
        if t.ch == '\n' {
            t.line_offset = t.offset
            t.line_count += 1
        }
        r, w := rune(t.src[t.read_offset]), 1
        switch {
            case r == 0: {
                error(t, t.offset, "illegal character NUL")
            }
            
            case r >= utf8.RUNE_SELF: {
                r, w = utf8.decode_rune_in_string(t.src[t.read_offset:])
                if r == utf8.RUNE_ERROR && w == 1 {
                    error(t, t.offset, "illegal UTF-8 encoding")
                } else if r == utf8.RUNE_BOM && t.offset > 0 {
                    error(t, t.offset, "illegal byte order mask")
                }
            }
        }
        t.read_offset += w
        t.ch = r
    } else { // We finished
        t.offset = len(t.src)
        if t.ch == '\n' {
            t.line_offset = t.offset
            t.line_count += 1
        }
        t.ch  = -1
    }
}

peek_byte :: proc(t: ^Tokenizer, offset := 0) -> byte {
    if t.read_offset + offset < len(t.src) {
        return t.src[t.read_offset + offset]
    }
    return 0
}

skip_whitespace :: proc(t: ^Tokenizer) {
    if t.insert_semicolon {
        for {
            switch t.ch {
                case ' ', '\t', '\r': advance_rune(t)
                case: return
            }
        }
    } else {
        for {
            switch t.ch {
                case ' ', '\t', '\r', '\n': advance_rune(t) 
                case: return
            }
        }
    }
}

is_letter_or_blank :: proc(r: rune) -> bool {
    if r < utf8.RUNE_SELF {
        switch r {
            case '_', 'A'..='Z', 'a'..='z': return true
        }
    }
    return unicode.is_letter(r)
}

is_digit :: proc(r: rune) -> bool {
    if '0' <= r && r >= '9' do return true
    return unicode.is_digit(r)
}

scan_comment :: proc(t: ^Tokenizer) -> string {
    offset := t.offset - 1
    next := -1
    general: {
        if t.ch == '/' || t.ch == '!' {
            advance_rune(t)
            for t.ch != '\n' && t.ch >= 0 {
                advance_rune(t)
            }

            next = t.offset
            if t.ch == '\n' {
                next += 1
            }
            break general
        }

        /* style comment */
        advance_rune(t)
        nest := 1
        for t.ch >= 0 && nest > 0 {
            ch := t.ch
            advance_rune(t)
            if ch == '/' && t.ch == '*' {
                nest += 1
            }

            if ch == '*' && t.ch == '/' {
                nest -= 1
                advance_rune(t) 
                next = t.offset 
                if nest == 0 {
                    break general
                }
            }
        }

        error(t, offset, "comment not terminated")
    }

    lit := t.src[offset : t.offset]

    // Strip CR for line comments
    if len(lit) > 2 && lit[1] == '/' && lit[len(lit) - 1] == '\r' {
        lit = lit[:len(lit)-1]
    }

    return lit
}

scan_identifier :: proc(t: ^Tokenizer) -> string {
    offset := t.offset
    for is_letter_or_blank(t.ch) || is_digit(t.ch) {
        advance_rune(t)
    }
    return t.src[offset : t.offset]
}

scan_string :: proc(t: ^Tokenizer) -> string {
    offset := t.offset - 1
    for {
        ch := t.ch
        if ch == '\n' || ch < 0 {
            error(t, offset, "string literal was not terminated")
            break
        }
        advance_rune(t)
        if ch == '"' {
            break
        }
        if ch == '\\' {
            scan_escape(t)
        }
    }

    return t.src[offset : t.offset]
}

scan_raw_string :: proc(t: ^Tokenizer) -> string {
    offset := t.offset - 1

    for {
        ch := t.ch
        if ch == utf8.RUNE_EOF {
            error(t, offset, "raw string literal was not terminated")
            break
        }
        advance_rune(t)
        if ch == '`' {
            break
        }
    }

    return t.src[offset : t.offset]
}

scan_escape :: proc(t: ^Tokenizer) -> bool {
    offset := t.offset

    n: int
    base, max: int
    switch t.ch {
        case 'a', 'b', 'e', 'f', 'n', 't', 'v', 'r', '\\', '\'', '\"': {
            advance_rune(t)
            return true
        }

        case '0'..='7': {
            n, base, max = 3, 8, 255
        }

        case 'x': {
            advance_rune(t)
            n, base, max = 2, 16, 255
        }

        case 'u': {
            advance_rune(t)
            n, base, max = 4, 16, utf8.MAX_RUNE
        }

        case: {
            if t.ch < 0 {
                error(t, offset, "escape sequence not terminated")
            } else {
                error(t, offset, "unknown escape sequence")
            }
            return false
        }
    }

    x: int
    for n > 0 {
        d := digit_val(t.ch)
        for d >= base {
            if t.ch < 0 {
                error(t, t.offset, "escape sequence was not terminated")
            } else {
                error(t, t.offset, "illegal character %v in escape sequence", t.ch)
            }
            return false
        }

        x = x * base + d
        advance_rune(t)
        n -= 1
    }

    if x > max || 0xd800 <= x && x <= 0xe000 {
        error(t, offset, "escape sequence is an invalid Unicode code point")
        return false
    }

    return true
}

// scan rune literals
scan_rune :: proc(t: ^Tokenizer) -> string {
    offset := t.offset - 1
    valid := true
    n := 0

    for {
        ch := t.ch
        if ch == '\n' || ch < 0 {
            if valid {
                error(t, offset, "rune literal not terminated")
                valid = false
            }
            break
        }
        advance_rune(t)
        if ch == '\'' do break
        n += 1
        if ch == '\\' {
            if !scan_escape(t) {
                valid = false
            }
        }
    }

    if valid && n != 1 {
        error(t, offset, "illegal rune literal")
    }

    return t.src[offset : t.offset]
}

scan_number :: proc(t: ^Tokenizer, seen_decimal_point: bool) -> (Token_Kind, string) {
    scan_mantissa :: proc(t: ^Tokenizer, base: int) {
        for digit_val(t.ch) < base || t.ch == '_' {
            advance_rune(t)
        }
    }

    scan_exponent :: proc(t: ^Tokenizer, kind: ^Token_Kind) {
        if t.ch == 'e' || t.ch == 'E' {
            kind^ = .Float
            advance_rune(t)
            if t.ch == '-' || t.ch == '+' {
                advance_rune(t)
            }
            if digit_val(t.ch) < 10 {
                scan_mantissa(t, 10)
            } else {
                error(t, t.offset, "illegal floating-point exponent")
            }
        }

        // imaginary stuff
        switch t.ch {
            case 'i', 'j', 'k': {
                kind^ = .Imag
                advance_rune(t)
            }
        }
    }

    scan_fraction :: proc(t: ^Tokenizer, kind: ^Token_Kind) -> (early_exit: bool) {
        if t.ch == '.' && peek_byte(t) == '.' {
            return true // ellipsis stuff (dragos: i think?)
        }
        if t.ch == '.' {
            kind^ = .Float
            advance_rune(t)
            scan_mantissa(t, 10)
        }
        return false
    }

    offset := t.offset 
    kind := Token_Kind.Integer
    seen_point := seen_decimal_point

    if seen_point {
        offset -= 1
        kind = .Float
        scan_mantissa(t, 10)
        scan_exponent(t, &kind)
    } else {
        if t.ch == '0' {
            int_base :: proc(t: ^Tokenizer, kind: ^Token_Kind, base: int, msg: string) {
                prev := t.offset
                advance_rune(t)
                scan_mantissa(t, base)
                if t.offset - prev <= 1 {
                    kind^ = .Invalid
                    error(t, t.offset, msg)
                }
            }

            advance_rune(t)
            switch t.ch {
                case 'b': int_base(t, &kind, 2, "illegal binary integer")
                case 'o': int_base(t, &kind, 8, "illegal octal integer")
                case 'd': int_base(t, &kind, 10, "illegal decimal integer")
                case 'z': int_base(t, &kind, 12, "illegal dozenal integer")
                case 'x': int_base(t, &kind, 16, "illegal hexadecimal integer")
                case 'h': {
                    prev := t.offset
                    advance_rune(t)
                    scan_mantissa(t, 16)
                    if t.offset - prev <= 1 {
                        kind = .Invalid
                        error(t, t.offset, "illegal hexadecimal floating point number")
                    } else {
                        sub := t.src[prev + 1 : t.offset]
                        digit_count := 0
                        for d in sub {
                            if d != '_' do digit_count += 1
                        }

                        switch digit_count {
                            case 4, 8, 16: break
                            case: error(t, t.offset, "invalid hexadecimial floating-point number, expected 4, 8 or 16 digits, got %d", digit_count)
                        }
                    }
                }

                case: {
                    seen_point = false
                    scan_mantissa(t, 10)
                    if t.ch == '.' {
                        seen_point = true
                        if scan_fraction(t, &kind) {
                            return kind, t.src[offset : t.offset]
                        }
                    }
                    scan_exponent(t, &kind)
                    return kind, t.src[offset : t.offset]
                }
            }
        }
    }

    scan_mantissa(t, 10)
    
    if scan_fraction(t, &kind) {
        return kind, t.src[offset : t.offset]
    }

    scan_exponent(t, &kind)

    return kind, t.src[offset : t.offset]
}

tokenizer_scan :: proc(t: ^Tokenizer) -> Token {
    skip_whitespace(t)

    offset := t.offset
    
    kind: Token_Kind
    lit: string
    pos := offset_to_pos(t, offset)

    switch ch := t.ch; true {
        case is_letter_or_blank(ch): {
            lit = scan_identifier(t)
            kind = .Ident
            check_keyword: {
                if 1 < len(lit) && len(lit) <= max_keyword_size && keyword_indices[len(lit)] {
                    hash := keyword_hash(lit)
                    index := hash & KEYWORD_HASH_TABLE_MASK
                    entry := &keyword_hash_table[index]
                    if entry.kind != .Invalid && entry.hash == hash {
                        if entry.text == lit {
                            kind = entry.kind
                        }
                    }
                }
            }
        }

        case '0' <= ch && ch <= '9': {
            kind, lit = scan_number(t, false)
        }

        case: {
            advance_rune(t)
            switch ch {
                case -1: {
                    kind = .EOF
                    if t.insert_semicolon {
                        t.insert_semicolon = false
                        kind = .Semicolon
                        lit = "\n"
                        return Token{kind, {}, lit, pos}
                    }
                }

                case '\n': {
                    t.insert_semicolon = false
                    kind = .Semicolon
                    lit = "\n"
                }

                case '\\': {
                    t.insert_semicolon = false
                    token := tokenizer_scan(t)
                    if token.pos.line == pos.line {
                        error(t, token.pos.offset, "expected a newline after \\")
                    }
                    return token
                }

                case '\'': {
                    kind = .Rune
                    lit = scan_rune(t)
                }

                case '"': {
                    kind = .String
                    lit = scan_string(t)
                }

                case '`': {
                    kind = .String
                    lit = scan_raw_string(t)
                }

                case '.': {
                    kind = .Period
                    switch t.ch {
                        case '0'..='9': {
                            kind, lit = scan_number(t, true)
                        }

                        case '.': {
                            advance_rune(t)
                            kind = .Ellipsis
                            switch t.ch {
                                case '<': {
                                    advance_rune(t)
                                    kind = .Range_Half
                                }
                                case '=': {
                                    advance_rune(t)
                                    kind = .Range_Full 
                                }
                            }
                        }
                    }
                }

                case '@': kind = .At
                case '$': kind = .Dollar
                case '?': kind = .Question
                case '^': kind = .Pointer
                case ';': kind = .Semicolon
                case ',': kind = .Comma
                case ':': kind = .Colon
                case '(': kind = .Open_Paren
                case ')': kind = .Close_Paren
                case '[': kind = .Open_Bracket
                case ']': kind = .Close_Bracket
                case '{': kind = .Open_Brace
                case '}': kind = .Close_Brace
                case '%': {
                    kind = .Mod
                    switch t.ch {
                        case '=': {
                            advance_rune(t)
                            kind = .Mod_Eq
                        }
                        case '%': {
                            advance_rune(t)
                            kind = .Mod_Eq
                            if t.ch == '=' {
                                advance_rune(t)
                                kind = .Mod_Mod_Eq
                            }
                        }
                    }
                }

                case '*': {
                    kind = .Mul
                    if t.ch == '=' {
                        advance_rune(t)
                        kind = .Mul_Eq
                    }
                }

                case '=': {
                    kind = .Eq
                    if t.ch == '=' {
                        advance_rune(t)
                        kind = .Xor_Eq
                    }
                }

                case '~': {
                    kind = .Xor
                    if t.ch == '=' {
                        advance_rune(t)
                        kind = .Xor_Eq
                    }
                }

                case '!': {
                    kind = .Not
                    if t.ch == '=' {
                        advance_rune(t)
                        kind = .Not_Eq
                    }
                }

                case '+': {
                    kind = .Add
                    switch t.ch {
                        case '=': {
                            advance_rune(t)
                            kind = .Add_Eq
                        }
                        case '+': {
                            advance_rune(t)
                            kind = .Increment
                        }
                    }
                }

                case '-': {
                    kind = .Sub
                    switch t.ch {
                        case '-': {
                            advance_rune(t)
                            kind = .Decrement 
                            if t.ch == '-' {
                                advance_rune(t)
                                kind = .Uninit
                            }
                        }

                        case '>': {
                            advance_rune(t)
                            kind = .Arrow_Right
                        }

                        case '=': {
                            advance_rune(t)
                            kind = .Sub_Eq
                        }
                    }
                }

                case '#': {
                    kind = .Hash
                    if t.ch == '!' {
                        kind = .Comment
                        lit = scan_comment(t)
                    }
                }

                case '/': {
                    kind = .Quo
                    switch t.ch {
                        case '/', '*': {
                            kind = .Comment
                            lit = scan_comment(t)
                        }

                        case '=': {
                            advance_rune(t)
                            kind = .Quo_Eq
                        }
                    }
                }

                case '<': {
                    kind = .Lt
                    switch t.ch {
                        case '=': {
                            advance_rune(t)
                            kind = .Lt_Eq
                        }

                        case '<': {
                            advance_rune(t)
                            kind = .Shl
                            if t.ch == '=' {
                                advance_rune(t)
                                kind = .Shl_Eq
                            }
                        }
                    }
                }

                case '>': {
                    kind = .Gt
                    switch t.ch {
                        case '=': {
                            advance_rune(t)
                            kind = .Gt_Eq
                        }

                        case '>': {
                            advance_rune(t)
                            kind = .Shr
                            if t.ch == '=' {
                                advance_rune(t)
                                kind = .Shr_Eq
                            }
                        }
                    }
                }

                case '&': {
                    kind = .And
                    switch t.ch {
                        case '~': {
                            advance_rune(t)
                            kind = .And_Not
                            if t.ch == '=' {
                                advance_rune(t)
                                kind = .And_Not_Eq
                            }
                        }

                        case '=': {
                            advance_rune(t)
                            kind = .And_Eq
                        }

                        case '&': {
                            advance_rune(t)
                            kind = .Cmp_And
                            if t.ch == '=' {
                                advance_rune(t)
                                kind = .Cmp_And_Eq
                            }
                        }
                    }
                }

                case '|': {
                    kind = .Or
                    switch t.ch {
                        case '=': {
                            advance_rune(t)
                            kind = .Or_Eq
                        }

                        case '|': {
                            advance_rune(t)
                            kind = .Cmp_Or
                            if t.ch == '=' {
                                advance_rune(t)
                                kind = .Cmp_Or_Eq
                            }
                        }
                    }
                }

                case: {
                    if ch != utf8.RUNE_BOM {
                        error(t, t.offset, "illegal character '%r': %d", ch, ch)
                    }
                    kind = .Invalid
                }
            }
        }
    }

    // Insert semicolon
    #partial switch kind {
        case .Invalid, .Comment: // preserve insert_semicolon info
        case .Ident,
             .Context,
             .Typeid,
             .Break,
             .Continue,
             .Fallthrough,
             .Return,
             .Integer,
             .Float,
             .Imag,
             .Rune,
             .String,
             .Uninit,
             .Question,
             .Pointer,
             .Close_Paren,
             .Close_Bracket,
             .Close_Brace,
             .Increment,
             .Decrement,
             .Or_return: t.insert_semicolon = true
        case: t.insert_semicolon = false
    }

    if lit == "" {
        lit = t.src[offset : t.offset]
    }

    return Token{kind, {}, lit, pos}
}

digit_val :: proc(r: rune) -> int {
    switch r {
        case '0'..='9': {
            return int(r - '0')
        }

        case 'a'..='f': {
            return int(r - 'a' + 10)
        }
        case 'A'..='F': {
            return int(r - 'A' + 10)
        }
    }
    return 16 // larger than highest possible
}