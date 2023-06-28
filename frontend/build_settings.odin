package frontend

Command_Kind :: enum {
    Doc,
}

Build_Context :: struct {
    strict_style: bool,
    strict_style_init_only: bool,
    ignore_lazy: bool,
    command_kind: Command_Kind,
}


build_context: Build_Context