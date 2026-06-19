" Vim syntax file
" Language:   mlir
" Maintainer: The MLIR team, http://github.com/tensorflow/mlir/
" Version:      $Revision$
" Some parts adapted from the LLVM vim syntax file.

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case match

" Types.
"
syn keyword mlirType index f16 f32 f64 bf16
" Signless integer types.
syn match mlirType /\<i\d\+\>/
" Unsigned integer types.
syn match mlirType /\<ui\d\+\>/
" Signed integer types.
syn match mlirType /\<si\d\+\>/

" Elemental types inside memref, tensor, or vector types.
syn match mlirType /x\s*\zs\(bf16\|f16\|f32\|f64\|i\d\+\|ui\d\+\|si\d\+\)/

" Shaped types.
syn match mlirType /\<memref\ze\s*<.*>/
syn match mlirType /\<tensor\ze\s*<.*>/
syn match mlirType /\<vector\ze\s*<.*>/

" vector types inside memref or tensor.
syn match mlirType /x\s*\zsvector/

" Operations.
" TODO: this list is not exhaustive.
syn keyword mlirOps alloc alloca addf addi and call call_indirect cmpf cmpi
syn keyword mlirOps constant dealloc divf dma_start dma_wait dim exp
syn keyword mlirOps getTensor index_cast load log memref_cast
syn keyword mlirOps memref_shape_cast mulf muli negf powf prefetch rsqrt sitofp
syn keyword mlirOps splat store select sqrt subf subi subview tanh
syn keyword mlirOps view

" Math dialect.
syn match mlirOps /\<math\.[a-z_]\+\>/

" Affine dialect.
syn match mlirOps /\<affine\.[a-z_]\+\>/

" Affine ops (legacy specific patterns).
syn match mlirOps /\<affine\.apply\>/
syn match mlirOps /\<affine\.dma_start\>/
syn match mlirOps /\<affine\.dma_wait\>/
syn match mlirOps /\<affine\.for\>/
syn match mlirOps /\<affine\.if\>/
syn match mlirOps /\<affine\.load\>/
syn match mlirOps /\<affine\.parallel\>/
syn match mlirOps /\<affine\.prefetch\>/
syn match mlirOps /\<affine\.store\>/
syn match mlirOps /\<scf\.execute_region\>/
syn match mlirOps /\<scf\.for\>/
syn match mlirOps /\<scf\.if\>/
syn match mlirOps /\<scf\.yield\>/

" Core MLIR dialect ops.
" Arith dialect.
syn match mlirOps /\<arith\.[a-z_]\+\>/

" Linalg dialect.
syn match mlirOps /\<linalg\.[a-z_]\+\>/

" Tensor dialect.
syn match mlirOps /\<tensor\.[a-z_]\+\>/

" Memref dialect.
syn match mlirOps /\<memref\.[a-z_]\+\>/

" Func dialect.
syn match mlirOps /\<func\.[a-z_]\+\>/

" Vector dialect.
syn match mlirOps /\<vector\.[a-z_]\+\>/

" Bufferization dialect.
syn match mlirOps /\<bufferization\.[a-z_]\+\>/

" Index dialect.
syn match mlirOps /\<index\.[a-z_]\+\>/

" CF (control flow) dialect.
syn match mlirOps /\<cf\.[a-z_]\+\>/

" SCF dialect (generic pattern).
syn match mlirOps /\<scf\.[a-z_]\+\>/

" GPU dialect.
syn match mlirOps /\<gpu\.[a-z_\.]\+\>/

" NVGPU dialect.
syn match mlirOps /\<nvgpu\.[a-z_\.]\+\>/

" AMDGPU dialect.
syn match mlirOps /\<amdgpu\.[a-z_\.]\+\>/

" LLVM dialect.
syn match mlirOps /\<llvm\.[a-z_\.]\+\>/

" SPIRV dialect.
syn match mlirOps /\<spirv\.[a-zA-Z_\.]\+\>/

" Transform dialect.
syn match mlirOps /\<transform\.[a-z_\.]\+\>/

" PDL dialect.
syn match mlirOps /\<pdl\.[a-z_]\+\>/

" Async dialect.
syn match mlirOps /\<async\.[a-z_]\+\>/

" ML Program dialect.
syn match mlirOps /\<ml_program\.[a-z_]\+\>/

" Complex dialect.
syn match mlirOps /\<complex\.[a-z_]\+\>/

" Sparse tensor dialect.
syn match mlirOps /\<sparse_tensor\.[a-z_]\+\>/

" TOSA dialect.
syn match mlirOps /\<tosa\.[a-z_]\+\>/

" Shape dialect.
syn match mlirOps /\<shape\.[a-z_]\+\>/

" Polynomial dialect.
syn match mlirOps /\<polynomial\.[a-z_]\+\>/

" Quant dialect.
syn match mlirOps /\<quant\.[a-z_]\+\>/

