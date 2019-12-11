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
           output reg exception
       );

reg chipSelect_RAM;
reg [31:0] readWord;
reg [31:0] writeWord;

RAM ram(
        .clk(clk),
        .reset(reset),
        .address(address[13:0]),
        .readEnable(chipSelect_RAM),
        .writeEnable(chipSelect_RAM && writeEnable),
        .writeDataIn(writeWord)
    );

reg [15:0] halfWord;
reg [7:0] byte;
reg alignException;
always @(*) begin
    alignException = 0;
    readData = 0;
    writeWord = 0;
    if (widthCtrl == `memWidth4) begin
        if (address[1:0] != 0) begin
            alignException = 1;
        end
        readData = readWord;
        writeWord = writeDataIn;
    end
    else if (widthCtrl == `memWidth2) begin
        if (address[0] != 0) begin
            alignException = 1;
        end
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
    addressException = 1;
    if (address < 16'h3000) begin
        chipSelect_RAM = 1;
        addressException = 0;
    end
end

always @(*) begin
    readWord = 'bx;
    if(chipSelect_RAM) begin
        readWord = ram.readData;
    end
end

always @(*) begin
    exception = 0;
    if (readEnable || writeEnable) begin
        exception = alignException || addressException || (chipSelect_RAM && ram.exception);
    end
end

always @(posedge clk) begin
    if (writeEnable) begin
        $display("%d@%h: *%h <= %h", $time, debugPC,{address[31:2], 2'b0}, writeWord);
    end
end

endmodule
