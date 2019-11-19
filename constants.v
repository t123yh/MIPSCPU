`define aluDisabled 0
`define aluAdd 5
`define aluSub 1
`define aluOr 2
`define aluAnd 3
`define aluShiftLeft 4
`define DEBUG
// `define VERBOSE

`define grfWriteDisable 0
`define grfWriteALU 1
`define grfWriteMem 2
`define grfWritePC 3

`define absJumpImmediate 1
`define absJumpRegister 0

`define bitsOfStatus 1000

`define stallNone 0
`define stallFetch 1
`define stallDecode 2
`define stallExecution 3
`define stallMemory 4