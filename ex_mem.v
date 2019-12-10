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
    input [`AluOpBus] ex_aluop,
    input [`RegBus] ex_mem_addr,
    input [`RegBus] ex_reg2,
    //协处理器
    input [`RegBus] ex_cp0_reg_data,
    input [`RegAddrBus] ex_cp0_reg_write_addr,
    input ex_cp0_reg_we,

    output reg [`RegAddrBus] mem_waddr,
    output reg [`RegBus] mem_wdata,
    output reg mem_wreg,
    output reg mem_whilo,
    output reg [`RegBus] mem_hi,
    output reg [`RegBus] mem_lo,
    //输出到ex的多周期数据
    output reg [1:0] cnt_o,
    // output reg [`DoubleRegBus] hilo_temp_o
    output reg [`AluOpBus] mem_aluop,
    output reg [`RegBus] mem_mem_addr,
    output reg [`RegBus] mem_reg2,
    //协处理器
    output reg [`RegBus] mem_cp0_reg_data,
    output reg [`RegAddrBus] mem_cp0_reg_write_addr,
    output reg mem_cp0_reg_we
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
            mem_aluop <= `EXE_NOP_OP;
            mem_mem_addr <= `ZeroWord;
            mem_reg2 <= `ZeroWord;
            mem_cp0_reg_data <= `ZeroWord;
            mem_cp0_reg_write_addr <= 5'b0;
            mem_cp0_reg_we <= 1'b0;
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
            mem_aluop <= `EXE_NOP_OP;
            mem_mem_addr <= `ZeroWord;
            mem_reg2 <= `ZeroWord;
            mem_cp0_reg_data <= `ZeroWord;
            mem_cp0_reg_write_addr <= 5'b0;
            mem_cp0_reg_we <= 1'b0;
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
            mem_aluop <= ex_aluop;
            mem_mem_addr <= ex_mem_addr;
            mem_reg2 <= ex_reg2;
            mem_cp0_reg_data <= ex_cp0_reg_data;
            mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
            mem_cp0_reg_we <= ex_cp0_reg_we;
        end
        else begin
            // hilo_temp_o <= hilo_temp_i;
            cnt_o <= cnt_i;
        end
    end
endmodule
