`include "constants.v"
module DataMemory(
           input clk,
           input reset,
           input writeEnable,
           input readEnable,
           input [1:0] widthCtrl,
           input [31:0] address,
           input [31:0] writeDataIn,
           input [31:0] debugPC,
           output exception,

    output data_sram_en,
    output logic [3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata
       );

assign data_sram_addr = address & 32'h1FFFFFFF;
assign data_sram_en = readEnable || writeEnable;

logic addressException;
assign exception = addressException;
always_comb begin
    addressException = 0;
    if (widthCtrl == `memWidth4) begin
        if (address[1:0] != 0) begin
            addressException = 1;
        end
    end
    else if (widthCtrl == `memWidth2) begin
        if (address[0] != 0) begin
            addressException = 1;
        end
    end
end

logic [31:0] writeData;
assign data_sram_wdata = writeData;

always_comb begin
    writeData = 0;
    data_sram_wen = 4'b0000;
    if (!addressException && writeEnable) begin
        if (widthCtrl == `memWidth4) begin
            writeData = writeDataIn;
            data_sram_wen = 4'b1111;
        end
        else if (widthCtrl == `memWidth2) begin
            if (address[1] == 1) begin
                writeData = {writeDataIn[15:0], 16'b0};
                data_sram_wen = 4'b1100;
            end
            else begin
                writeData = {16'b0, writeDataIn[15:0]};
                data_sram_wen = 4'b0011;
            end
        end
        else if (widthCtrl == `memWidth1) begin
            if (address[1:0] == 3) begin
                writeData = {writeDataIn[7:0], 24'b0};
                data_sram_wen = 4'b1000;
            end
            else if (address[1:0] == 2) begin
                writeData = {8'b0, writeDataIn[7:0], 16'b0};
                data_sram_wen = 4'b0100;
            end
            else if (address[1:0] == 1) begin
                writeData = {16'b0, writeDataIn[7:0], 8'b0};
                data_sram_wen = 4'b0010;
            end
            else begin
                writeData = {24'b0, writeDataIn[7:0]};
                data_sram_wen = 4'b0001;
            end
        end
    end
end

endmodule
