`timescale 1ns / 1ps

`include"define.v"
`include"cpu.v"
`include"inst_rom.v"

module min_sopc(
    input clk,
    input rst
    );

    //指令存储器的输出，cpu的输入
    wire [`InstBus] inst;

    //cpu的输出，rom的输入
    wire ce;
    wire [`InstAddrBus] addr;

    //inst_rom的实例化
    inst_rom inst_rom0(
        .ce(ce),
        .addr(addr),
        .inst(inst)
    );

    //cpu的实例化
    cpu cpu0(
        .clk(clk),
        .rst(rst),
        .rom_data_i(inst),
        .rom_ce_o(ce),
        .rom_addr_o(addr)
    );
endmodule
