`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/03 09:44:15
// Design Name: 
// Module Name: ex
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

module ex(
    input rst,
    input [`AluSelBus] alusel_i,
    input [`AluOpBus] aluop_i,
    input [`RegBus] reg1_i,
    input [`RegBus] reg2_i,
    input wreg_i,
    input [`RegAddrBus] waddr_i,

    output reg wreg_o,
    output reg [`RegAddrBus] waddr_o,
    output reg [`RegBus] wdata_o
    );
    //保存逻辑运算的结果（因为现在只有一个 ori 指令，所以只考虑这个）
    reg[`RegBus] logicout;
    //对比id.v以及ex.v,可以发现：对于输出的数据，一般是在另一个块里面进行操作的
    //我觉得 alusel 存在的意义在于使不同之类的指令并行化，不然每次只有一个结果，那么输出一个结果就可以了，何必多此一举进行选择
    always @(*)begin
        if(rst == `RstEna)begin
            logicout <= `ZeroWord;
        end
        else begin
            case(aluop_i)
                `EXE_OR_OP:begin
                    logicout <= reg1_i | reg2_i;
                end
                default:
                    logicout <= `ZeroWord;
            endcase
        end
    end
    //根据 alusel 选择输出结果
    always @(*)begin
        wreg_o <= wreg_i;
        waddr_o <= waddr_i;
        case (alusel_i)
            `EXE_RES_LOGIC:begin
                wdata_o <= logicout;
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
endmodule
