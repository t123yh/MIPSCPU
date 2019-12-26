# MIPSCPU
一个简易的 MIPS CPU。北航 2018 级计算机组成原理课程设计。

## 使用方法
使用 Mars 编译 CPU 代码，将 0x3000 起始的 text 区以 16 进制格式导入 code.txt，然后仿真即可。

## 支持的指令集
MIPS-C3: LB, LBU, LH, LHU, LW, SB, SH, SW, ADD, ADDU,  SUB,  SUBU,  MULT,  MULTU,  DIV,  DIVU,  SLL,  SRL,  SRA,  SLLV,  SRLV, SRAV, AND, OR, XOR, NOR, ADDI, ADDIU, ANDI, ORI,  XORI, LUI, SLT, SLTI, SLTIU, SLTU, BEQ, BNE, BLEZ, BGTZ,  BLTZ, BGEZ, J, JAL, JALR, JR, MFHI, MFLO, MTHI, MTLO

CP0 相关：MFC0, MTC0, ERET

## 外设
两个定时器，支持中断功能。寄存器地址分别在 0x7F00 - 0x7F0B, 0x7F10 - 0x7F1B。
