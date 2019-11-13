`include "constants.v"

module Controller (
           input [31:0] instruction,
           input [31:0] debugPC,
           output [4:0] rs,
           output [4:0] rt,
           output reg memLoad,
           output reg memStore,
           output reg branch,
           output reg [31:0] immediate,
           output reg [4:0] destinationRegister,
           output reg aluSrc,
           output reg [3:0] aluCtrl,
           output reg absJump,
           output reg absJumpLoc, // 1 = immediate, 0 = register
           output reg [3:0] grfWriteSource
       );

wire [5:0] opcode = instruction[31:26];
wire [5:0] funct = instruction[5:0];

assign rt = instruction[20:16];
assign rs = instruction[25:21];
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
    immediate = 0;
    destinationRegister = 0;
    aluSrc = 0;
    aluCtrl = `aluAdd;
    absJump = 0;
    absJumpLoc = 0;
    case (opcode)
        R: begin
            case(funct)
                add: begin
                    grfWriteSource = `grfWriteALU;
                    destinationRegister = rd;
                    aluCtrl = `aluAdd;
                end
                sub: begin
                    grfWriteSource = `grfWriteALU;
                    destinationRegister = rd;
                    aluCtrl = `aluSub;
                end
                sll: begin
                    grfWriteSource = `grfWriteALU;
                    destinationRegister = rt;
                    aluSrc = 1;
                    immediate = instruction[10:6];
                    aluCtrl = `aluShiftLeft;
                end
                jr: begin
                    absJump = 1;
                    absJumpLoc = `absJumpRegister;
                end
                syscall: begin
                    $display("Bye");
                    $finish;
                end
            endcase
        end

        ori: begin
            grfWriteSource = `grfWriteALU;
            aluCtrl = `aluOr;
            destinationRegister = rt;
            aluSrc = 1;
            immediate = zeroExtendedImmediate;
        end

        lw: begin
            memLoad = 1;
            grfWriteSource = `grfWriteMem;
            destinationRegister = rt;
            aluSrc = 1;
            immediate = signExtendedImmediate;
        end

        sw: begin
            memStore = 1;
            aluSrc = 1;
            immediate = signExtendedImmediate;
        end

        beq: begin
            branch = 1;
            aluCtrl = `aluSub;
            immediate = signExtendedImmediate;
        end

        lui: begin
            grfWriteSource = `grfWriteALU;
            destinationRegister = rt;
            aluSrc = 1;
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
