
module RAM(
           input clk,
           input reset,
           input writeEnable,
           input readEnable,
           input [13:0] address,
           input [31:0] writeDataIn,
           input [31:0] debugPC,
           output reg [31:0] readData,
           output exception
       );
reg [31:0] memory [4095:0];
wire [11:0] realAddress = address[13:2];
always @(*) begin
    readData = 'bx;
    if (readEnable) begin
        readData = memory[realAddress];
    end
end

// assign exception = address == 16'h0008; // For testing purpose
assign exception = 0;

integer i;
always @(posedge clk) begin
    if (reset) begin
        for (i = 0; i < 4096; i = i + 1) begin
            memory[i] <= 0;
        end
    end
    else if (writeEnable) begin
        memory[realAddress] <= writeDataIn;
    end
end

always @(posedge clk) begin
    if (writeEnable && !exception) begin
        $display("%d@%h: *%h <= %h", $time, debugPC,{18'b0, realAddress, 2'b0}, writeDataIn);
    end
end

endmodule
