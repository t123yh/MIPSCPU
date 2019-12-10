`include "constants.v"

module CP0(
           input clk,
           input reset,
           input writeEnable,
           input [4:0] number,
           input [31:0] writeData,
           output [31:0] readData,

           input isException,
           input [4:0] exceptionCause,
           input [31:0] exceptionPC,

           output reg jump,
           output reg [31:0] jumpAddress
       );

wire [31:0] exceptionHandler = 32'h00004180;

reg [31:0] registers [15:0];

always @(posedge clk) begin
    if (writeEnable) begin
        registers[number] <= writeData;
    end
end

assign readData = registers[number];

`define EPC registers[14]
`define PrId registers[15]
`define SR registers[12]
`define EXL `SR[1]
`define IE `SR[0]
`define IM `SR[15:10]
`define Cause registers[13]
`define BD `Cause[31]
`define IP `Cause[15:10]
`define ExcCode `Cause[6:2]

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
            jumpAddress = `EPC;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        `EPC <= 0;
        `PrId <= 32'hDEADBEEF;
        `IE <= 1;
        `EXL <= 0;
        `IM <= 6'b111111;
    end
    else begin
        if (isException) begin
            if (exceptionCause == `causeERET) begin
                `EXL <= 0;
            end
            else begin
                `ExcCode <= exceptionCause;
                `EPC <= exceptionPC;
                `EXL <= 1;
            end
        end
    end
end

endmodule
