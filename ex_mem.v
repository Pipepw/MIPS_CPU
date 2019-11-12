`timescale 1ns / 1ps

`include"define.v"

module ex_mem(
    input clk,rst,
    input [`RegAddrBus] ex_waddr,
    input [`RegBus] ex_wdata,
    input ex_wreg,
    input ex_whilo,
    input [`RegBus] ex_hi,
    input [`RegBus] ex_lo,

    output reg [`RegAddrBus] mem_waddr,
    output reg [`RegBus] mem_wdata,
    output reg mem_wreg,
    output reg mem_whilo,
    output reg [`RegBus] mem_hi,
    output reg [`RegBus] mem_lo
    );
    always @(posedge clk)begin
        if(rst == `RstEna)begin
            mem_waddr <= `NOPRegAddr;
            mem_wdata <= `ZeroWord;
            mem_wreg <= `WriteDisa;
            mem_whilo <= `WriteDisa;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;
        end
        else begin
            mem_waddr <= ex_waddr;
            mem_wdata <= ex_wdata;
            mem_wreg <= ex_wreg;
            mem_whilo <= ex_whilo;
            mem_hi <= ex_hi;
            mem_lo <= ex_lo;
        end
    end
endmodule
