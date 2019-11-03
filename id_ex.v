`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/03 08:57:53
// Design Name: 
// Module Name: id_ex
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

module id_ex(
    input clk,rst,
    input [`AluSelBus] id_alusel,
    input [`AluOpBus] id_aluop,
    input id_wreg,
    input [`RegAddrBus] id_waddr,
    input [`RegBus] id_reg1,
    input [`RegBus] id_reg2,

    output reg [`AluSelBus] ex_alusel,
    output reg [`AluOpBus] ex_aluop,
    output reg ex_wreg,
    output reg [`RegAddrBus] ex_waddr,
    output reg [`RegBus] ex_reg1,
    output reg [`RegBus] ex_reg2
    );
    always @(posedge clk)begin
        if(rst == `RstEna)begin
            ex_alusel <= `EXE_RES_NOP;
            ex_aluop <= `EXE_NOP_OP;
            ex_wreg <= `WriteDisa;
            ex_waddr <= `NOPRegAddr;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
        end
        else begin
            ex_alusel <= id_alusel;
            ex_aluop <= id_aluop;
            ex_wreg <= id_wreg;
            ex_waddr <= id_waddr;
            ex_reg1 <= id_reg1;
            ex_reg2 <= id_reg2;
        end
    end
endmodule
