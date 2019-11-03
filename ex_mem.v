`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/03 14:57:40
// Design Name: 
// Module Name: ex_mem
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

module ex_mem(
    input clk,rst,
    input [`RegAddrBus] ex_waddr,
    input [`RegBus] ex_wdata,
    input ex_wreg,

    output reg [`RegAddrBus] mem_waddr,
    output reg [`RegBus] mem_wdata,
    output reg mem_wreg
    );
    always @(posedge clk)begin
        if(rst == `RstEna)begin
            mem_waddr <= `NOPRegAddr;
            mem_wdata <= `ZeroWord;
            mem_wreg <= `WriteDisa;
        end
        else begin
            mem_waddr <= ex_waddr;
            mem_wdata <= ex_wdata;
            mem_wreg <= ex_wreg;
        end
    end
endmodule
