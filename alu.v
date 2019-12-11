`include "constants.v"
module ArithmeticLogicUnit (
           input [31:0] A,
           input [31:0] B,
           input [3:0] ctrl,
           output reg [31:0] out,
           output overflow // TODO: overflow bit is untested.
       );

wire [32:0] extA = {A[31], A}, extB = {B[31], B};
reg [32:0] tmp;
assign overflow = tmp[32] != tmp[31];

always @(*) begin
    tmp = 0;
    out = 0;
    case (ctrl)
`ifdef DEBUG

        `aluDisabled:
            out = 'bx;
`endif

        `aluAdd: begin
            tmp = extA + extB;
            out = tmp[31:0];
        end
        `aluSub: begin
            tmp = extA - extB;
            out = tmp[31:0];
        end

        `aluOr:
            out = A | B;
        `aluAnd:
            out = A & B;
        `aluXor:
            out = A ^ B;
        `aluNor:
            out = ~(A | B);

        `aluShiftLeft:
            out = A << B[4:0];
        `aluShiftRight:
            out = A >> B[4:0];
        `aluArithmeticShiftRight:
            out = $signed(A) >>> B[4:0];
        
        `aluSLT: begin
            out = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;
        end

        `aluSLTU: begin
            out = (A < B) ? 32'b1 : 32'b0;
        end
    endcase
end

endmodule
