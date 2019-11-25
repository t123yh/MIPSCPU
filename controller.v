`include "constants.v"

module Controller (
           input [31:0] instruction,
           input [31:0] debugPC,
           input [3:0] currentStage,
           input reset,
           input bubble,

           output reg [4:0] regRead1,
           output reg [4:0] regRead2,
           output reg memLoad,
           output reg memStore,
           output reg branch,
           output reg branchEQ,
           output reg [31:0] immediate,
           output reg [4:0] destinationRegister,
           output reg aluSrc,
           output reg [3:0] aluCtrl,
           output reg absJump,
           output reg absJumpLoc, // 1 = immediate, 0 = register
           output reg [3:0] grfWriteSource,
           output reg bye,
           output reg needRegisterInJumpStage
       );

wire [5:0] opcode = instruction[31:26];
wire [5:0] funct = instruction[5:0];

wire [4:0] rti = instruction[20:16];
wire [4:0] rsi = instruction[25:21];
wire [4:0] rd = instruction[15:11];

wire[25:0] bigImm = instruction[25:0];
wire [15:0] imm = instruction[15:0];
wire [31:0] zeroExtendedImmediate = imm;
wire [31:0] shiftedImmediate = {imm, 16'b0};
wire [31:0] signExtendedImmediate = $signed(imm);

localparam R = 6'b000000;
localparam ori = 6'b001101;
localparam lw = 6'b100011;
localparam sw = 6'b101011;
localparam beq = 6'b000100;
localparam lui = 6'b001111;
localparam jal = 6'b000011;
localparam addiu = 6'b001001;
localparam j = 6'b000010;

localparam add = 6'b100001;
localparam sub = 6'b100011;
localparam sll = 6'b000000;
localparam jr = 6'b001000;
localparam syscall = 6'b001100;

localparam debug = 1;

always @(*) begin
    memLoad = 0;
    memStore = 0;
    grfWriteSource = `grfWriteDisable;
    branch = 0;
    needRegisterInJumpStage = 0;
    destinationRegister = 0;
    aluSrc = 0;
    aluCtrl = `aluDisabled;
    absJump = 0;
    regRead1 = 0;
    bye = 0;
    regRead2 = 0;
`ifdef DEBUG

    immediate = 'bx;
    absJumpLoc = 'bx;
`else
    immediate = 0;
    absJumpLoc = 0;
`endif

    if (!reset && !bubble)
    case (opcode)
        R: begin
            case(funct)
                add: begin
                    regRead1 = rsi;
                    regRead2 = rti;
                    grfWriteSource = `grfWriteALU;
                    destinationRegister = rd;
                    aluCtrl = `aluAdd;
                end
                sub: begin
                    regRead1 = rsi;
                    regRead2 = rti;
                    grfWriteSource = `grfWriteALU;
                    destinationRegister = rd;
                    aluCtrl = `aluSub;
                end
                sll: begin
                    regRead1 = rsi;
                    grfWriteSource = `grfWriteALU;
                    destinationRegister = rti;
                    aluSrc = 1;
                    immediate = instruction[10:6];
                    aluCtrl = `aluShiftLeft;
                end
                jr: begin
                    regRead1 = rsi;
                    absJump = 1;
                    absJumpLoc = `absJumpRegister;
                    needRegisterInJumpStage = 1;
                end
                syscall: begin
                    bye = 1;
                end
            endcase
        end

        addiu: begin
            regRead1 = rsi;
            grfWriteSource = `grfWriteALU;
            aluCtrl = `aluAdd;
            destinationRegister = rti;
            aluSrc = 1;
            immediate = signExtendedImmediate;
        end

        ori: begin
            regRead1 = rsi;
            grfWriteSource = `grfWriteALU;
            aluCtrl = `aluOr;
            destinationRegister = rti;
            aluSrc = 1;
            immediate = zeroExtendedImmediate;
        end

        lw: begin
            regRead1 = rsi;
            memLoad = 1;
            grfWriteSource = `grfWriteMem;
            destinationRegister = rti;
            aluSrc = 1;
            aluCtrl = `aluAdd;
            immediate = signExtendedImmediate;
        end

        sw: begin
            regRead1 = rsi;
            regRead2 = rti;
            memStore = 1;
            aluSrc = 1;
            aluCtrl = `aluAdd;
            immediate = signExtendedImmediate;
        end

        beq: begin
            regRead1 = rsi;
            regRead2 = rti;
            branch = 1;
            branchEQ = 1;
            immediate = signExtendedImmediate;
            needRegisterInJumpStage = 1;
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
            grfWriteSource = `grfWritePC;
            destinationRegister = 31;
        end

        j: begin
            absJump = 1;
            absJumpLoc = `absJumpImmediate;
            immediate = bigImm;
        end
    endcase
end

endmodule
