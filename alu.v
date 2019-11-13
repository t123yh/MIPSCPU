`include "constants.v"
//% @file alu.v
//% @brief xor with two inputs

//% Xor Module brief description
// @attribute A shit
module ArithmeticLogicUnit (
           input [31:0] A,
           input [31:0] B,
           input [3:0] ctrl,
           output reg [31:0] out
       );


always @(*) begin
    case (ctrl)
        `aluAdd:
            out <= A + B;
        `aluSub:
            out <= A - B;
        `aluOr:
            out <= A | B;
        `aluAnd:
            out <= A & B;
        `aluShiftLeft:
            out <= A << B;
    endcase
end

endmodule
