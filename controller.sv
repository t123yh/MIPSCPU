`include "constants.v"

module Controller (
           input [31:0] instruction,
           input [31:0] debugPC,
           input [2:0] currentStage,
           input reset,
           input bubble,

           output logic [4:0] regRead1,
           output logic [4:0] regRead2,
           output logic regRead1Required,
           output logic regRead2Required,

           output logic [3:0] mulCtrl,
           output mulEnable,
           output logic mulOutputSel,

           output logic memLoad,
           output logic [1:0] memWidthCtrl,
           output logic memReadSignExtend,
           output logic memStore,
           output logic branch,
           output logic [31:0] immediate,
           output logic [4:0] destinationRegister,
           output logic aluSrc,
           output logic [3:0] aluCtrl,
           output logic [3:0] cmpCtrl,
           output logic absJump,
           output logic absJumpLoc, // 1 = immediate, 0 = register
           output logic [3:0] grfWriteSource,
           output logic checkOverflow,
           output logic [2:0] generateException,
           output logic writeCP0,
           output logic [4:0] numberCP0,

           output logic bye
       );

wire [5:0] opcode = instruction[31:26];
wire [5:0] funct = instruction[5:0];

wire [4:0] rti = instruction[20:16];
wire [4:0] rsi = instruction[25:21];
wire [4:0] rdi = instruction[15:11];

wire[25:0] bigImm = instruction[25:0];
wire [15:0] imm = instruction[15:0];
wire [31:0] zeroExtendedImmediate = imm;
wire [31:0] shiftedImmediate = {imm, 16'b0};
wire [31:0] signExtendedImmediate = $signed(imm);

assign mulEnable = mulCtrl != `mtDisabled;

localparam reg_ra = 31;

localparam R = 6'b000000;
localparam REGIMM = 6'b000001;
localparam ori = 6'b001101;
localparam andi = 6'b001100;
localparam xori = 6'b001110;
localparam lw = 6'b100011;
localparam sw = 6'b101011;
localparam beq = 6'b000100;
localparam bne = 6'b000101;
localparam blez = 6'b000110;
localparam bgtz = 6'b000111;
localparam lui = 6'b001111;
localparam jal = 6'b000011;
localparam addiu = 6'b001001;
localparam addi = 6'b001000;
localparam j = 6'b000010;
localparam lb = 6'b100000;
localparam lbu = 6'b100100;
localparam lh = 6'b100001;
localparam lhu = 6'b100101;
localparam sb = 6'b101000;
localparam sh = 6'b101001;
localparam special2 = 6'b011100;
localparam cop0 = 6'b010000;

localparam addu = 6'b100001;
localparam add = 6'b100000;
localparam subu = 6'b100011;
localparam sub = 6'b100010;
localparam _and = 6'b100100;
localparam _or = 6'b100101;
localparam _xor = 6'b100110;
localparam _nor = 6'b100111;
localparam sll = 6'b000000;
localparam srl = 6'b000010;
localparam sra = 6'b000011;
localparam sllv = 6'b000100;
localparam srlv = 6'b000110;
localparam srav = 6'b000111;
localparam jalr = 6'b001001;
localparam mult = 6'b011000;
localparam multu = 6'b011001;
localparam div = 6'b011010;
localparam divu = 6'b011011;
localparam mfhi = 6'b010000;
localparam mflo = 6'b010010;
localparam mthi = 6'b010001;
localparam mtlo = 6'b010011;
localparam msub = 6'b000100;
localparam madd = 6'b000000;
localparam maddu = 6'b000001;
localparam eret = 6'b011000;

localparam bltz = 5'b00000;
localparam bgez = 5'b00001;
localparam bltzal = 5'b10000;
localparam bgezal = 5'b10001;

localparam mfc0 = 5'b00000;
localparam mtc0 = 5'b00100;

localparam slt = 6'b101010;
localparam sltu = 6'b101011;
localparam slti = 6'b001010;
localparam sltiu = 6'b001011;

localparam jr = 6'b001000;
localparam syscall = 6'b001100;
localparam _break = 6'b001101;

localparam debug = 1;

always_comb begin
    regRead1Required = 0;
    regRead2Required = 0;
    if (currentStage == `stageD) begin
        if (absJump || branch) begin
            regRead1Required = 1;
            regRead2Required = 1;
        end
    end
    else if (currentStage == `stageE) begin
        if (aluCtrl != `aluDisabled || mulCtrl != `mtDisabled) begin
            regRead1Required = 1;
            if (aluSrc == 0)
                regRead2Required = 1;
        end
    end
    else if (currentStage == `stageM) begin
        if (memStore) begin
            regRead2Required = 1;
        end
    end
    else if (currentStage == `stageW) begin
        if (writeCP0) begin
            regRead1Required = 1;
        end
    end
end

`define simpleALU \
    regRead1 = rsi; \
    regRead2 = rti;\
    grfWriteSource = `grfWriteALU; \
    destinationRegister = rdi;

