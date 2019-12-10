`include "constants.v"

module CP0(
           input clk,
           input reset,
           input writeEnable,
           input [4:0] writeNumber,
           input [31:0] writeData,
           output [31:0] readData,

           input isException,
           input [4:0] exceptionCause,
           input [31:0] exceptionPC,

           output reg jump,
           output reg [31:0] jumpAddress
       );

wire [31:0] exceptionHandler = 32'h00004180;

reg [7:2] IM;
reg EXL;
reg IE;

reg BD;
reg [7:2] IP;
reg [4:0] ExcCode;

reg [31:0] EPC;

wire [31:0] PrId = 32'hDEADBEEF;

always @(*) begin
    jump = 0;
    jumpAddress = 'bx;
    if (isException) begin
        if (exceptionCause != `causeERET) begin
            jump = 1;
            jumpAddress = exceptionHandler;
        end
        else begin
            jump = 1;
            jumpAddress = EPC;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        IM = 0;
        EXL = 0;
        IE = 1;
        IP = 0;
    end
    else begin
        if (isException) begin
            if (exceptionCause == `causeERET) begin
                EXL <= 0;
            end
            else begin
                ExcCode <= exceptionCause;
                EPC <= exceptionPC;
                EXL <= 1;
            end
        end
    end
end

endmodule
