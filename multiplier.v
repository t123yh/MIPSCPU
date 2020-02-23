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

localparam MultiplicationDelay = 7;
reg [31:0] inA, inB;
reg [3:0] op;

wire [63:0] multiplyResult;
wire [63:0] unsignedMultiplyResult;
mult_signed_0 signedMul(.A(inA), .B(inB), .CLK(clk), .SCLR(start), .P(multiplyResult));
mult_unsigned_0 unsignedMul(.A(inA), .B(inB), .CLK(clk), .SCLR(start), .P(unsignedMultiplyResult));

wire [63:0] signedDivResult;
wire [63:0] unsignedDivResult;
wire signedDivValid, unsignedDivValid;
wire inputDataValid = busy;
div_signed_0 signedDiv(
    .aclk(clk),
    .aresetn(!start),
    .s_axis_divisor_tvalid(inputDataValid),
    .s_axis_divisor_tdata(inB),
    .s_axis_dividend_tvalid(inputDataValid),
    .s_axis_dividend_tdata(inA),
    .m_axis_dout_tdata(signedDivResult),
    .m_axis_dout_tvalid(signedDivValid)
);
div_unsigned_0 unsignedDiv(
    .aclk(clk),
    .aresetn(!start),
    .s_axis_divisor_tvalid(inputDataValid),
    .s_axis_divisor_tdata(inB),
    .s_axis_dividend_tvalid(inputDataValid),
    .s_axis_dividend_tdata(inA),
    .m_axis_dout_tdata(unsignedDivResult),
    .m_axis_dout_tvalid(unsignedDivValid)
);

reg [3:0] counter;
reg ready;
always @(*) begin
    ready = 0;
    case (op)
        `mtMultiply, `mtMultiplyUnsigned,`mtMSUB, `mtMADD, `mtMADDU:
            ready = counter > MultiplicationDelay;
        `mtDivide:
            ready = signedDivValid;
        `mtDivideUnsigned:
            ready = unsignedDivValid;
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        HI <= 0;
        LO <= 0;
        busy <= 0;
        counter <= 'bX;
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
            counter <= 0;
            busy <= 1;
        end
    end
    else if (busy) begin
        if (ready) begin
            counter <= 'bX;
            busy <= 0;
            case (op)
                `mtMultiply:
                    {HI, LO} <= multiplyResult;
                `mtMSUB:
                    {HI, LO} <= {HI, LO} - multiplyResult;
                `mtMADD:
                    {HI, LO} <= {HI, LO} + multiplyResult;
                `mtMADDU:
                    {HI, LO} <= {HI, LO} + unsignedMultiplyResult;
                `mtMultiplyUnsigned:
                    {HI, LO} <= unsignedMultiplyResult;
                `mtDivide: begin
                    if (inB != 0) begin
                        {LO, HI} <= signedDivResult;
                    end
                end
                `mtDivideUnsigned: begin
                    if (inB != 0) begin
                        {LO, HI} <= unsignedDivResult;
                    end
                end
            endcase
        end else begin
            counter <= counter + 1;
        end
    end
end

endmodule