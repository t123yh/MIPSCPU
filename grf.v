module GeneralRegisterFile(
    input [4:0] readAddress1,
    output [31:0] readOutput1,
    input [4:0] readAddress2,
    output [31:0] readOutput2,
    input [4:0] writeAddress,
    input [31:0] writeData,
    input writeEnable,
    input clk,
    input reset,
    input [31:0] debugPC
);

reg [31:0] registers [31:0];

assign readOutput1 = registers[readAddress1];
assign readOutput2 = registers[readAddress2];

integer i;
always @(posedge clk) begin
    if (reset) begin
        for (i = 0; i <= 31; i = i + 1) begin
            registers[i] <= 0;
        end
    end else begin
        if (writeEnable && writeAddress != 0) begin
            $display("@%h: $%d <= %h", debugPC, writeAddress, writeData);
            registers[writeAddress] <= writeData;
        end
    end
end

endmodule