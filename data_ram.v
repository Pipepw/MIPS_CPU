`timescale 1ns / 1ps

`include"define.v"

module data_ram(
    input clk,
    input ce,   //用于控制是否可读
    input [`DataBus] data_i,    //输入的数据
    input [`DataAddrBus] addr,  //操作的地址，我传进来的地址是对齐之后的地址
    input we,   //用于控制操作方式（加载或存储）
    input [3:0] sel,            //用于控制具体的地址，对齐的地址之后的一个字的地址，哪一位为1则操作哪一位

    output reg [`DataBus] data_o
    );
    reg [`ByteWidth] data_mem0[0:200];    //为什么要用四个呢？如何知道操作哪一个呢？判断大小？
    reg [`ByteWidth] data_mem1[0:200];    //答：每一个就是每一位的内容，一共四位
    reg [`ByteWidth] data_mem2[0:200];
    reg [`ByteWidth] data_mem3[0:200];    //实际上这个是大地址，因为采用大端存储的方式

//**********写操作****************将输入的数据写入到data_mem中
    always @(posedge clk)begin
        if(ce == `ChipDisa)begin
            data_o <= `ZeroWord;
        end
        else if(we == `IsWrite)begin    //sel = 4'b1100表示写入前两位，也就是sw，或者swl
            if(sel[3] == 1'b1)begin     //在mem中，我是把数据放到了低位的，但是不能只看一条指令
                data_mem3[addr[15:0]] <= data_i[31:24]; //将高位数据存放到低地址中
            end //如果是sb，地址为5，那么addr=4，sel=4'b0100
            if(sel[2] == 1'b1)begin     //书上对地址进行了我在mem中进行的处理，并且虽然地址有32位但其中16位是符号扩展之后的结果，所以实际地址只有16位
                data_mem2[addr[15:0]] <= data_i[23:16];
            end //如果是sh，地址为6，那么addr=4，sel=4'b0011
            if(sel[1] == 1'b1)begin
                data_mem1[addr[15:0]] <= data_i[15:8];
            end
            if(sel[0] == 1'b1)begin
                data_mem0[addr[15:0]] <= data_i[7:0];
            end
        end
    end

//*********读操作*****************将data_mem中的数据输出到mem中
    always @(*)begin
        if(ce == `ChipDisa)begin
            data_o <= `ZeroWord;
        end
        else if(we == `IsRead) begin    //直接将整个字都传送过去具体的选择在mem中决定
            data_o <= {data_mem3[addr[15:0]],
                        data_mem2[addr[15:0]],
                        data_mem1[addr[15:0]],
                        data_mem0[addr[15:0]]};
        end
        else begin
            data_o <= `ZeroWord;
        end
    end
endmodule