" IRDL dialect.
syn match mlirOps /\<irdl\.[a-z_]\+\>/

" IREE dialect ops.
" HAL (Hardware Abstraction Layer) dialect.
syn match mlirOps /\<hal\.[a-z_\.]\+\>/

" Flow dialect.
syn match mlirOps /\<flow\.[a-z_\.]\+\>/

" Stream dialect.
syn match mlirOps /\<stream\.[a-z_\.]\+\>/

" VM (Virtual Machine) dialect.
syn match mlirOps /\<vm\.[a-z_\.0-9]\+\>/

" Util dialect.
syn match mlirOps /\<util\.[a-z_\.]\+\>/

" VMVX dialect.
syn match mlirOps /\<vmvx\.[a-z_\.0-9]\+\>/

" IREE LinalgExt dialect.
syn match mlirOps /\<iree_linalg_ext\.[a-z_\.]\+\>/

" IREE Encoding dialect.
syn match mlirOps /\<iree_encoding\.[a-z_\.]\+\>/

" IREE TensorExt dialect.
syn match mlirOps /\<iree_tensor_ext\.[a-z_\.]\+\>/

" IREE Codegen dialect.
syn match mlirOps /\<iree_codegen\.[a-z_\.]\+\>/

" IREE GPU dialect.
syn match mlirOps /\<iree_gpu\.[a-z_\.]\+\>/

" IREE VectorExt dialect.
syn match mlirOps /\<iree_vector_ext\.[a-z_\.]\+\>/

" TODO: dialect name prefixed ops (llvm or std).

" Keywords.
syn keyword mlirKeyword
      \ affine_map
      \ affine_set
      \ dense
      \ else
      \ func
      \ module
      \ return
      \ step
      \ to

" Misc syntax.

syn match   mlirNumber /-\?\<\d\+\>/
" Match numbers even in shaped types.
syn match   mlirNumber /-\?\<\d\+\ze\s*x/
syn match   mlirNumber /x\s*\zs-\?\d\+\ze\s*x/

syn match   mlirFloat  /-\?\<\d\+\.\d*\(e[+-]\d\+\)\?\>/
syn match   mlirFloat  /\<0x\x\+\>/
syn keyword mlirBoolean true false
" Spell checking is enabled only in comments by default.
syn match   mlirComment /\/\/.*$/ contains=@Spell
syn region  mlirString start=/"/ skip=/\\"/ end=/"/
syn match   mlirLabel /[-a-zA-Z$._][-a-zA-Z$._0-9]*:/
" Prefixed identifiers usually used for ssa values and symbols.
syn match   mlirIdentifier /[%@][a-zA-Z$._-][a-zA-Z0-9$._-]*/
syn match   mlirIdentifier /[%@]\d\+\>/
" Prefixed identifiers usually used for blocks.
syn match   mlirBlockIdentifier /\^[a-zA-Z$._-][a-zA-Z0-9$._-]*/
syn match   mlirBlockIdentifier /\^\d\+\>/
" Prefixed identifiers usually used for types.
syn match   mlirTypeIdentifier /![a-zA-Z$._-][a-zA-Z0-9$._-]*/
syn match   mlirTypeIdentifier /!\d\+\>/
" Prefixed identifiers usually used for attribute aliases and result numbers.
syn match   mlirAttrIdentifier /#[a-zA-Z$._-][a-zA-Z0-9$._-]*/
syn match   mlirAttrIdentifier /#\d\+\>/

" Syntax-highlight lit test commands and bug numbers.
syn match  mlirSpecialComment /\/\/\s*RUN:.*$/
syn match  mlirSpecialComment /\/\/\s*CHECK:.*$/
syn match  mlirSpecialComment "\v\/\/\s*CHECK-(NEXT|NOT|DAG|SAME|LABEL):.*$"
syn match  mlirSpecialComment /\/\/\s*expected-error.*$/
syn match  mlirSpecialComment /\/\/\s*expected-remark.*$/
syn match  mlirSpecialComment /;\s*XFAIL:.*$/
syn match  mlirSpecialComment /\/\/\s*PR\d*\s*$/
syn match  mlirSpecialComment /\/\/\s*REQUIRES:.*$/

if version >= 508 || !exists("did_c_syn_inits")
  if version < 508
    let did_c_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink mlirType Type
  HiLink mlirOps Statement
  HiLink mlirNumber Number
  HiLink mlirComment Comment
  HiLink mlirString String
  HiLink mlirLabel Label
  HiLink mlirKeyword Keyword
  HiLink mlirBoolean Boolean
  HiLink mlirFloat Float
  HiLink mlirConstant Constant
  HiLink mlirSpecialComment SpecialComment
  HiLink mlirIdentifier Identifier
  HiLink mlirBlockIdentifier Label
  HiLink mlirTypeIdentifier Type
  HiLink mlirAttrIdentifier PreProc

  delcommand HiLink
endif

let b:current_syntax = "mlir"
