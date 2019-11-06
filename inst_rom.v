`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/05 18:29:46
// Design Name: 
// Module Name: inst__rom
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

module inst_rom(
    input ce,
    input [`InstAddrBus]addr,
    output reg [`InstBus] inst
    );
    reg [`InstBus] inst_mem[0:`InstMemNum-1];
    initial $readmemh("C:/Users/Pipe/Documents/CPU/CPU/CPU.srcs/sources_1/inst_mem.data",inst_mem);
    always @(*)begin
        if(ce == `ChipDisa)begin
            inst <= `ZeroWord;
        end
        else begin
            //之所以到2，是因为MIPS是按字节寻址的，而指令的地址是位，所以要除以4，也就是右移两位
            inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
        end
    end
endmodule
