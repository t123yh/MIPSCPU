`include "constants.v"
module DataMemory(
           input clk,
           input reset,
           input writeEnable,
           input [1:0] widthCtrl,
           input readEnable,
           input extendCtrl,
           input [31:0] address,
           input [31:0] writeDataIn,
           output reg [31:0] readData,
           input [31:0] debugPC,
           output reg exception,

           output sb_WriteEnable,
           output sb_ReadEnable,
           output [31:0] sb_Address,
           output [31:0] sb_DataIn,
           input [31:0] sb_DataOut,
           input sb_exception
       );

reg chipSelect_RAM, chipSelect_SB;
reg [31:0] readWord;
reg [31:0] writeWord;

assign sb_WriteEnable = chipSelect_SB && writeEnable;
assign sb_ReadEnable = chipSelect_SB;
assign sb_Address = address;
assign sb_DataIn = writeDataIn;

RAM ram(
        .clk(clk),
        .reset(reset),
        .address(address[13:0]),
        .readEnable(chipSelect_RAM),
        .writeEnable(chipSelect_RAM && writeEnable),
        .writeDataIn(writeWord),
        .debugPC(debugPC)
    );

reg [15:0] halfWord;
reg [7:0] byte;
always @(*) begin
    readData = 0;
    writeWord = 0;
    if (widthCtrl == `memWidth4) begin
        readData = readWord;
        writeWord = writeDataIn;
    end
    else if (widthCtrl == `memWidth2) begin
        if (address[1]) begin
            halfWord = readWord[31:16];
            writeWord = {writeDataIn[15:0], readWord[15:0]};
        end
        else begin
            halfWord = readWord[15:0];
            writeWord = {readWord[31:16], writeDataIn[15:0]};
        end
        if (extendCtrl) begin
            readData = $signed(halfWord);
        end
        else begin
            readData = halfWord;
        end
    end
    else if (widthCtrl == `memWidth1) begin
        if (address[1:0] == 3) begin
            byte = readWord[31:24];
            writeWord = {writeDataIn[7:0], readWord[23:0]};
        end
        else if (address[1:0] == 2) begin
            byte = readWord[23:16];
            writeWord = {readWord[31:24], writeDataIn[7:0], readWord[15:0]};
        end
        else if (address[1:0] == 1) begin
            byte = readWord[15:8];
            writeWord = {readWord[31:16], writeDataIn[7:0], readWord[7:0]};
        end
        else if (address[1:0] == 0) begin
            byte = readWord[7:0];
            writeWord = {readWord[31:8], writeDataIn[7:0]};
        end
        if (extendCtrl) begin
            readData = $signed(byte);
        end
        else begin
            readData = byte;
        end
    end
end

reg addressException;
always @(*) begin
    chipSelect_RAM = 0;
    chipSelect_SB = 0;
    addressException = 0;
    if (address < 16'h3000) begin
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
        if (!addressException) begin
            chipSelect_RAM = 1;
        end
    end
    else if (address >= 16'h7F00 && address < 16'h7F20) begin
        if (widthCtrl == `memWidth4) begin
            if (address[1:0] != 0) begin
                addressException = 1;
            end
        end
        else begin
            addressException = 1;
        end
        if (!addressException) begin
            chipSelect_SB = 1;
        end
    end
    else begin
        addressException = 1;
    end
end

always @(*) begin
    readWord = 'bx;
    if(chipSelect_RAM) begin
        readWord = ram.readData;
    end
    else if (chipSelect_SB) begin
        readWord = sb_DataOut;
    end
end

always @(*) begin
    exception = 0;
    if (readEnable || writeEnable) begin
        exception = addressException || (chipSelect_RAM && ram.exception) || (chipSelect_SB && sb_exception);
    end
end

endmodule
