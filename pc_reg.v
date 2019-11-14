`timescale 1ns / 1ps

`include "define.v"

module pc_reg(//实际上只完成了简单的指令加4的功能以及清零的功能
    input clk,
    input rst,
    input [5:0] stall,  //暂停信号
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
        else if(stall[0] == `NoStop) begin //不暂停才赋值，暂停则保持不变
            pc<=pc+4'h4; //直接就在这里自动完成了加4的功能
        end
        else begin
        end
    end
endmodule
