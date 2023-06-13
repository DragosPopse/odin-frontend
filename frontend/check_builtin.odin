package frontend

Builtin_Type_Is_Proc :: #type proc(t: ^Type) -> bool

check_or_else_right_type :: proc (c:^Checker_Context) {

}

gb_internal void check_or_else_right_type(CheckerContext *c, Ast *expr, String const &name, Type *right_type) {
	if (right_type == nullptr) {
		return;
	}
	if (!is_type_boolean(right_type) && !type_has_nil(right_type)) {
		gbString str = type_to_string(right_type);
		error(expr, "'%.*s' expects an \"optional ok\" like value, or an n-valued expression where the last value is either a boolean or can be compared against 'nil', got %s", LIT(name), str);
		gb_string_free(str);
	}
}