`define simpleShift \
    regRead1 = rti; \
    grfWriteSource = `grfWriteALU; \
    destinationRegister = rdi; \
    aluSrc = 1; \
    immediate = instruction[10:6];

`define simpleShiftVariable \
    regRead1 = rti; \
    regRead2 = rsi; \
    grfWriteSource = `grfWriteALU; \
    destinationRegister = rdi;

`define simpleALUImmediate \
    regRead1 = rsi; \
    grfWriteSource = `grfWriteALU; \
    destinationRegister = rti; \
    aluSrc = 1;

`define simpleBranch \
    regRead1 = rsi; \
    branch = 1; \
    immediate = signExtendedImmediate;

`define simpleMemoryLoad \
    regRead1 = rsi; \
    memLoad = 1; \
    grfWriteSource = `grfWriteMem; \
    destinationRegister = rti; \
    aluSrc = 1; \
    aluCtrl = `aluAdd; \
    checkOverflow = 1; \
    immediate = signExtendedImmediate; 

`define simpleMemoryStore \
    regRead1 = rsi; \
    regRead2 = rti; \
    memStore = 1; \
    aluSrc = 1; \
    aluCtrl = `aluAdd; \
    checkOverflow = 1; \
    immediate = signExtendedImmediate;

`define simpleMUL   \
    regRead1 = rsi; \
    regRead2 = rti;

`define simpleLink \
    grfWriteSource = `grfWritePC; \
    destinationRegister = reg_ra;

always_comb begin
    memLoad = 0;
    memStore = 0;
    grfWriteSource = `grfWriteDisable;
    branch = 0;
    destinationRegister = 0;
    aluSrc = 0;
    aluCtrl = `aluDisabled;
    absJump = 0;
    regRead1 = 0;
    bye = 0;
    regRead2 = 0;
    memWidthCtrl = 0;
    memReadSignExtend = 0;
    checkOverflow = 0;
    mulOutputSel = 'bx;
    mulCtrl = `mtDisabled;
    generateException = `ctrlNoException;
    writeCP0 = 0;
    numberCP0 = 0;
`ifdef DEBUG

    immediate = 'bx;
    absJumpLoc = 'bx;
