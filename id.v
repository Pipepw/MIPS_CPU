`timescale 1ns / 1ps

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

    //来自ex阶段的旁路数据，当相邻指令发生数据冲突时
    input [`RegBus] ex_wdata_i,
    input [`RegAddrBus] ex_waddr_i,
    input ex_wreg_i,

    //来自mem阶段的旁路数据，当间隔一条指令发生数据发生数据冲突时
    input [`RegBus] mem_wdata_i,
    input [`RegAddrBus] mem_waddr_i,
    input mem_wreg_i,

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
    output reg [`AluSelBus] alusel_o,       //运算类型
    output reg [5:0] stallreq
    );

//我和书上不同的地方，书上是直接按照op进行分类，而我是先按照指令类型进行分类，实际上这样做是多此一举
//并且将数据传输到regfile以及从regfile中读取数据是同时进行的，或者说是要放到一起进行的所以应该用非阻塞赋值

    //先把所有情况的指令段分离出来，TODO:为什么是这样划分的？看到后面才会明白（应该是因为不同的指令需要不同的指令段）
    wire[5:0] op = inst_i[31:26];   //op操作段
    wire[4:0] op2 = inst_i[10:6];   //shamt，并不是这样的，这几个代表的是几个不同等级的指令
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
                `EXE_ANDI:  begin
                    aluop_o <= `EXE_AND_OP;
                    alusel_o <= `EXE_RES_LOGIC;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadDisa;
                    imm <= {16'b0,inst_i[15:0]};
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
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
                `EXE_XORI:  begin
                    aluop_o <= `EXE_XOR_OP;
                    alusel_o <= `EXE_RES_LOGIC;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadDisa;
                    imm <= {16'b0,inst_i[15:0]};
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                `EXE_LUI:   begin   //高16位存放立即数数据，低16位存0
                    aluop_o <= `EXE_LUI_OP;
                    alusel_o <= `EXE_RES_LOGIC;
                    reg1_read_o <= `ReadEna;        //源操作数1赋值为0
                    reg2_read_o <= `ReadDisa;       //源操作数2赋值为立即数
                    imm <= {inst_i[15:0],16'h0};    //直接利用立即数，所以不用扩展，但是imm还是32位的，所以还是要扩展，后面也是按32位进行处理
                    wreg_o <= `WriteEna;            //因为在ex没有相应的操作，所以只有这里赋值为立即数
                    waddr_o <= inst_i[20:16];       //写入的地址是rt
                    instvalid <= `InstValid;
                end
                `EXE_PREF:  begin   //TODO:不知道pref和sync这两个指令有什么用
                    aluop_o <= `EXE_NOP_OP;
                    alusel_o <= `EXE_RES_NOP;
                    reg1_read_o <= `ReadDisa;
                    reg2_read_o <= `ReadDisa;
                    wreg_o <= `WriteDisa;
                    instvalid <= `InstValid;
                end

                `EXE_ADDI:  begin
                    aluop_o <= `EXE_ADD_OP;
                    alusel_o <= `EXE_RES_ARITH;
                    reg1_read_o <= `ReadEna;   //立即数运算，rt <- rs + imm
                    reg2_read_o <= `ReadDisa;
                    imm <= {{16{inst_i[15]}},inst_i[15:0]};
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                `EXE_ADDIU: begin
                    aluop_o <= `EXE_ADDU_OP;
                    alusel_o <= `EXE_RES_ARITH;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadDisa;
                    imm <= {{16{inst_i[15]}},inst_i[15:0]};
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                `EXE_SLTI: begin
                    aluop_o <= `EXE_SLT_OP;
                    alusel_o <= `EXE_RES_ARITH;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadDisa;
                    imm <= {{16{inst_i[15]}},inst_i[15:0]};
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                `EXE_SLTIU: begin
                    aluop_o <= `EXE_SLTU_OP;
                    alusel_o <= `EXE_RES_ARITH;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadDisa;
                    imm <= {{16{inst_i[15]}},inst_i[15:0]};//符号扩展
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end

                //R型指令
                `EXE_SPECIAL_INST:  begin       //指令码为0的情况,R型指令
                    case(op2)
                        5'b00000:  begin
                            case(op3)
                                `EXE_AND:   begin
                                    aluop_o <= `EXE_AND_OP;
                                    alusel_o <= `EXE_RES_LOGIC;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    // waddr_o <= inst_i[20:16];这个是ori中将数据存到rt中，默认是存到rd中，所以不用单独赋值
                                    instvalid <= `InstValid;
                                end
                                `EXE_OR:    begin
                                    aluop_o <= `EXE_OR_OP;
                                    alusel_o <= `EXE_RES_LOGIC;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_XOR:   begin
                                    aluop_o <= `EXE_XOR_OP;
                                    alusel_o <= `EXE_RES_LOGIC;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_NOR:   begin
                                    aluop_o <= `EXE_NOR_OP;
                                    alusel_o <= `EXE_RES_LOGIC;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end

                                //移位操作
                                `EXE_SLLV:  begin
                                    aluop_o <= `EXE_SLL_OP;
                                    alusel_o <= `EXE_RES_SHIFT;
                                    reg1_read_o <= `ReadEna;    //用rs作为偏移量
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SRLV:  begin
                                    aluop_o <= `EXE_SRL_OP;
                                    alusel_o <= `EXE_RES_SHIFT;
                                    reg1_read_o <= `ReadEna;    //用rs作为偏移量
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SRAV:  begin
                                    aluop_o <= `EXE_SRA_OP;
                                    alusel_o <= `EXE_RES_SHIFT;
                                    reg1_read_o <= `ReadEna;    //用rs作为偏移量
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end

                                //移动操作
                                `EXE_MFHI:  begin
                                    wreg_o <= `WriteEna;
                                    aluop_o <= `EXE_MFHI_OP;
                                    alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b0;
                                    reg2_read_o <= 1'b0;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MFLO:  begin
                                    wreg_o <= `WriteEna;
                                    aluop_o <= `EXE_MFLO_OP;
                                    alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b0;
                                    reg2_read_o <= 1'b0;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MTHI:  begin
                                    wreg_o <= `WriteDisa;
                                    aluop_o <= `EXE_MTHI_OP;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b0;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MTLO:  begin
                                    wreg_o <= `WriteDisa;
                                    aluop_o <= `EXE_MTLO_OP;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b0;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MOVN:  begin
                                    aluop_o <= `EXE_MOVN_OP;
                                    alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid <= `InstValid;
                                    if(reg2_o != `ZeroWord)begin
                                        wreg_o <= `WriteEna;
                                    end
                                    else begin
                                        wreg_o <= `WriteDisa;
                                    end
                                end
                                `EXE_MOVZ:  begin
                                    aluop_o <= `EXE_MOVZ_OP;
                                    alusel_o <= `EXE_RES_MOVE;
                                    reg1_read_o <= 1'b1;
                                    reg2_read_o <= 1'b1;
                                    instvalid <= `InstValid;
                                    if(reg2_o == `ZeroWord)begin
                                        wreg_o <= `WriteEna;
                                    end
                                    else begin
                                        wreg_o <= `WriteDisa;
                                    end
                                end

                                //算术操作
                                `EXE_ADD:   begin
                                    aluop_o <= `EXE_ADD_OP;
                                    alusel_o <= `EXE_RES_ARITH;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_ADDU:   begin
                                    aluop_o <= `EXE_ADDU_OP;
                                    alusel_o <= `EXE_RES_ARITH;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SUB:   begin
                                    aluop_o <= `EXE_SUB_OP;
                                    alusel_o <= `EXE_RES_ARITH;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SUBU:   begin
                                    aluop_o <= `EXE_SUBU_OP;
                                    alusel_o <= `EXE_RES_ARITH;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SLT:   begin
                                    aluop_o <= `EXE_SLT_OP;
                                    alusel_o <= `EXE_RES_ARITH;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_SLTU:   begin
                                    aluop_o <= `EXE_SLTU_OP;
                                    alusel_o <= `EXE_RES_ARITH;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MULT:  begin
                                    aluop_o <= `EXE_MULT_OP;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteDisa;   //结果写入hi（高位）与lo（低位）中
                                    instvalid <= `InstValid;
                                end
                                `EXE_MULTU:  begin  //无符号数乘法运算
                                    aluop_o <= `EXE_MULTU_OP;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteDisa;
                                    instvalid <= `InstValid;
                                end

                                //空指令,nop以及snop不用单独处理，一种特殊的移位操作
                                `EXE_SYNC:  begin
                                    aluop_o <= `EXE_NOP_OP;
                                    alusel_o <= `EXE_RES_NOP;
                                    reg1_read_o <= `ReadDisa;
                                    reg2_read_o <= `ReadEna;//TODO:为什么都是将reg2设置为可读
                                    wreg_o <= `WriteDisa;
                                    instvalid <= `InstValid;
                                end
                                default:begin
                                end
                            endcase //case(op3)
                        end // op2=5'b00000
                    default:begin
                    end
                    endcase //case(op2)
                end //SPECIAL指令

                `EXE_SPECIAL2_INST:  begin
                    case(op2)
                        5'b00000:   begin
                            case(op3)
                                `EXE_CLZ:   begin
                                    aluop_o <= `EXE_CLZ_OP;
                                    alusel_o <= `EXE_RES_ARITH;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadDisa;   //clz rd,rs;找rs中0的个数，z:zero
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_CLO:   begin
                                    aluop_o <= `EXE_CLO_OP;
                                    alusel_o <= `EXE_RES_ARITH;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadDisa;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MUL:   begin
                                    aluop_o <= `EXE_MUL_OP;
                                    alusel_o <= `EXE_RES_MUL;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteEna;
                                    instvalid <= `InstValid;
                                end
                            endcase //case(op3)special2中
                        end
                        default:begin
                        end
                    endcase //case(op2)special2中
                end //SPECIAL2指令
                default:begin   //必须要加一个default，避免成为所以锁存器，即使default为空
                end
            endcase //case(op)
            if(inst_i[31:21] == 11'd0)begin
                case(op3)
                    `EXE_SLL:   begin   //逻辑左移，用到了shamt，也就是op2
                        aluop_o <= `EXE_SLL_OP;
                        alusel_o <= `EXE_RES_SHIFT;
                        reg1_read_o <= `ReadDisa;
                        reg2_read_o <= `ReadEna;    //读取rt寄存器的值
                        imm[4:0] <= inst_i[10:6];//用shamt作为输出，本来只有4位，我还补16个0？
                        wreg_o <= `WriteEna;
                        waddr_o <= inst_i[15:11];
                        instvalid <= `InstValid;
                    end
                    `EXE_SRL:   begin   //逻辑右移
                        aluop_o <= `EXE_SRL_OP;
                        alusel_o <= `EXE_RES_SHIFT;
                        reg1_read_o <= `ReadDisa;
                        reg2_read_o <= `ReadEna;
                        imm[4:0] <= inst_i[10:6];
                        wreg_o <= `WriteEna;
                        waddr_o <= inst_i[15:11];
                        instvalid <= `InstValid;
                    end
                    `EXE_SRA:   begin   //算术右移
                        aluop_o <= `EXE_SRA_OP;
                        alusel_o <= `EXE_RES_SHIFT;
                        reg1_read_o <= `ReadDisa;
                        reg2_read_o <= `ReadEna;
                        imm[4:0] <= inst_i[10:6];
                        wreg_o <= `WriteEna;
                        waddr_o <= inst_i[15:11];
                        instvalid <= `InstValid;
                    end
                    default:begin
                    end
                endcase //case(op3)
            end
        end //if
    end     //always        通过这样的方法，使块更加可读

//分开写的原因:
//1.不同的敏感列表，随时需要读取操作
//2.所有指令公用这些，只需要设置读使能信号就行了
//3.不是两个操作数都会读取
/**********************二、读取源操作数1*****************************/

    always @(*)begin
        if(rst == `RstEna)begin
            reg1_o <= `ZeroWord;
        end
        else if(reg1_read_o == `ReadEna)begin

        //当读地址与写地址相同，并且写使能为真时，说明发生了数据相关，这是需要旁路
            if((reg1_addr_o==ex_waddr_i)&&(ex_wreg_i==`WriteEna))begin
                reg1_o <= ex_wdata_i;
            end
            else if((reg1_addr_o==mem_waddr_i)&&(mem_wreg_i==`WriteEna))begin
                reg1_o <= mem_wdata_i;
            end
            //当没有发生旁路时，则从regfile中读取数据
            else begin
                reg1_o <= reg1_data_i;  //regfile 读端口1的值
            end
        end
        else if(reg1_read_o == `ReadDisa)begin
            reg1_o <= imm;          //为什么赋值为立即数呢？因为有可能是会其他的部分作为输出
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

        //当读地址与写地址相同，并且写使能为真时，说明发生了数据相关，这时需要旁路
            if((reg2_addr_o==ex_waddr_i)&&(ex_wreg_i==`WriteEna))begin
                reg2_o <= ex_wdata_i;
            end
            else if((reg2_addr_o==mem_waddr_i)&&(mem_wreg_i==`WriteEna))begin
                reg2_o <= mem_wdata_i;
            end
            //当没有发生旁路时，则从regfile中读取数据
            else begin
                reg2_o <= reg2_data_i;  //regfile 读端口2的值
            end
        end
        else if(reg2_read_o == `ReadDisa)begin
            reg2_o <= imm;
        end
        else begin
            reg2_o <= `ZeroWord;
        end
    end
endmodule
