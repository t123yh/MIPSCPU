`include "constants.v"
module SystemBridge(
           input clk,
           input reset,
           input writeEnable,
           input readEnable,
           input [31:0] address,
           input [31:0] writeDataIn,
           output reg [31:0] readData,
           output reg exception,

           output WE0,
           input [31:0] TC0BIPO,
           output [31:0] TC0BOPI,

           output WE1,
           input [31:0] TC1BIPO,
           output [31:0] TC1BOPI
       );

reg CS_TC0, CS_TC1;

assign WE0 = CS_TC0 && writeEnable;
assign WE1 = CS_TC1 && writeEnable;
assign TC1BOPI = writeDataIn;
assign TC0BOPI = writeDataIn;

always @(*) begin
    readData = 'bx;
    exception = 0;
    if (readEnable || writeEnable) begin
        if (CS_TC0) begin
            readData = TC0BIPO;
        end
        else if (CS_TC1) begin
            readData = TC1BIPO;
        end
        else begin
            exception = 1;
        end
    end
end

always @(*) begin
    CS_TC0 = 0;
    CS_TC1 = 0;
    if (writeEnable) begin
        if (address[15:0] >= 'h7F00 && address[15:0] <= 'h7F07) begin
            CS_TC0 = 1;
        end
        else if (address[15:0] >= 'h7F10 && address[15:0] <= 'h7F17) begin
            CS_TC1 = 1;
        end
    end
    else if (readEnable) begin
        if (address[15:0] >= 'h7F00 && address[15:0] <= 'h7F0B) begin
            CS_TC0 = 1;
        end
        else if (address[15:0] >= 'h7F10 && address[15:0] <= 'h7F1B) begin
            CS_TC1 = 1;
        end
    end
end

endmodule
