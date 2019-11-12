`timescale 1ns / 1ps

`include"define.v"

module mem(
    input rst,
    input wreg_i,
    input [`RegAddrBus] waddr_i,
    input [`RegBus] wdata_i,
    input [`RegBus] hi_i,
    input [`RegBus] lo_i,
    input whilo_i,

    output reg wreg_o,
    output reg [`RegAddrBus] waddr_o,
    output reg [`RegBus] wdata_o,
    output reg [`RegBus] hi_o,
    output reg [`RegBus] lo_o,
    output reg whilo_o
    );
    always @(*)begin
        if(rst == `RstEna)begin
            wreg_o <= `WriteDisa;
            waddr_o <= `NOPRegAddr;
            wdata_o <= `ZeroWord;
            whilo_o <= `WriteDisa;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
        else begin
            wreg_o <= wreg_i;
            waddr_o <= waddr_i;
            wdata_o <= wdata_i;
            whilo_o <= whilo_i;
            hi_o <= hi_i;
            lo_o <= lo_i;
        end
    end
endmodule
