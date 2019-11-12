`timescale 1ns / 1ps

`include"define.v"

module mem_wb(      //这种中间寄存器都是在一个时钟周期之后将数据传过去
    input clk,rst,
    input mem_reg,
    input [`RegAddrBus] mem_waddr,
    input [`RegBus] mem_wdata,
    input mem_whilo,
    input [`RegBus] mem_hi,
    input [`RegBus] mem_lo,

    output reg wb_reg,
    output reg [`RegAddrBus] wb_waddr,
    output reg [`RegBus] wb_wdata,
    output reg wb_whilo,
    output reg [`RegBus] wb_hi,
    output reg [`RegBus] wb_lo
    );
    always @(posedge clk)begin
        if(rst == `RstEna)begin
            wb_reg <= `WriteDisa;
            wb_waddr <= `NOPRegAddr;
            wb_wdata <= `ZeroWord;
            wb_whilo <= `WriteDisa;
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
        end
        else begin
            wb_reg <= mem_reg;
            wb_waddr <= mem_waddr;
            wb_wdata <= mem_wdata;
            wb_whilo <= mem_whilo;
            wb_hi <= mem_hi;
            wb_lo <= mem_lo;
        end
    end
endmodule
