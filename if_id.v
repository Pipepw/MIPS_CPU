`timescale 1ns / 1ps

`include "define.v"

module if_id(
    input clk,
    input rst,
    //来自取指阶段的信号
    input [`InstAddrBus] if_pc,//取指阶段的地址
    input [`InstBus] if_inst,//取指阶段的指令
    //对应译码阶段的信号
    output reg[`InstAddrBus] id_pc,//译码阶段的地址
    output reg[`InstBus] id_inst//译码阶段的指令
    );
    always @(posedge clk)begin
        if(rst==`RstEna)begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
        end
        else begin
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
    end
endmodule
