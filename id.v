`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/01 17:53:09
// Design Name: 
// Module Name: id
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

//与pc和regfile组合，完成译码功能，取数也是在这时候开始的
//所谓的译码就是将指令中需要的东西准备好，根据指令来进行操作，现在只考虑ori指令
//相关的操作就是根据指令来对regfile进行读写操作，只是一个中间件
//MIPS的指令类型：（具体的操作在alu单元中）
//1.R型指令
//2.I型指令，没有看到对立即数的传递呢？
//3.J型指令

`include"define.v"

module id(
    input rst,
    input [`InstAddrBus] pc_i,              //从pc传输来的指令地址
    input [`InstBus] inst_i,                //用地址从regfile中得到的指令

    //读取的Regfile的值
    input [`RegBus] reg1_data_i,            //从regfile输入的第一个读输入
    input [`RegBus] reg2_data_i,            //第二个读输入

    //输出到regfile的信息
    output reg reg1_read_o,                 //第一个读使能信号
    output reg reg2_read_o,                 //第二个读使能信号
    output reg [`RegAddrBus] reg1_addr_o,   //第一个读地址
    output reg [`RegAddrBus] reg2_addr_o,   //第二个读地址

    //送到执行阶段的信息
    output reg wreg_o,                      //写使能信号
    output reg [`RegAddrBus] waddr_o,       //写入寄存器地址（目的寄存器 rd ）
    output reg [`RegBus] reg1_o,            //输出的源操作数1
    output reg [`RegBus] reg2_o,            //源操作数2
    output reg [`AluOpBus] aluop_o,         //alu控制信号
    output reg [`AluSelBus] alusel_o        //运算类型
    );

//我和书上不同的地方，书上是直接按照op进行分类，而我是先按照指令类型进行分类，实际上这样做是多此一举
//并且将数据传输到regfile以及从regfile中读取数据是同时进行的，或者说是要放到一起进行的所以应该用非阻塞赋值

    //先把所有情况的指令段分离出来，TODO:为什么是这样划分的？看到后面才会明白（应该是因为不同的指令需要不同的指令段）
    wire[5:0] op = inst_i[31:26];   //op操作段
    wire[4:0] op2 = inst_i[10:6];   //shamt
    wire[5:0] op3 = inst_i[5:0];    //funct
    wire[4:0] op4 = inst_i[20:16];  //rt
    //立即数，等待后面扩展为32位之后再赋值
    reg [`RegBus] imm;
    //指示指令是否有效，没考虑到这个
    reg instvalid;

/**********************一、对指令进行译码*****************************/

    always @(*)begin
        if(rst == `RstEna)begin
            reg1_read_o <= `ReadDisa;
            reg2_read_o <= `ReadDisa;
            reg1_addr_o <= `RegNumLog2'b0;
            reg2_addr_o <= `RegNumLog2'b0;
            wreg_o <= `WriteDisa;
            waddr_o <= `NOPRegAddr;        //宏定义：默认地址为空时

            reg1_o <= `RegWidth'b0;     //TODO:书上没有对reg_o进行处理，为什么呢？
            reg2_o <= `RegWidth'b0;

            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            imm <= 32'h0;
            instvalid <= `InstValid;
        end
        else begin
        //先对共用的部分进行初始化，主要是对输出到执行阶段的部分进行赋值，只是进行初始化，设置一些默认值
            aluop_o <= `EXE_NOP_OP;     //先初始化为气泡
            alusel_o <= `EXE_RES_NOP;
            waddr_o <= inst_i[15:11];      //不同的指令，这部分的意义不同啊，rd寄存器
            wreg_o <= `WriteDisa;
            instvalid <= `InstValid;
            reg1_read_o <= `ReadDisa;
            reg2_read_o <= `ReadDisa;
            reg1_addr_o <= inst_i[25:21];   //rs寄存器
            reg2_addr_o <= inst_i[20:16];   //rt寄存器
            imm <= `ZeroWord;

            case(op)                    //这里面主要是对控制信号以及地址进行操作
                `EXE_ORI:    begin      //读取rs的数据，目的寄存器为rt
                    aluop_o <= `EXE_OR_OP;
                    alusel_o <= `EXE_RES_LOGIC;
                    //读取数据
                    reg1_read_o <= `ReadEna;    //ori操作只需要rs
                    // reg1_o <= reg1_data_i;  书上读取数据是在另一个always 里面进行的，因为敏感列表不一样，并且那边要时刻准备着运行，所以这样做
                    reg2_read_o <= `ReadDisa;
                    imm <= {16'b0,inst_i[15:0]};
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                default:begin   //必须要加一个default，避免成为所以锁存器，即使default为空
                end
            endcase
        end //if else
    end     //always        通过这样的方法，使块更加可读

//分开写的原因:1.不同的敏感列表，随时需要读取操作  2.所有指令公用这些，只需要设置读使能信号就行了
/**********************二、读取源操作数1*****************************/

    always @(*)begin
        if(rst == `RstEna)begin
            reg1_o <= `ZeroWord;
        end
        else if(reg1_read_o == `ReadEna)begin
            reg1_o <= reg1_data_i;  //regfile 读端口1的值
        end
        else if(reg1_read_o == `ReadDisa)begin
            reg1_o <= imm;          //为什么赋值为立即数呢？
        end
        else begin
            reg1_o <= `ZeroWord;
        end
    end

    /**********************三、读取源操作数2*****************************/

    always @(*)begin
        if(rst == `RstEna)begin
            reg2_o <= `ZeroWord;
        end
        else if(reg2_read_o == `ReadEna)begin
            reg2_o <= reg2_data_i;
        end
        else if(reg2_read_o == `ReadDisa)begin
            reg2_o <= imm;
        end
        else begin
            reg2_o <= `ZeroWord;
        end
    end
endmodule