`else
    immediate = 0;
    absJumpLoc = 0;
`endif

    if (!reset && !bubble)
    case (opcode)
        cop0: begin
            case (funct)
                6'b000000: begin
                    case (rsi)
                        mfc0: begin
                            destinationRegister = rti;
                            grfWriteSource = `grfWriteCP0;
                            numberCP0 = rdi;
                        end
                        mtc0: begin
                            regRead1 = rti;
                            writeCP0 = 1;
                            numberCP0 = rdi;
                        end
                    endcase
                end
                eret: begin
                    generateException = `ctrlERET;
                end
                default: begin
                    generateException = `ctrlUnknownInstruction;
                end
            endcase
        end
        special2: begin
            case (funct)
                msub: begin
                    `simpleMUL
                    mulCtrl = `mtMSUB;
                end
                madd: begin
                    `simpleMUL
                    mulCtrl = `mtMADD;
                end
                maddu: begin
                    `simpleMUL
                    mulCtrl = `mtMADDU;
                end
                default: begin
                    generateException = `ctrlUnknownInstruction;
                end
            endcase
        end

        REGIMM: begin
            case (rti)
                bltzal: begin
                    `simpleBranch
                    `simpleLink
                    cmpCtrl = `cmpLessThanZero;
                end
                bgezal: begin
                    `simpleBranch
                    `simpleLink
                    cmpCtrl = `cmpGreaterThanOrEqualToZero;
                end
                bltz: begin
                    `simpleBranch
                    cmpCtrl = `cmpLessThanZero;
                end
                bgez: begin
                    `simpleBranch
                    cmpCtrl = `cmpGreaterThanOrEqualToZero;
                end

                default: begin
                    generateException = `ctrlUnknownInstruction;
                end
            endcase
        end
        
        R: begin
            case(funct)
                addu: begin
                    `simpleALU
                    aluCtrl = `aluAdd;
                end
                subu: begin
                    `simpleALU
                    aluCtrl = `aluSub;
                end
                add: begin
                    `simpleALU
                    aluCtrl = `aluAdd;
                    checkOverflow = 1;
                end
                sub: begin
                    `simpleALU
                    aluCtrl = `aluSub;
                    checkOverflow = 1;
                end

                _and: begin
                    `simpleALU
                    aluCtrl = `aluAnd;
                end
                _or: begin
                    `simpleALU
                    aluCtrl = `aluOr;
                end
                _nor: begin
                    `simpleALU
                    aluCtrl = `aluNor;
                end
                _xor: begin
                    `simpleALU
                    aluCtrl = `aluXor;
                end

                sll: begin
                    `simpleShift
                    aluCtrl = `aluShiftLeft;
                end
                srl: begin
                    `simpleShift
                    aluCtrl = `aluShiftRight;
                end
                sra: begin
                    `simpleShift
                    aluCtrl = `aluArithmeticShiftRight;
                end

                sllv: begin
                    `simpleShiftVariable
                    aluCtrl = `aluShiftLeft;
                end
                srlv: begin
                    `simpleShiftVariable
                    aluCtrl = `aluShiftRight;
                end
                srav: begin
                    `simpleShiftVariable
                    aluCtrl = `aluArithmeticShiftRight;
                end

                slt: begin
                    `simpleALU
                    aluCtrl = `aluSLT;
                end

                sltu: begin
                    `simpleALU
                    aluCtrl = `aluSLTU;
                end

                jr: begin
                    regRead1 = rsi;
                    absJump = 1;
                    absJumpLoc = `absJumpRegister;
                end

                jalr: begin
                    regRead1 = rsi;
                    absJump = 1;
                    absJumpLoc = `absJumpRegister;
                    grfWriteSource = `grfWritePC;
                    destinationRegister = rdi;
                end

                syscall: begin
                    generateException = `ctrlSyscall;
                end

                _break: begin
                    generateException = `ctrlBreak;
                end

                mult: begin
                    `simpleMUL
                    mulCtrl = `mtMultiply;
                end

                multu: begin
                    `simpleMUL
                    mulCtrl = `mtMultiplyUnsigned;
                end

                div: begin
                    `simpleMUL
                    mulCtrl = `mtDivide;
                end

                divu: begin
                    `simpleMUL
                    mulCtrl = `mtDivideUnsigned;
                end

                mfhi: begin
                    mulOutputSel = 1;
                    destinationRegister = rdi;
                    grfWriteSource = `grfWriteMul;
                end

                mflo: begin
                    mulOutputSel = 0;
                    destinationRegister = rdi;
                    grfWriteSource = `grfWriteMul;
                end

                mthi: begin
                    regRead1 = rsi;
                    mulCtrl = `mtSetHI;
                end

                mtlo: begin
                    regRead1 = rsi;
                    mulCtrl = `mtSetLO;
                end

                default: begin
                    generateException = `ctrlUnknownInstruction;
                end
            endcase
        end

        addiu: begin
            `simpleALUImmediate
            immediate = signExtendedImmediate;
            aluCtrl = `aluAdd;
        end

        addi: begin
            `simpleALUImmediate
            immediate = signExtendedImmediate;
            aluCtrl = `aluAdd;
            checkOverflow = 1;
        end

        ori: begin
            `simpleALUImmediate
            immediate = zeroExtendedImmediate;
            aluCtrl = `aluOr;
        end

        xori: begin
            `simpleALUImmediate
            immediate = zeroExtendedImmediate;
            aluCtrl = `aluXor;
        end

        andi: begin
            `simpleALUImmediate
            immediate = zeroExtendedImmediate;
            aluCtrl = `aluAnd;
        end

        slti: begin
            `simpleALUImmediate
            immediate = signExtendedImmediate;
            aluCtrl = `aluSLT;
        end

        sltiu: begin
            `simpleALUImmediate
            immediate = signExtendedImmediate;
            aluCtrl = `aluSLTU;
        end

        lw: begin
            `simpleMemoryLoad
            memWidthCtrl = `memWidth4;
        end

        lh: begin
            `simpleMemoryLoad
            memWidthCtrl = `memWidth2;
            memReadSignExtend = 1;
        end

        lb: begin
            `simpleMemoryLoad
            memWidthCtrl = `memWidth1;
            memReadSignExtend = 1;
        end

        lhu: begin
            `simpleMemoryLoad
            memWidthCtrl = `memWidth2;
            memReadSignExtend = 0;
        end

        lbu: begin
            `simpleMemoryLoad
            memWidthCtrl = `memWidth1;
            memReadSignExtend = 0;
        end

        sw: begin
            `simpleMemoryStore
            memWidthCtrl = `memWidth4;
        end

        sh: begin
            `simpleMemoryStore
            memWidthCtrl = `memWidth2;
        end

        sb: begin
            `simpleMemoryStore
            memWidthCtrl = `memWidth1;
        end

        beq: begin
            `simpleBranch
            regRead2 = rti;
            cmpCtrl = `cmpEqual;
        end

        bne: begin
            `simpleBranch
            regRead2 = rti;
            cmpCtrl = `cmpNotEqual;
        end

        blez: begin
            `simpleBranch
            cmpCtrl = `cmpLessThanOrEqualToZero;
        end

        bgtz: begin
            `simpleBranch
            cmpCtrl = `cmpGreaterThanZero;
        end 


        lui: begin
            regRead1 = rsi;
            grfWriteSource = `grfWriteALU;
            destinationRegister = rti;
            aluSrc = 1;
            aluCtrl = `aluAdd;
            immediate = shiftedImmediate;
        end

        jal: begin
            absJump = 1;
            absJumpLoc = `absJumpImmediate;
            immediate = bigImm;
            `simpleLink
        end

        j: begin
            absJump = 1;
            absJumpLoc = `absJumpImmediate;
            immediate = bigImm;
        end

        default: begin
            generateException = `ctrlUnknownInstruction;
        end
    endcase
end

endmodule