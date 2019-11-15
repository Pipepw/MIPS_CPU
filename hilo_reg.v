`timescale 1ns / 1ps

`include "define.v"

module hilo_reg(
    input clk,
    input rst,
    input we,
    input [`RegBus] hi_i,
    input [`RegBus] lo_i,

    output reg [`RegBus] hi_o,
    output reg [`RegBus] lo_o
    );

    always@(*)begin
        if(rst == `RstEna)begin
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
        else if(we == `WriteEna)begin
            hi_o <= hi_i;
            lo_o <= lo_i;
        end
    end
endmodule
