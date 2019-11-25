`timescale 1ns / 1ps

`include"define.v"


module min_sopc(
    input clk,
    input rst
    );

    //指令存储器的输出，cpu的输入
    wire [`InstBus] inst;
    wire [`InstAddrBus] rom_addr;
    wire rom_ce;
    //用于ram
    wire [`DataAddrBus] ram_addr;
    wire ram_ce;
    wire [3:0] sel;
    wire [`DataBus] ram_data_i;
    wire [`DataBus] ram_data_o;
    wire we;

    //inst_rom的实例化
    inst_rom inst_rom0(
        .ce(rom_ce),
        .addr(rom_addr),
        .inst(inst)
    );

    //cpu的实例化
    cpu cpu0(
        .clk(clk),
        .rst(rst),
        //与inst_rom之间
        .rom_data_i(inst),
        .rom_ce_o(rom_ce),
        .rom_addr_o(rom_addr),
        //与data_ram之间
        .ram_data_o(ram_data_o),
        .ram_data_i(ram_data_i),
        .ram_addr_i(ram_addr),
        .ram_we_i(we),
        .ram_sel_i(sel),
        .ram_ce_i(ram_ce)
    );

    //data_ram的实例化
    data_ram data_ram0(
        .clk(clk),
        .ce(ram_ce),
        .data_i(ram_data_i),
        .addr(ram_addr),
        .we(we),
        .sel(sel),
        .data_o(ram_data_o)
    );
endmodule
