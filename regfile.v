`timescale 1ns / 1ps

`include"define.v"

module regfile(
    input clk,rst,
    input we,
    input [`RegAddrBus] waddr,
    input [`RegBus] wdata,

    input re1,
    input [`RegAddrBus] raddr1,
    output reg [`RegBus] rdata1,

    input re2,
    input [`RegAddrBus] raddr2,
    output reg [`RegBus] rdata2
    );
//******定义寄存器************
    reg [`RegBus] regs[0:`RegNum-1];

//******************写操作****************
    always @(posedge clk)begin//`RegNumLog2的作用是什么?不能是通用寄存器？
        if(rst==`RstDisa)begin//还是说地址不能是5'h0就行,答：因为MIPS中$0寄存器的值只能是0
            if((we==`WriteEna)&&(waddr!=`RegNumLog2'h0))begin
                regs[waddr] <= wdata;
            end
        end
    end

//*****************读操作1****************读操作是个组合逻辑操作
    always @(*) begin           //这样做的目的：保证在译码阶段取得要读取的值（任何时候都有可能读取）
        if(rst==`RstEna)begin   //并且需要在一个时钟周期内进行多次读操作
            rdata1<=`ZeroWord;
        end
        else if(raddr1== `RegNumLog2'h0)begin
            rdata1<=`ZeroWord;
        end
        else if((raddr1==waddr)&&(we==`WriteEna)&&(re1==`ReadEna))begin
            rdata1<=wdata;//当同时发生读写时，直接将写的值传送给读,因为是异步的，所以可能发生冲突
        end
        else if(re1==`ReadEna)begin
            rdata1 <= regs[raddr1];
        end
        else begin
            rdata1 <= `ZeroWord;
        end
    end

//******************读操作2****************
    always @(*) begin
        if(rst==`RstEna)begin
            rdata2<=`ZeroWord;
        end
        else if(raddr2== `RegNumLog2'h0)begin
            rdata2<=`ZeroWord;
        end
        else if((raddr2==waddr)&&(we==`WriteEna)&&(re2==`ReadEna))begin
            rdata2<=wdata;
        end
        else if(re2==`ReadEna)begin
            rdata2 <= regs[raddr2];
        end
        else begin
            rdata2 <= `ZeroWord;
        end
    end
endmodule
