module mips(
    input clk,
    input reset,
    input interrupt
);

CPU myFuckingCpuForYouToTest(
        .clk(clk),
        .reset(reset),
        .irq({5'b0, interrupt})
    );

endmodule