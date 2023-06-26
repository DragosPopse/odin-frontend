package frontend

import "core:sync"
// add here things i have no idea about (yet!!!)



Blocking_Mutex :: sync.Mutex
RW_Mutex :: sync.RW_Mutex

// Note(Dragos): This might be removed soon enough
File_Info :: struct {
    name: string,
    fullpath: string,
    size: int,
    is_dir: bool,
}

// Note(Dragos): Wtf is this
Loaded_File :: struct {

}

Decl_Attribute_Proc :: #type proc()