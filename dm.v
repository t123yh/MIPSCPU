module DataMemory(
           input clk,
           input reset,
           input writeEnable,
           input [31:0] address,
           input [31:0] writeData,
           output [31:0] readData,
           input [31:0] debugPC
       );

reg [31:0] memory [1023:0];

wire [9:0] realAddress = address[11:2];
assign readData = memory[realAddress];

integer i;
always @(posedge clk) begin
    if (reset) begin
        for (i = 0; i < 1024; i = i + 1) begin
            memory[i] <= 0;
        end
    end
    else if (writeEnable) begin
        $display("@%h: *%h <= %h", debugPC, address, writeData);
        memory[realAddress] <= writeData;
    end
end


endmodule
