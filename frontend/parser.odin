package frontend

Ast :: struct {
    
}

Calling_Convention :: enum {
	Invalid     = 0,
	Odin        = 1,
	Contextless = 2,
	CDecl       = 3,
	StdCall     = 4,
	FastCall    = 5,

	None        = 6,
	Naked       = 7,

	InlineAsm   = 8,

	Win64       = 9,
	SysV        = 10,



	ForeignBlockDefault = -1,
};