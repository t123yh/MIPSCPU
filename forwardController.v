`include "constants.v"
module ForwardController (
           input [4:0] request,
           input [31:0] original,
           input enabled,
           input [31:0] debugPC,
           input [7:0] debugStage,
           output reg [31:0] value,
           output stallExec,

           // priority: src1 > src2
           input src1Valid,
           input [4:0] src1Reg,
           input [31:0] src1Value,

           input src2Valid,
           input [4:0] src2Reg,
           input [31:0] src2Value,

           input src3Valid,
           input [4:0] src3Reg,
           input [31:0] src3Value
       );

initial begin
`ifdef DEBUG
    $dumpvars(0, enabled);
    $dumpvars(0, request);
    $dumpvars(0, value);
    $dumpvars(0, original);
    $dumpvars(0, stallExec);
    $dumpvars(0, src1Valid);
    $dumpvars(0, src1Reg);
    $dumpvars(0, src2Valid);
    $dumpvars(0, src2Reg);
    $dumpvars(0, src2Value);
    $dumpvars(0, src3Valid);
    $dumpvars(0, src3Reg);
`endif
end

reg stall;
assign stallExec = stall & enabled;

always @(*) begin
    if (request == 0 || enabled == 0) begin
        value = 0;
`ifdef DEBUG

        if (!enabled)
            value = 'bx;
`endif

        stall = 0;
    end
    else if (src1Reg == request) begin
        if (!src1Valid) begin
            stall = 1;
`ifdef VERBOSE

            $display("%c@%h, Requested %d, src1 not available, stalling", debugStage, debugPC, request);
`endif

        end
        else begin
`ifdef VERBOSE
            $display("%c@%h, Requested for %d, forwarding from src1",debugStage, debugPC, request);
`endif

            stall = 0;
            value = src1Value;
        end
    end
    else if (src2Reg == request) begin
        if (!src2Valid) begin
            stall = 1;
`ifdef VERBOSE

            $display("%c@%h, Requested for %d, src2 not available, stalling", debugStage, debugPC, request);
`endif

        end
        else begin
`ifdef VERBOSE
            $display("%c@%h, Requested for %d, forwarding from src2", debugStage, debugPC, request);
`endif

            stall = 0;
            value = src2Value;
        end
    end
    else if (src3Reg == request) begin
        if (!src3Valid) begin
            stall = 1;
`ifdef VERBOSE

            $display("%c@%h, Requested for %d, src3 not available, stalling", debugStage, debugPC, request);
`endif

        end
        else begin
`ifdef VERBOSE
            $display("%c@%h, Requested for %d, forwarding from src3", debugStage, debugPC, request);
`endif

            stall = 0;
            value = src3Value;
        end
    end
    else begin
`ifdef VERBOSE
        $display("%0t, %c@%h, Requested for %d, not forwarding, %h", $time, debugStage, debugPC, request, original);
`endif

        value = original;
        stall = 0;
    end
end

endmodule
