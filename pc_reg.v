`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/01 08:48:15
// Design Name: 
// Module Name: pc_reg
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
`include "define.v"

module pc_reg(//实际上只完成了简单的指令加4的功能以及清零的功能
    input clk,
    input rst,
    output reg[`InstAddrBus] pc, //要读取的指令的地址
    output reg ce
    );
    always @(posedge clk)begin
        if(rst==`RstEna)begin
            ce<=`ChipDisa; //复位的时候指令存储器禁用
        end//这样做是因为在两个不同的always里面，所以需要一个额外的通信
        else begin
            ce<=`ChipEna;//复位结束后，指令存储器使能，一个过程中只能有一个操作
        end
    end
    always @(posedge clk)begin
        if(ce==`ChipDisa)begin
            pc<=32'h00000000;//指令存储器禁用的时候，PC为0
        end
        else begin
            pc<=pc+4'h4; //直接就在这里自动完成了加4的功能
        end
    end
endmodule
