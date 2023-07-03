package frontend

Target_Os_Kind :: enum {
    Invalid,
    windows,
    darwin,
    linux,
    essence,
    freebsd,
    openbsd,
    wasi,
    js,
    freestanding,
}

Target_Arch_Kind :: enum u16 {
    Invalid,
    amd64,
    i386,
    arm32,
    arm64,
    wasm32,
    wasm64p32,
}

Target_ABI_Kind :: enum u16 {
    Default,
    Win64,
    SysV,
}

Target_Endian_Kind  :: enum u8 {
    Little,
    Big,
}

target_os_names := [Target_Os_Kind]string {
    .Invalid = "",
    .windows = "windows",
    .darwin = "darwin",
    .linux = "linux",
    .essence = "essence",
    .freebsd = "freebsd",
    .openbsd = "openbsd",
    .wasi = "wasi",
    .js = "js",
    .freestanding = "freestanding",
}

target_arch_names := [Target_Arch_Kind]string {
    .Invalid = "",
    .amd64 = "amd64",
    .i386 = "i386",
    .arm32 = "arm32",
    .arm64 = "arm64",
    .wasm32 = "wasm32",
    .wasm64p32 = "wasm64p32",
}

target_endian_names := [Target_Endian_Kind]string {
    .Little = "little",
    .Big = "big",
}

target_abi_names := [Target_ABI_Kind]string {
    .Default = "",
    .Win64 = "win64",
    .SysV = "sysv",
}

target_endians := [Target_Arch_Kind]Target_Endian_Kind {
    .Invalid = nil,
    .amd64 = .Little,
    .i386 = .Little,
    .arm32 = .Little,
    .arm64 = .Little,
    .wasm32 = .Little,
    .wasm64p32 = .Little,
}

Target_Metrics :: struct {
    os: Target_Os_Kind,
    arch: Target_Arch_Kind,
    ptr_size: int,
    int_size: int,
    max_align: int,
    max_simd_align: int,
    target_triplet: string,
    target_data_layout: string,
    abi: Target_ABI_Kind,
}

// Whats this??
Query_Data_Set_Kind :: enum {
    Invalid,
    Global_Definitions,
    Go_To_Definitions,
}

Query_Data_Set_Settings :: struct {
    kind: Query_Data_Set_Kind,
    ok, compact: bool,
}

Build_Mode_Kind :: enum {
    Executable,
    Dynamic_Library,
    Object,
    Assembly,
    LLVM_IR,
}

// we might not be needing most of this, but lets keep it here for the future
Command_Kind :: enum {
    Run,
    Build,
    Check,
    Doc,
    Version,
    Test,
    Strip_Semicolon,
    Bug_Report,
}

odin_command_strings := [Command_Kind]string {
    .Run = "run",
    .Build = "build",
    .Check = "check",
    .Doc = "doc",
    .Version = "version",
    .Test = "test",
    .Strip_Semicolon = "strip-semicolon",
    .Bug_Report = "report",
}


Cmd_Doc_Flag :: enum u32 {
    Short,
    All_Packages,
    Doc_Format,
}

Cmd_Doc_Flags :: bit_set[Cmd_Doc_Flag]

Timings_Export_Format :: enum i32 {
    Unspecified,
    JSON,
    CSV,
}

Error_Pos_Style :: enum {
    Default,// path(line:column) msg
    Unix,   // path:line:column: msg
}

// wtf is this
Reloc_Mode :: enum u8 {
    Default,
    Static,
    PIC,
    Dynamic_No_PIC,
}

Build_Path :: enum u8 {
    Main_Package, // Input path to the package directory (or file) we buildin'

    RC, // .rc path
    RES, // .res path generated from .rc
    Win_SDK_Bin_Path,
    Win_SDK_UM_Lib,
    Win_SDK_UCRT_Lib,
    VS_EXE,
    VS_LIB,

    Output,
    PDB,
}


Build_Context :: struct {
    ODIN_OS: string,
    ODIN_ARCH: string,
    ODIN_VENDOR: string, // compiler vendor
    ODIN_VERSION: string, 
    ODIN_BUILD_PROJECT_NAME: string,

    ODIN_DEBUG: bool,
    ODIN_DISABLE_ASSERT: bool,
    ODIN_DEFAULT_TO_NIL_ALLOCATOR: bool,
    ODIN_FOREIGN_ERROR_PROCEDURES: bool,
    ODIN_VALGRIND_SUPPORT: bool,

    ODIN_ERROR_POS_STYLE: Error_Pos_Style,

    endian_kind: Target_Endian_Kind,

    ptr_size, int_size, max_align, max_simd_align: int,

    command_kind: Command_Kind,
    command: string, // probably not needed

    metrics: Target_Metrics,
    show_help: bool, // defo not needed

    build_paths: [dynamic]string,

    out_filepath: string,
    resource_filepath: string,
    pdb_filepath: string,
    // Todo(Dragos): keep adding things in here as we need them

    ignore_lazy: bool,
    strict_style: bool,
    strict_style_init_only: bool,
}

build_context: Build_Context