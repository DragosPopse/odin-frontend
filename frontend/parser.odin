package frontend

import "core:container/queue"
import "core:sync"



is_ast_expr :: proc(node: ^Ast) -> bool {
	#partial switch in node.variant {
		case Ast_Bad_Expr,
		Ast_Tag_Expr,
		Ast_Unary_Expr,
		Ast_Binary_Expr,
		Ast_Paren_Expr,
		Ast_Selector_Expr,
		Ast_Implicit_Selector_Expr,
		Ast_Selector_Call_Expr,
		Ast_Index_Expr,
		Ast_Deref_Expr,
		Ast_Slice_Expr,
		Ast_Call_Expr,
		Ast_Field_Value,
		Ast_Enum_Field_Value,
		Ast_Ternary_If_Expr,
		Ast_Ternary_When_Expr,
		Ast_Or_Else_Expr,
		Ast_Or_Return_Expr,
		Ast_Type_Assertion,
		Ast_Type_Cast,
		Ast_Auto_Cast,
		Ast_Inline_Asm_Expr,
		Ast_Matrix_Index_Expr: return true
	}
	return false
}

// Question(Dragos): Would this be way slower than a in_between comparison on an enum or reflection?
is_ast_stmt :: proc(node: ^Ast) -> bool {
	#partial switch in node.variant {
		case Ast_Bad_Stmt,
		Ast_Empty_Stmt,
		Ast_Expr_Stmt,
		Ast_Assign_Stmt,
		Ast_Block_Stmt,
		Ast_If_Stmt,
		Ast_When_Stmt,
		Ast_Return_Stmt,
		Ast_For_Stmt,
		Ast_Range_Stmt,
		Ast_Unroll_Range_Stmt,
		Ast_Case_Clause,
		Ast_Switch_Stmt,
		Ast_Type_Switch_Stmt,
		Ast_Defer_Stmt,
		Ast_Branch_Stmt,
		Ast_Using_Stmt: return true
	}

	return false
}

is_ast_complex_stmt :: proc(node: ^Ast) -> bool {
	#partial switch in node.variant {
		case Ast_Block_Stmt,
		Ast_If_Stmt,
		Ast_When_Stmt,
		Ast_Return_Stmt,
		Ast_For_Stmt,
		Ast_Range_Stmt,
		Ast_Unroll_Range_Stmt,
		Ast_Case_Clause,
		Ast_Switch_Stmt,
		Ast_Type_Switch_Stmt,
		Ast_Defer_Stmt,
		Ast_Branch_Stmt,
		Ast_Using_Stmt: return true
	}

	return false
}

is_ast_decl :: proc(node: ^Ast) -> bool {
	#partial switch in node.variant {
		case Ast_Bad_Decl,
		Ast_Foreign_Block_Decl,
		Ast_Label,
		Ast_Value_Decl,
		Ast_Package_Decl,
		Ast_Import_Decl,
		Ast_Foreign_Import_Decl: return true
	}

	return false
}

is_ast_type :: proc(node: ^Ast) -> bool {
	#partial switch in node.variant {
		case Ast_Typeid_Type,
		Ast_Helper_Type,
		Ast_Poly_Type,
		Ast_Proc_Type,
		Ast_Pointer_Type,
		Ast_Relative_Type,
		Ast_Multi_Pointer_Type,
		Ast_Array_Type,
		Ast_Dynamic_Array_Type,
		Ast_Struct_Type,
		Ast_Union_Type,
		Ast_Enum_Type,
		Ast_Bit_Set_Type,
		Ast_Map_Type,
		Ast_Matrix_Type: return true
	}

	return false
}

is_ast_when_stmt :: proc(node: ^Ast) -> bool {
	_, ok := &node.variant.(Ast_When_Stmt)
	return ok
}

// Learn(Dragos): Ast nodes are allocated by an arena. We can put the allocator in the parser
alloc_ast_node :: proc(f: ^Ast_File, $Variant: typeid) -> ^Ast {
	unimplemented()
}

expr_to_string :: proc(expr: ^Ast) -> string {
	unimplemented()
}

allow_field_separator :: proc(f: ^Ast_File) -> bool {
	unimplemented()
}

