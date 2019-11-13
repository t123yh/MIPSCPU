`include "constants.v"
module InstructionMemory(
           input clk,
           input reset,
           input absJump,
           input [31:0] absJumpAddress, // In bytes
           input [15:0] relJumpDelta, // In words
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
        $display("@%h, delta = %d, instruction = %h", pc, relJumpDelta, instruction);
    `endif
    if (reset) begin
        internalCounter <= 0;
    end
    else if (absJump) begin
        `ifdef DEBUG
            $display("Jump to %h", { absJumpAddress[11:2], 2'b00 });
        `endif
        internalCounter <= absJumpAddress[11:2];
    end
    else begin
        internalCounter <= internalCounter + 1 + relJumpDelta[9:0];
    end
end

endmodule
