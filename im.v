`include "constants.v"
module InstructionMemory(
           input clk,
           input reset,
           input absJump,
           input pcStall,
           input [31:0] absJumpAddress, // In bytes
           output reg [31:0] pc,
           output [31:0] instruction,
           output reg exception
       );


reg [31:0] memory [4095:0];

initial begin
    $readmemh("code.txt", memory);
end

wire [31:0] realAddress = pc - 32'h3000;
assign instruction = memory[realAddress[13:2]];

always @(*) begin
    exception = 0;
    if (pc >= 32'h5000 || pc < 32'h3000) begin
        exception = 1;
    end
    if (pc[1:0] != 0) begin
        exception = 1;
    end
end

always @(posedge clk) begin
`ifdef DEBUG
    // $display("@%h, delta = %d, instruction = %h", pc, relJumpDelta, instruction);
`endif
    if (reset)
    begin
        pc <= 32'h3000;
    end
    else if (pcStall) begin
`ifdef VERBOSE
        $display("Stalled, no instruction.");
`endif

    end
    else if (absJump) begin
`ifdef VERBOSE
        $display("Jump to %h", absJumpAddress);
`endif

        pc <= absJumpAddress;
    end
    else begin
        pc <= pc + 4;
    end
end

always @(*) begin
`ifdef VERBOSE
    $display("PC @ %h", pc);
`endif
end

endmodule
