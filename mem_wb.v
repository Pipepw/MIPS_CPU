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
    input [5:0] stall,
    input mem_LLbit_we,
    input mem_LLbit_value,
    input [`RegBus] mem_cp0_reg_data,
    input [`RegAddrBus] mem_cp0_reg_write_addr,
    input mem_cp0_reg_we,

    output reg wb_reg,
    output reg [`RegAddrBus] wb_waddr,
    output reg [`RegBus] wb_wdata,
    output reg wb_whilo,
    output reg [`RegBus] wb_hi,
    output reg [`RegBus] wb_lo,
    output reg wb_LLbit_we,
    output reg wb_LLbit_value,
    output reg [`RegBus] wb_cp0_reg_data,
    output reg [`RegAddrBus] wb_cp0_reg_write_addr,
    output reg wb_cp0_reg_we
    );
    always @(posedge clk)begin
        if(rst == `RstEna)begin
            wb_reg <= `WriteDisa;
            wb_waddr <= `NOPRegAddr;
            wb_wdata <= `ZeroWord;
            wb_whilo <= `WriteDisa;
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_LLbit_we <= 1'b0;
            wb_LLbit_value <= 1'b0;
            wb_cp0_reg_data <= `ZeroWord;
            wb_cp0_reg_write_addr <= 5'b0;
            wb_cp0_reg_we <= 1'b0;
        end
        //很典型的一种情况，下一个周期是单周期的操作，所以需要在其执行完之后输入空指令，否则会出现重复运行的情况
        else if(stall[4] == `Stop && stall[5] == `NoStop)begin
            wb_reg <= `WriteDisa;
            wb_waddr <= `NOPRegAddr;
            wb_wdata <= `ZeroWord;
            wb_whilo <= `WriteDisa;
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_LLbit_we <= 1'b0;
            wb_LLbit_value <= 1'b0;
            wb_cp0_reg_data <= `ZeroWord;
            wb_cp0_reg_write_addr <= 5'b0;
            wb_cp0_reg_we <= 1'b0;
        end
        else if(stall[4] == `NoStop)begin
            wb_reg <= mem_reg;
            wb_waddr <= mem_waddr;
            wb_wdata <= mem_wdata;
            wb_whilo <= mem_whilo;
            wb_hi <= mem_hi;
            wb_lo <= mem_lo;
            wb_LLbit_we <= mem_LLbit_we;
            wb_LLbit_value <= mem_LLbit_value;
            wb_cp0_reg_data <= mem_cp0_reg_data;
            wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
            wb_cp0_reg_we <= mem_cp0_reg_we;
        end
    end
endmodule
