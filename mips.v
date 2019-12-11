module mips(
    input clk,
    input reset,
    input interrupt,
    output [31:0] addr
);

TC tc0(
    .clk(clk),
    .reset(reset),
    .Addr(cpu.sb_Address[31:2])
);

TC tc1(
    .clk(clk),
    .reset(reset),
    .Addr(cpu.sb_Address[31:2])
);

SystemBridge sb(
    .clk(clk),
    .reset(reset),

    .writeEnable(cpu.sb_WriteEnable),
    .readEnable(cpu.sb_ReadEnable),
    .address(cpu.sb_Address),
    .writeDataIn(cpu.sb_DataIn),
    .readData(cpu.sb_DataOut),
    .exception(cpu.sb_exception),
    
    .WE0(tc0.WE),
    .TC0BIPO(tc0.Dout),
    .TC0BOPI(tc0.Din),

    .WE1(tc1.WE),
    .TC1BIPO(tc1.Dout),
    .TC1BOPI(tc1.Din)
);

CPU cpu(
        .clk(clk),
        .reset(reset),
        .irq({3'b0, interrupt, tc1.IRQ, tc0.IRQ}),
        .effectivePC(addr)
    );

endmodule