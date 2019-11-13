`include "constants.v"
module CPU (
           input clk,
           input reset
       );

reg branchDecision;

always @(*) begin
    branchDecision = 0;
    if (ctrl.branch && alu.out == 0) begin
        branchDecision = 1;
    end
end

ArithmeticLogicUnit alu(
                        .ctrl(ctrl.aluCtrl),
                        .A(grf.readOutput1),
                        .B(ctrl.aluSrc ? ctrl.immediate : grf.readOutput2)
                    );

InstructionMemory im(
                      .clk(clk),
                      .reset(reset),
                      .absJump(ctrl.absJump),
                      .absJumpAddress(ctrl.absJumpLoc ? {im.pc[31:28], ctrl.immediate[25:0], 2'b00} : grf.readOutput1),
                      .relJumpDelta(branchDecision ? ctrl.immediate[15:0] : 16'b0)
                  );

DataMemory dm(
               .clk(clk),
               .reset(reset),
               .debugPC(im.pc),
               .writeEnable(ctrl.memStore),
               .address(alu.out),
               .writeData(grf.readOutput2) // register@rt
           );

reg [31:0] grfWriteData;
GeneralRegisterFile grf(
                        .clk(clk),
                        .reset(reset),
                        .writeEnable(ctrl.grfWriteSource != `grfWriteDisable),
                        .writeData(grfWriteData),
                        .readAddress1(ctrl.rs),
                        .readAddress2(ctrl.rt),
                        .writeAddress(ctrl.destinationRegister),
                        .debugPC(im.pc)
                    );
always @(*) begin
    case (ctrl.grfWriteSource)
        `grfWriteDisable:
            grfWriteData = 0;
        `grfWriteALU:
            grfWriteData = alu.out;
        `grfWriteMem:
            grfWriteData = dm.readData;
        `grfWritePC:
            grfWriteData = im.pc + 4;
    endcase
end

Controller ctrl(
               .instruction(im.instruction),
               .debugPC(im.pc)
           );

endmodule
