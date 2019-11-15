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
    input [5:0] stall,
    //ex阶段存入的多周期数据
    input [1:0] cnt_i,
    // input [`DoubleRegBus] hilo_temp_i,

    output reg [`RegAddrBus] mem_waddr,
    output reg [`RegBus] mem_wdata,
    output reg mem_wreg,
    output reg mem_whilo,
    output reg [`RegBus] mem_hi,
    output reg [`RegBus] mem_lo,
    //输出到ex的多周期数据
    output reg [1:0] cnt_o
    // output reg [`DoubleRegBus] hilo_temp_o
    );
    always @(posedge clk)begin
        if(rst == `RstEna)begin
            mem_waddr <= `NOPRegAddr;
            mem_wdata <= `ZeroWord;
            mem_wreg <= `WriteDisa;
            mem_whilo <= `WriteDisa;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;
            cnt_o <= 2'b00;
            // hilo_temp_o <= {`ZeroWord,`ZeroWord};
        end
        else if(stall[3] == `Stop && stall[4] == `NoStop)begin
            mem_waddr <= `NOPRegAddr;
            mem_wdata <= `ZeroWord;
            mem_wreg <= `WriteDisa;
            mem_whilo <= `WriteDisa;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;
            cnt_o <= cnt_i;         //只有在流水线阻塞的时候才进行赋值
            // hilo_temp_o <= hilo_temp_i;   //其他时候也可以赋值，但是没有意义
        end
        else if(stall[3] == `NoStop)begin   //在乘累加的第二阶段就已经解除阻塞了，也就是在最后一个阶段都需要解除阻塞
            mem_waddr <= ex_waddr;
            mem_wdata <= ex_wdata;
            mem_wreg <= ex_wreg;
            mem_whilo <= ex_whilo;
            mem_hi <= ex_hi;
            mem_lo <= ex_lo;
            cnt_o <= `ZeroWord;     //在这里进行清零操作，每次多周期操作之后都处理一下
            // hilo_temp_o <= `ZeroWord;
        end
        else begin
            // hilo_temp_o <= hilo_temp_i;
            cnt_o <= cnt_i;
        end
    end
endmodule
