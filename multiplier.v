`include "constants.v"

module Multiplier (
           input reset,
           input clk,
           input start,
           input [31:0] A,
           input [31:0] B,
           input [3:0] ctrl,
           output reg busy,
           output reg [31:0] HI,
           output reg [31:0] LO
       );

localparam MultiplicationDelay = 5;
localparam DivisionDelay = 10;

reg [31:0] inA, inB;
reg [3:0] counter;
reg [3:0] op;
reg [3:0] cycles;

wire [63:0] multiplyResult = $signed(inA) * $signed(inB);
wire [63:0] unsignedMultiplyResult = inA * inB;

always @(*) begin
    cycles = 0;
    case (op)
        `mtMultiply, `mtMultiplyUnsigned,`mtMSUB, `mtMADD, `mtMADDU:
            cycles = MultiplicationDelay;
        `mtDivide, `mtDivideUnsigned:
            cycles = DivisionDelay;
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        HI <= 0;
        LO <= 0;
        busy <= 0;
    end
    else if (start) begin
        if (ctrl == `mtSetHI) begin
            HI <= A;
        end
        else if (ctrl == `mtSetLO) begin
            LO <= A;
        end
        else begin
            inA <= A;
            inB <= B;
            op <= ctrl;
            counter <= 1;
            busy <= 1;
        end
    end
    else if (busy) begin
        if (counter < cycles) begin
            counter <= counter + 1;
        end
        else begin
            busy <= 0;
            case (op)
                `mtMultiply:
                    {HI, LO} <= $signed(inA) * $signed(inB);
                `mtMSUB:
                    {HI, LO} <= {HI, LO} - multiplyResult;
                `mtMADD:
                    {HI, LO} <= {HI, LO} + multiplyResult;
                `mtMADDU:
                    {HI, LO} <= {HI, LO} + unsignedMultiplyResult;
                `mtMultiplyUnsigned:
                    {HI, LO} <= inA * inB;
                `mtDivide: begin
                    if (inB != 0) begin
                        HI <= $signed(inA) % $signed(inB);
                        LO <= $signed(inA) / $signed(inB);
                    end
                end
                `mtDivideUnsigned: begin
                    if (inB != 0) begin
                        HI <= inA % inB;
                        LO <= inA / inB;
                    end
                end
            endcase

        end
    end
end

endmodule