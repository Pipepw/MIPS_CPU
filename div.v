`timescale 1ns / 1ps

`include"define.v"


module div(
    input clk,rst,
    input [`RegBus] opdata1_i,      //这两个可以用前面乘法的处理过的数据
    input [`RegBus] opdata2_i,
    input start_i,
    input annul_i,                  //除法的周期太长了，所以添加一个取消命令，取消则直接结束就好

    output reg [`DoubleRegBus] result_o,    //为什么除法的结果会有64位，我改成了32位,应该是64位，因为高32位为商，低32位为余数
    output reg ready_o              //ready_o是给ex用的，表示结果可以用，开始和结束是由ex控制的，与这个无关
    );
    //我的想法是直接在外部添加一个控制步骤的变量就好了，但书上用的是状态转换的方法，
    //因为有一个明确的信号，当进行到最后一位时，则可以直接结束了，实际上书上还是用了控制步骤的变量，也就是start_i
    //也就是说，每个时钟周期，这个还是要与ex通信，并且由ex进行直接控制
    //其实在ex只进行判断数据是否能用也是可行的，
    reg [`RegAddrBus] cnt;      //用来控制次数以及操作
    reg [`RegBus] opdata1_temp; //用来保存临时的数据，书上将结果和这个temp放在了一起，组成了64位
    wire [`RegBus] opdata1_next;
    reg [1:0] state;
    //改成“无符号数”与除数相减，判断大小，以及用于之后添加新位
    assign opdata1_next = opdata1_temp - opdata2_i;
    always @(posedge clk)begin
        if(rst == `RstEna)begin
            state <= `DivFree;
            ready_o <= 1'b0;
            result_o <= {`ZeroWord,`ZeroWord};
            cnt <= 0;
        end
        case(state)
            `DivFree:   begin  //将数据准备好，默认的运行状态
                if(start_i)begin
                    state <= `DivOn;
                end
                opdata1_temp <= opdata1_i[31];  //进行赋初值的操作
                ready_o <= 1'b0;
                result_o <= {`ZeroWord,`ZeroWord};
                cnt <= 0;
            end
            `DivOn: begin
                cnt <= cnt + 1;
                if(cnt == 31)begin          //最后一位单独进行处理，并结束
                    ready_o <= 1'b1;        //等于31表示除法运算完成
                    if(opdata1_next[31])begin   //为真表示小于
                        result_o[0] <= 0;
                        result_o[63:32] <= opdata1_temp; //表示余数，小于则直接是余数
                    end
                    else begin
                        result_o[0] <= 1;
                        result_o[63:32] <= opdata1_next; //表示余数，相减之后的结果表示余数
                    end
                    state <= `DivFree;      //回到原来的状态
                end
                else if(opdata2_i == 0)begin
                    ready_o <= 1'b1;
                    result_o <= 0;          //当除数为0时，其结果直接输出为0
                    state <= `DivFree;      //回到原来的状态
                end

                //真正进行运算操作的部分
                else begin
                    if(opdata1_next[31])begin   //不管怎样都会添加下一位，但有的是直接添加，有的则需要减了之后添加，也就是有的用temp，有的用next
                        result_o[31-cnt] <= 0;  //小于则用原来的temp进行添加，高32位为商
                        opdata1_temp <= {opdata1_temp[30:0],opdata1_i[30-cnt]};
                    end
                    else begin
                        result_o[31-cnt] <= 1;  //大于等于则用next进行添加
                        opdata1_temp <= {opdata1_next[30:0],opdata1_i[30-cnt]};
                    end
                end
            end //DivOn
            default:begin
            end
        endcase
    end
endmodule
