`timescale 1ns / 1ps

//与pc和regfile组合，完成译码功能，取数也是在这时候开始的
//所谓的译码就是将指令中需要的东西准备好
//相关的操作就是根据指令来对regfile进行读写操作，只是一个中间件
//MIPS的指令类型：（具体的操作在alu单元中）
//1.R型指令
//2.I型指令
//3.J型指令

`include"define.v"

module id(
    input rst,
    input [`InstAddrBus] pc_i,              //从pc传输来的指令地址
    input [`InstBus] inst_i,                //用地址从regfile中得到的指令，果然留着是有用的，传递到ex

    //读取的Regfile的值
    input [`RegBus] reg1_data_i,            //从regfile输入的第一个读输入
    input [`RegBus] reg2_data_i,            //第二个读输入

    //来自ex阶段的旁路数据，当相邻指令发生数据冲突时
    input [`RegBus] ex_wdata_i,
    input [`RegAddrBus] ex_waddr_i,
    input ex_wreg_i,
    input [`AluOpBus] ex_aluop_i,

    //来自mem阶段的旁路数据，当间隔一条指令发生数据发生数据冲突时
    input [`RegBus] mem_wdata_i,
    input [`RegAddrBus] mem_waddr_i,
    input mem_wreg_i,

    //来自id_ex的输入，判断指令是否为延迟指令
    input is_delay_inst_i,

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
    output reg is_delay_inst_o,             //当前指令是否为延迟槽中的指令，实际上没有什么用
    output reg [`InstAddrBus] link_addr_o,  //返回地址
    output [`InstBus] inst_o,      //指令
    output reg stallreq,                    //用于解决beq与lw这类指令之间的数据冲突

    //送回pc的数据
    output reg branch_flag_o,
    output reg [`InstAddrBus] branch_addr_inst_o,

    //取id_ex绕了一个周期后返回，用来判断是否为延迟指令
    output reg next_inst_is_delay_o
    );

    //对inst_o进行赋值
    assign inst_o = inst_i;

