module mips(
    input clk,
    input reset
);

CPU myFuckingCpuForYouToTest(
        .clk(clk),
        .reset(reset)
    );

endmodule