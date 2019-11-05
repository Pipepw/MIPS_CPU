`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/05 19:05:52
// Design Name: 
// Module Name: min_sopc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include"define.v"

module min_sopc(
    input clk,
    input rst
    );

    //指令存储器的输出，cpu的输入
    wire [`InstBus] inst;

    //cpu的输出，rom的输入
    wire ce;
    wire [`RegAddrBus] addr;

    //inst_rom的实例化
    inst_rom(
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
