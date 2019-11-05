`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/05 12:16:33
// Design Name: 
// Module Name: mem_wb
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

module mem_wb(      //这种中间寄存器都是在一个时钟周期之后将数据传过去
    input clk,rst,
    input mem_reg,
    input [`RegAddrBus] mem_waddr,
    input [`RegBus] mem_wdata,

    output reg wb_reg,
    output reg [`RegAddrBus] wb_waddr,
    output reg [`RegBus] wb_wdata
    );
    always @(posedge clk)begin
        if(rst == `RstEna)begin
            wb_reg <= `WriteDisa;
            wb_waddr <= `NOPRegAddr;
            wb_wdata <= `ZeroWord;
        end
        else begin
            wb_reg <= mem_reg;
            wb_waddr <= mem_waddr;
            wb_wdata <= mem_wdata;
        end
    end
endmodule
