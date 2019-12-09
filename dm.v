`include "constants.v"
module DataMemory(
           input clk,
           input reset,
           input writeEnable,
           input [1:0] widthCtrl,
           input extendCtrl,
           input [31:0] address,
           input [31:0] writeDataIn,
           output reg [31:0] readData,
           input [31:0] debugPC,
           output reg exception
       );

reg [31:0] memory [4095:0];

wire [11:0] realAddress = address[13:2];
reg [15:0] halfWord;
reg [7:0] byte;
always @(*) begin
    exception = 0;
    readData = 0;
    if (memory[realAddress] >= 32'h3000) begin
        exception = 1;
    end
    if (widthCtrl == `memWidth4) begin
        if (address[1:0] != 0) begin
            exception = 1;
        end
        readData = memory[realAddress];
    end
    else if (widthCtrl == `memWidth2) begin
        if (address[0] != 0) begin
            exception = 1;
        end
        if (address[1]) begin
            halfWord = memory[realAddress][31:16];
        end
        else begin
            halfWord = memory[realAddress][15:0];
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
            byte = memory[realAddress][31:24];
        end
        else if (address[1:0] == 2) begin
            byte = memory[realAddress][23:16];
        end
        else if (address[1:0] == 1) begin
            byte = memory[realAddress][15:8];
        end
        else if (address[1:0] == 0) begin
            byte = memory[realAddress][7:0];
        end
        if (extendCtrl) begin
            readData = $signed(byte);
        end
        else begin
            readData = byte;
        end
    end
end

reg [31:0] writeData;

always @(*) begin
    writeData = 0;
    if (widthCtrl == `memWidth4) begin
        writeData = writeDataIn;
    end
    else if (widthCtrl == `memWidth2) begin
        if (address[1] == 1) begin
            writeData = {writeDataIn[15:0], memory[realAddress][15:0]};
        end
        else begin
            writeData = {memory[realAddress][31:16], writeDataIn[15:0]};
        end
    end
    else if (widthCtrl == `memWidth1) begin
        if (address[1:0] == 3) begin
            writeData = {writeDataIn[7:0], memory[realAddress][23:0]};
        end
        else if (address[1:0] == 2) begin
            writeData = {memory[realAddress][31:24], writeDataIn[7:0], memory[realAddress][15:0]};
        end
        else if (address[1:0] == 1) begin
            writeData = {memory[realAddress][31:16], writeDataIn[7:0], memory[realAddress][7:0]};
        end
        else begin
            writeData = {memory[realAddress][31:8], writeDataIn[7:0]};
        end
    end
end

integer i;
always @(posedge clk) begin
    if (reset) begin
        for (i = 0; i < 1024; i = i + 1) begin
            memory[i] <= 0;
        end
    end
    else if (writeEnable) begin
`ifdef DEBUG
        $display("@%h: *%h <= %h", debugPC, {18'h0, realAddress, 2'b0}, writeData);
`else
        $display("%d@%h: *%h <= %h", $time, debugPC,{18'h0, realAddress, 2'b0}, writeData);
`endif

        memory[realAddress] <= writeData;
    end
end


endmodule