//我和书上不同的地方，书上是直接按照op进行分类，而我是先按照指令类型进行分类，实际上这样做是多此一举
//并且将数据传输到regfile以及从regfile中读取数据是同时进行的，或者说是要放到一起进行的所以应该用非阻塞赋值

    //不同指令对应的指令段不同，op > op2 > op3 > op4，对指令的判断顺序
    wire[5:0] op = inst_i[31:26];
    wire[4:0] op2 = inst_i[10:6];
    wire[5:0] op3 = inst_i[5:0];
    wire[4:0] op4 = inst_i[20:16];
    //立即数，等待后面扩展为32位之后再赋值
    reg [`RegBus] imm;
    wire [`RegBus] pc_plus_4;       //用来暂时存储下一条指令的地址，pc_i + 4;
    wire [`RegBus] pc_plus_8;       //用来存储返回地址
    //指示指令是否有效，没考虑到这个，实际上暂时没用到，后面异常处理可能会用上
    reg instvalid;
    //判断上一条指令是否为load指令以及判断是否需要阻塞
    reg stallreq_for_reg1;
    reg stallreq_for_reg2;
    wire inst_is_load;

    assign pc_plus_4 = (pc_i + 4);
    assign pc_plus_8 = (pc_i + 8);
    //没有将ll以及sc加入进去
    assign inst_is_load = (ex_aluop_i == `EXE_LB_OP || ex_aluop_i == `EXE_LBU_OP || ex_aluop_i == `EXE_LH_OP ||
                            ex_aluop_i == `EXE_LHU_OP || ex_aluop_i == `EXE_LW_OP || ex_aluop_i == `EXE_LWL_OP ||
                            ex_aluop_i == `EXE_LWR_OP)?1'b1:1'b0;

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
            branch_flag_o <= 1'b0;
            link_addr_o <= `ZeroWord;
            next_inst_is_delay_o <= 1'b0;
            branch_addr_inst_o <= `ZeroWord;
        end
        else begin
        //先对共用的部分进行初始化，主要是对输出到执行阶段的部分进行赋值，只是进行初始化，设置一些默认值
            aluop_o <= `EXE_NOP_OP;     //先初始化为气泡
            alusel_o <= `EXE_RES_NOP;
            waddr_o <= inst_i[15:11];      //默认为rd寄存器
            wreg_o <= `WriteDisa;
            instvalid <= `InstValid;
            reg1_read_o <= `ReadDisa;
            reg2_read_o <= `ReadDisa;
            reg1_addr_o <= inst_i[25:21];   //rs寄存器
            reg2_addr_o <= inst_i[20:16];   //rt寄存器
            imm <= `ZeroWord;
            branch_flag_o <= 1'b0;
            link_addr_o <= `ZeroWord;
            next_inst_is_delay_o <= 1'b0;
            branch_addr_inst_o <= `ZeroWord;

            //指令码控制
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
                `EXE_PREF:  begin   //TODO:不知道pref指令有什么用
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
                //转移指令
                `EXE_J: begin
                    aluop_o <= `EXE_J_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadDisa;
                    reg2_read_o <= `ReadDisa;
                    wreg_o <= `WriteDisa;
                    instvalid <= `InstValid;
                    branch_flag_o <= 1'b1;
                    next_inst_is_delay_o <= 1'b1;
                    branch_addr_inst_o <= {pc_plus_4[31:28],inst_i[25:0],2'b00};
                end
                `EXE_JAL:   begin
                    aluop_o <= `EXE_JAL_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadDisa;
                    reg2_read_o <= `ReadDisa;
                    wreg_o <= `WriteEna;
                    waddr_o <= 5'b11111;    //指定将返回地址存储到$31中
                    instvalid <= `InstValid;
                    branch_flag_o <= 1'b1;
                    next_inst_is_delay_o <= 1'b1;
                    branch_addr_inst_o <= {pc_plus_4[31:28],inst_i[25:0],2'b00};
                    link_addr_o <= pc_plus_8;
                end
                `EXE_BEQ:   begin
                    aluop_o <= `EXE_BEQ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;
                    wreg_o <= `WriteDisa;
                    instvalid <= `InstValid;
                    if(reg1_o == reg2_o)begin   //相等才转移
                        branch_flag_o <= 1'b1;
                        next_inst_is_delay_o <= 1'b1;
                        branch_addr_inst_o <= pc_plus_4 + {{14{inst_i[15]}},inst_i[15:0],2'b00};    //左移两位后符号扩展为32位，再与延迟槽指令地址相加
                    end
                    else begin
                    end
                end
                `EXE_BGTZ:   begin
                    aluop_o <= `EXE_BGTZ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;
                    wreg_o <= `WriteDisa;
                    instvalid <= `InstValid;
                    if(reg1_o[31] == 1'b0 && reg1_o != `ZeroWord)begin     //书上不是直接用的大小与符号进行比较的，因为这样比较，不论正负都是大于0的，因为补码
                        branch_flag_o <= 1'b1;
                        next_inst_is_delay_o <= 1'b1;
                        branch_addr_inst_o <= pc_plus_4 + {{14{inst_i[15]}},inst_i[15:0],2'b00};
                    end
                    else begin
                    end
                end
                `EXE_BLEZ:   begin
                    aluop_o <= `EXE_BLEZ_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;
                    wreg_o <= `WriteDisa;
                    instvalid <= `InstValid;
                    if(reg1_o[31] == 1'b1 || reg1_o == `ZeroWord)begin
                        branch_flag_o <= 1'b1;
                        next_inst_is_delay_o <= 1'b1;
                        branch_addr_inst_o <= pc_plus_4 + {{14{inst_i[15]}},inst_i[15:0],2'b00};
                    end
                    else begin
                    end
                end
                `EXE_BNE:   begin
                    aluop_o <= `EXE_BNE_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;
                    wreg_o <= `WriteDisa;
                    instvalid <= `InstValid;
                    if(reg1_o != reg2_o)begin
                        branch_flag_o <= 1'b1;
                        next_inst_is_delay_o <= 1'b1;
                        branch_addr_inst_o <= pc_plus_4 + {{14{inst_i[15]}},inst_i[15:0],2'b00};
                    end
                    else begin
                    end
                end

                //加载存储指令
                `EXE_LB:    begin
                    aluop_o <= `EXE_LB_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;    //rs中存放的是base，所以需要进行读取
                    reg2_read_o <= `ReadDisa;
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];   //将读取结果放到rt寄存器中
                    instvalid <= `InstValid;
                end
                `EXE_LBU:    begin
                    aluop_o <= `EXE_LBU_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadDisa;
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                `EXE_LH:    begin
                    aluop_o <= `EXE_LH_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadDisa;
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                `EXE_LHU:    begin
                    aluop_o <= `EXE_LHU_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadDisa;
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                `EXE_LW:    begin
                    aluop_o <= `EXE_LW_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadDisa;
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                `EXE_LWL:    begin
                    aluop_o <= `EXE_LWL_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;    //因为只是修改其中的一部分，所以需要进行读取，也就是后面会用连接的方式进行放入rt
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                `EXE_LWR:    begin
                    aluop_o <= `EXE_LWR_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;
                    wreg_o <= `WriteEna;
                    waddr_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                `EXE_SB:    begin
                    aluop_o <= `EXE_SB_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;    //将rt中的值存放到内存中
                    wreg_o <= `WriteDisa;
                    instvalid <= `InstValid;
                end
                `EXE_SH:    begin
                    aluop_o <= `EXE_SH_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;
                    wreg_o <= `WriteDisa;
                    instvalid <= `InstValid;
                end
                `EXE_SW:    begin
                    aluop_o <= `EXE_SW_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;
                    wreg_o <= `WriteDisa;
                    instvalid <= `InstValid;
                end
                `EXE_SWL:    begin
                    aluop_o <= `EXE_SWL_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;
                    wreg_o <= `WriteDisa;
                    instvalid <= `InstValid;
                end
                `EXE_SWR:    begin
                    aluop_o <= `EXE_SWR_OP;
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= `ReadEna;
                    reg2_read_o <= `ReadEna;
                    wreg_o <= `WriteDisa;
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
                                `EXE_DIV:   begin
                                    aluop_o <= `EXE_DIV_OP;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteDisa;
                                    instvalid <= `InstValid;
                                end
                                `EXE_DIVU:  begin
                                    aluop_o <= `EXE_DIVU_OP;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteDisa;
                                    instvalid <= `InstValid;
                                end

                                //跳转指令
                                `EXE_JR:    begin
                                    aluop_o <= `EXE_JR_OP;
                                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadDisa;
                                    wreg_o <= `WriteDisa;   //不需要保存数据到regfile中
                                    instvalid <= `InstValid;
                                    branch_flag_o <= 1'b1;
                                    next_inst_is_delay_o <= 1'b1;
                                    branch_addr_inst_o <= reg1_o;
                                end
                                `EXE_JALR:  begin
                                    aluop_o <= `EXE_JALR_OP;
                                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadDisa;
                                    wreg_o <= `WriteEna;    //最后要将地址写入到寄存器中
                                    instvalid <= `InstValid;
                                    branch_flag_o <= 1'b1;
                                    link_addr_o <= pc_plus_8;       //需要将返回地址保存下来
                                    next_inst_is_delay_o <= 1'b1;
                                    branch_addr_inst_o <= reg1_o;   //可以直接在这里面使用，也就是说改变之后会马上作用到这里
                                end

                                //空指令,nop以及snop不用单独处理，一种特殊的移位操作
                                `EXE_SYNC:  begin
                                    aluop_o <= `EXE_NOP_OP;
                                    alusel_o <= `EXE_RES_NOP;
                                    reg1_read_o <= `ReadDisa;
                                    reg2_read_o <= `ReadDisa;//为什么空指令都是将reg2设置为可读，答：在ex阶段都没有对其进行处理，是什么都无所谓
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
                                `EXE_MADD:  begin
                                    aluop_o <= `EXE_MADD_OP;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteDisa;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MADDU:  begin
                                    aluop_o <= `EXE_MADDU_OP;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteDisa;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MSUB:  begin
                                    aluop_o <= `EXE_MSUB_OP;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteDisa;
                                    instvalid <= `InstValid;
                                end
                                `EXE_MSUBU:  begin
                                    aluop_o <= `EXE_MSUBU_OP;
                                    reg1_read_o <= `ReadEna;
                                    reg2_read_o <= `ReadEna;
                                    wreg_o <= `WriteDisa;
                                    instvalid <= `InstValid;
                                end
                            endcase //case(op3)special2中
                        end
                        default:begin
                        end
                    endcase //case(op2)special2中
                end //SPECIAL2指令

                //REGIMM类型指令
                `EXE_REGIMM_INST:    begin
                    case(op4)
                        `EXE_BLTZ:   begin
                            aluop_o <= `EXE_BLTZ_OP;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_read_o <= `ReadEna;
                            reg2_read_o <= `ReadDisa;
                            wreg_o <= `WriteDisa;
                            instvalid <= `InstValid;
                            if(reg1_o[31] == 1'b1)begin
                                branch_flag_o <= 1'b1;
                                next_inst_is_delay_o <= 1'b1;
                                branch_addr_inst_o <= pc_plus_4 + {{14{inst_i[15]}},inst_i[15:0],2'b00};
                            end
                            else begin
                            end
                        end
                        `EXE_BLTZAL:   begin
                            aluop_o <= `EXE_BLTZAL_OP;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_read_o <= `ReadEna;
                            reg2_read_o <= `ReadDisa;
                            instvalid <= `InstValid;
                            if(reg1_o[31] == 1'b1)begin    //小于时转移，并保存返回地址
                                wreg_o <= `WriteEna;
                                waddr_o <= 5'b11111;
                                branch_flag_o <= 1'b1;
                                next_inst_is_delay_o <= 1'b1;
                                branch_addr_inst_o <= pc_plus_4 + {{14{inst_i[15]}},inst_i[15:0],2'b00};
                                link_addr_o <= pc_plus_8;
                            end
                            else begin
                            end
                        end
                        `EXE_BGEZ:   begin
                            aluop_o <= `EXE_BGEZ_OP;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_read_o <= `ReadEna;
                            reg2_read_o <= `ReadDisa;
                            wreg_o <= `WriteDisa;
                            instvalid <= `InstValid;
                            if(reg1_o[31] == 1'b0)begin
                                branch_flag_o <= 1'b1;
                                next_inst_is_delay_o <= 1'b1;
                                branch_addr_inst_o <= pc_plus_4 + {{14{inst_i[15]}},inst_i[15:0],2'b00};
                            end
                            else begin
                            end
                        end
                        `EXE_BGEZAL:   begin
                            aluop_o <= `EXE_BGEZAL_OP;
                            alusel_o <= `EXE_RES_JUMP_BRANCH;
                            reg1_read_o <= `ReadEna;
                            reg2_read_o <= `ReadDisa;
                            instvalid <= `InstValid;
                            if(reg1_o[31] == 1'b0)begin
                                wreg_o <= `WriteEna;//书上将wwl放到了外面进行赋值，但是如果不满足条件的话，为什么还是将返回地址写入呢？答：没有影响
                                waddr_o <= 5'b11111;
                                branch_flag_o <= 1'b1;
                                next_inst_is_delay_o <= 1'b1;
                                branch_addr_inst_o <= pc_plus_4 + {{14{inst_i[15]}},inst_i[15:0],2'b00};
                                link_addr_o <= pc_plus_8;
                            end
                            else begin
                            end
                        end
                    endcase
                end //EXE_REGIMM_INST指令类型
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

    //为is_delay进行赋值操作，放在外面是因为没必要因为这一个而执行某个always块中的所有部分
    always @(*) begin
        if(rst == `RstEna)begin
            is_delay_inst_o <= 1'b0;
        end
        else begin
            is_delay_inst_o <= is_delay_inst_i;
        end
    end

    //处理加载存储指令与转移指令之间的数据冲突，主要是两者相邻时进行阻塞操作，对reg1进行判断
    always @(*)begin
        stallreq_for_reg1 <= `NoStop;
        if(rst == `RstEna)begin
            stallreq_for_reg1 <= `NoStop;
        end
        else begin
            if(inst_is_load == 1'b1 && reg1_read_o == `ReadEna && reg1_addr_o == ex_waddr_i)begin
                stallreq_for_reg1 <= `Stop;
            end
        end
    end
    //对reg2进行判断，不放在一起是因为这两个是并行的操作
    always @(*)begin
        stallreq_for_reg2 <= `NoStop;
        if(rst == `RstEna)begin
            stallreq_for_reg2 <= `NoStop;
        end
        else begin
            if(inst_is_load == 1'b1 && reg2_read_o == `ReadEna && reg2_addr_o == ex_waddr_i)begin
                stallreq_for_reg2 <= `Stop;
            end
        end
    end
    //对阻塞进行赋值
    always @(*)begin
        if(rst == `RstEna)begin
            stallreq <= `NoStop;
        end
        else begin
            stallreq <= stallreq_for_reg1 | stallreq_for_reg2;
        end
    end
endmodule
