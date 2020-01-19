" Vim syntax file
" Language : Minijazz

if exists("b:current_syntax")
	finish
endif

syn match inc "#include \".\"$"
syn region cmt start="(\*" end="\*)" contains=cmt

syn keyword kwds where end if then else reg ram rom
syn keyword consts true false
syn keyword ops and or xor not nand mux reg ram rom
syn keyword other const

let b:current_syntax = "mj"

hi def link kwds Conditional
hi def link consts Boolean
hi def link ops Operator
hi def link other Keyword
hi def link special Keyword
hi def link inc Include
hi def link cmt Comment
