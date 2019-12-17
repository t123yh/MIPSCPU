`include "constants.v"
module InstructionMemory(
           input clk,
           input reset,
           input absJump,
           input pcStall,
           input hang,
           input [31:0] absJumpAddress, // In bytes
           output [31:0] outputPC,
           output [31:0] instruction,
           output reg exception,
           output bubble
       );


reg [31:0] memory [4095:0];
wire isHanging;

initial begin
    $readmemh("code.txt", memory);
    $readmemh("code_handler.txt", memory, 1120, 2047);
end

wire [31:0] realAddress = pc - 32'h3000;
reg [31:0] pc;
reg hangState;
assign outputPC = hangState ? 0 : pc;
assign bubble = hangState;
assign instruction = isHanging ? 0 : memory[realAddress[13:2]];
assign isHanging = hang || hangState;

always @(*) begin
    exception = 0;
    if (!hangState) begin
        if (pc >= 32'h5000 || pc < 32'h3000) begin
            exception = 1;
        end
        if (pc[1:0] != 0) begin
            exception = 1;
        end
    end
end

always @(posedge clk) begin
`ifdef DEBUG
    // $display("@%h, delta = %d, instruction = %h", pc, relJumpDelta, instruction);
`endif
    if (reset)
    begin
        pc <= 32'h3000;
        hangState <= 0;
    end
    else begin
        if (pcStall) begin
        end
        else if (absJump) begin
            hangState <= 0;
            pc <= absJumpAddress;
        end
        else begin
            if (hang) begin
                hangState <= 1;
            end
            if (!isHanging) begin
                pc <= pc + 4;
            end
        end
    end
end

always @(*) begin
`ifdef VERBOSE
    $display("PC @ %h", pc);
`endif
end

endmodule
