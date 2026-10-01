" Cerebras Software Language syntax highlighting.
if exists("b:current_syntax")
  finish
endif

syn case match
syn keyword cslKeyword param const var comptime layout struct enum union
syn keyword cslKeyword fn task export extern inline noinline async
syn keyword cslConditional if else switch
syn keyword cslRepeat for while break continue
syn keyword cslStatement return defer unreachable
syn keyword cslType bool void noreturn type anytype anyopaque
syn keyword cslType color input_queue output_queue local_task_id data_task_id control_task_id
syn keyword cslType mem1d_dsd mem4d_dsd fabin_dsd fabout_dsd
syn match cslType /\<[iuf]\d\+\>/
syn keyword cslBoolean true false
syn keyword cslConstant null undefined
syn match cslFunction /\<[A-Za-z_][A-Za-z0-9_]*\ze\s*(/
syn match cslBuiltin /@[A-Za-z_][A-Za-z0-9_]*/
syn match cslNumber /\<\d[0-9_]*\>/
syn match cslNumber /\<0[xX][0-9a-fA-F_]\+\>/
syn match cslNumber /\<0[bB][01_]\+\>/
syn match cslFloat /\<\d[0-9_]*\.[0-9_]\+\%([eE][+-]\=[0-9_]\+\)\=/
syn match cslFloat /\<\d[0-9_]*[eE][+-]\=[0-9_]\+/
syn match cslEscape /\\\%([nrt\\"']\|x\x\{2}\)/ contained
syn region cslString start=/"/ skip=/\\./ end=/"/ contains=cslEscape
syn region cslCharacter start=/'/ skip=/\\./ end=/'/ contains=cslEscape oneline
syn keyword cslTodo TODO FIXME XXX NOTE contained
syn match cslComment /\/\/.*$/ contains=cslTodo,@Spell
syn region cslComment start=/\/\*/ end=/\*\// contains=cslTodo,@Spell

hi def link cslKeyword Keyword
hi def link cslConditional Conditional
hi def link cslRepeat Repeat
hi def link cslStatement Statement
hi def link cslType Type
hi def link cslBoolean Boolean
hi def link cslConstant Constant
hi def link cslFunction Function
hi def link cslBuiltin Function
hi def link cslNumber Number
hi def link cslFloat Float
hi def link cslEscape SpecialChar
hi def link cslString String
hi def link cslCharacter Character
hi def link cslTodo Todo
hi def link cslComment Comment

let b:current_syntax = "csl"
