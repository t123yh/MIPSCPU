`include "constants.v"
module InstructionMemory(
           input clk,
           input reset,
           input absJump,
           input pcStall,
           input [31:0] absJumpAddress, // In bytes
           output [31:0] pc,
           output [31:0] instruction
       );


reg [31:0] memory [1023:0];

initial begin
    $readmemh("code.txt", memory);
end

reg [9:0] internalCounter;
assign pc = {20'b11, internalCounter, 2'b0};
assign instruction = memory[internalCounter];

always @(posedge clk) begin
`ifdef DEBUG
    // $display("@%h, delta = %d, instruction = %h", pc, relJumpDelta, instruction);
`endif
    if (reset)
    begin
        internalCounter <= 0;
    end
    else if (pcStall) begin
`ifdef VERBOSE
        $display("Stalled, no instruction.");
`endif

    end
    else if (absJump) begin
`ifdef VERBOSE
        $display("Jump to %h", { absJumpAddress[11:2], 2'b00 });
`endif

        internalCounter <= absJumpAddress[11:2];
    end
    else begin
        internalCounter <= internalCounter + 1;
    end
end

always @(*) begin
`ifdef VERBOSE
    $display("PC @ %h", internalCounter << 2);
`endif
end

endmodule
