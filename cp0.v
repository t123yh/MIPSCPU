`include "constants.v"

module CP0(
           input clk,
           input reset,
           input writeEnable,
           input [4:0] number,
           input [31:0] writeData,
           output [31:0] readData,

           input hasExceptionInPipeline,

           input isBD,
           input isException,
           input [4:0] exceptionCause,
           input [31:0] exceptionPC,
           input [31:0] exceptionBadVAddr,

           output reg jump,
           output reg [31:0] jumpAddress,

           output interruptNow,
           input [15:10] externalInterrupt
       );

wire [31:0] exceptionHandler = 32'hBFC00380;

reg [31:0] registers [15:0];

`define CauseNumber 13
`define CompareNumber 11
`define CountNumber 9

assign readData = registers[number];

`define EPC registers[14]
`define PrId registers[15]
`define SR registers[12]
`define EXL `SR[1]
`define IE `SR[0]
`define IM `SR[15:8]
`define Cause registers[13]
`define BD `Cause[31]
`define IP `Cause[15:8]
`define ExcCode `Cause[6:2]
`define BadVAddr registers[8]
`define Count registers[`CountNumber]
`define Compare registers[`CompareNumber]

assign BDReg = `BD;
wire EXLReg = `EXL;
wire [4:0] ExcCodeReg = `ExcCode;
wire [31:0] EPCReg = `EPC;

always @(*) begin
    jump = 0;
    jumpAddress = 'bx;
    if (isException) begin
        jump = 1;
        if (exceptionCause == `causeERET) begin
            jumpAddress = `EPC;
        end
        else if (exceptionCause != `causeERET) begin
            jumpAddress = exceptionHandler;
        end
    end
end
integer i;
initial begin
    for (i = 0; i < 16; i = i + 1) begin
        registers[i] = 32'b0;
    end
end

reg timerInterrupt, clearTimerInterrupt;
wire [15:8] interruptSource = {timerInterrupt, externalInterrupt[14:10], `Cause[9:8]};
wire interruptEnabled = `IE && !`EXL && !hasExceptionInPipeline;
wire [15:8] unmaskedInterrupt = interruptEnabled ? (interruptSource & `IM) : 0;
wire hasInterrupt = | unmaskedInterrupt;

reg pendingInterrupt;
assign interruptNow = hasInterrupt;


always @(posedge clk) begin
    if (reset) begin
        timerInterrupt <= 0;
    end
    else begin
        if (clearTimerInterrupt) begin
            timerInterrupt <= 0;
        end
        else begin
            if (`Count == `Compare && `Compare != 32'b0) begin
                timerInterrupt <= 1;
            end
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        `EPC <= 0;
        `PrId <= 32'hDEADBEEF;
        `IE <= 0;
        `EXL <= 1;
        `IM <= 6'b111111;
        // interruptSource <= 0;
        pendingInterrupt <= 0;
        clearTimerInterrupt <= 0;
    end
    else begin
        if (isException || !writeEnable || number != `CountNumber) begin
            `Count <= `Count + 1;
        end

        // interruptSource <= externalInterrupt;
        if (hasInterrupt) begin
            pendingInterrupt <= 1;
        end
        else if (pendingInterrupt) begin
            if (`EXL) begin
                pendingInterrupt <= 0;
            end
        end
        if (isException) begin
            if (`EXL) begin
                if (exceptionCause == `causeERET) begin
                    `EXL <= 0;
                end
            end
            else begin
                if (exceptionCause != `causeERET) begin
                    `BadVAddr <= exceptionBadVAddr;
                    `BD <= isBD;
                    `ExcCode <= exceptionCause;
                    if (isBD) begin
                        `EPC <= exceptionPC - 4;
                    end
                    else begin
                        `EPC <= exceptionPC;
                    end
                    `EXL <= 1;
                end
            end
        end
        else begin
            if (writeEnable) begin
                if (number == `CauseNumber) begin // Cause
                    `Cause[31:16] <= writeData[31:16];
                    `Cause[9:0] <= writeData[9:0];
                end
                else begin
                    registers[number] <= writeData;
                end
            end

            `Cause[15:10] <= externalInterrupt[15:10];

            if (writeEnable && number == `CompareNumber) begin
                clearTimerInterrupt <= 1;
            end else if (clearTimerInterrupt) begin
                clearTimerInterrupt <= 0;
            end
        end
    end
end

endmodule
