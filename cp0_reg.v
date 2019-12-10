`timescale 1ns / 1ps

`include"define.v"

module cp0_reg(     //和前面是同样的道理，看起来是寄存器，实际上是输出不变则表示存下来了，这样是因为只需要一个值就好，不需要关注之前的状态
    input clk,
    input rst,
    input we_i,                 //写使能信号
    input [4:0] waddr_i,        //写入的地址（那么多个寄存器，这个就是用来控制写入那个寄存器的)
    input [4:0] raddr_i,        //读取的地址
    input [`RegBus] data_i,     //写入的数据
    input [5:0] int_i,          //6个外部硬件的中断输入

    output reg[`RegBus] data_o, //读出的数据
    output reg[`RegBus] count_o,
    output reg[`RegBus] compare_o,
    output reg[`RegBus] status_o,
    output reg[`RegBus] cause_o,
    output reg[`RegBus] epc_o,
    output reg[`RegBus] config_o,
    output reg[`RegBus] prid_o,
    output reg timer_int_o      //定时中断
    );
    //************写操作*****************
    always @(posedge clk)begin
        if(rst == `RstEna)begin
            count_o <= `ZeroWord;
            compare_o <= `ZeroWord;
            status_o <= `ZeroWord;
            cause_o <= `ZeroWord;
            epc_o <= `ZeroWord;
            config_o <= 32'h00008000;   //BE字段为1，表示大端存储
            prid_o <= 32'b0;
            timer_int_o <= `InterruptNotAssert;
        end
        else begin
            case(waddr_i)
                `CP0_REG_COUNT: begin
                    count_o <= data_i;
                end
                `CP0_REG_COMPARE:   begin
                    compare_o <= data_i;
                    timer_int_o <= `InterruptNotAssert;
                end
                `CP0_REG_STATUS:    begin
                    status_o <= data_i;
                end
                `CP0_REG_CAUSE: begin   //只有IP[1:0]、IV、WP字段可写
                    cause_o[9:8] <= data_i[9:8];
                    cause_o[23] <= data_i[23];
                    cause_o[22] <= data_i[22];
                end
                `CP0_REG_EPC:   begin
                    epc_o <= data_i;
                end
            endcase
        end
    end

    //*********** 读操作 ******************
    always @(*)begin
        if(rst == `RstEna)begin
            data_o <= `ZeroWord;
        end
        else begin
            case(raddr_i)
                `CP0_REG_COUNT: begin
                    data_o <= count_o;
                end
                `CP0_REG_COMPARE:   begin
                    data_o <= compare_o;
                end
                `CP0_REG_STATUS:    begin
                    data_o <= status_o;
                end
                `CP0_REG_CAUSE: begin   //只有IP[1:0]、IV、WP字段可写
                    data_o <= cause_o;
                end
                `CP0_REG_EPC:   begin
                    data_o <= epc_o;
                end
                `CP0_REG_PRID:  begin
                    data_o <= prid_o;
                end
                `CP0_REG_CONFIG:    begin
                    data_o <= config_o;
                end
                default:    begin
                end
            endcase
        end
    end
endmodule
