`timescale 1ns / 1ps

`include"define.v"

module inst_rom(
    input ce,
    input [`InstAddrBus]addr,
    output reg [`InstBus] inst
    );
    reg [`InstBus] inst_mem[0:`InstMemNum-1];
    initial $readmemh("E:/Virtual Machines/VMsharefile/inst_rom.data",inst_mem);
    always @(*)begin
        if(ce == `ChipDisa)begin
            inst <= `ZeroWord;
        end
        else begin
            //之所以到2，是因为MIPS是按字节寻址的，而指令的地址是位，所以要除以4，也就是右移两位
            inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
        end
    end
endmodule
