//*********** 全局的宏定义 **********************
`define RstEna      1'b1                //复位信号有效
`define RstDisa     1'b0                //复位信号无效
`define ZeroWord    32'h00000000        //32位的数值0
`define WriteEna    1'b1                //使能写
`define WriteDisa   1'b0                //禁止写
`define ReadEna     1'b1                //使能读
`define ReadDisa    1'b0                //禁止读
`define AluOpBus    7:0                 //译码阶段的输出 aluop_o的宽度
`define AluSelBus   2:0                 //译码阶段的输出 alusel_o的宽度
`define InstValid   1'b1                //指令有效
`define InstInvalid 1'b0                //指令无效
`define True_v      1'b1                //逻辑“真”
`define False_v     1'b0                //逻辑“假”
`define ChipEna     1'b1                //芯片使能
`define ChipDisa    1'b0                //芯片禁止
`define Stop        1'b1                //流水暂停
`define NoStop      1'b0                //流水继续

//*********** 与具体指令有关的宏定义 **********************
//为什么指令码和功能码用同样的表示方法呢？
`define EXE_AND     6'b100100           //and的功能码
`define EXE_OR      6'b100101           //or的功能码
`define EXE_XOR     6'b100110           //xor的功能码
`define EXE_NOR     6'b100111           //nor的功能码
`define EXE_ANDI    6'b001100           //andi的指令码
`define EXE_ORI     6'b001101           //ori的指令码
`define EXE_XORI    6'b001110           //xori的指令码
`define EXE_LUI     6'b001111           //lui的指令码

`define EXE_SLL     6'b000000           //sll的功能码
`define EXE_SLLV    6'b000100           //sllv的功能码
`define EXE_SRL     6'b000010           //srl的功能码
`define EXE_SRLV    6'b000110           //srlv的功能码
`define EXE_SRA     6'b000011           //sra的功能码
`define EXE_SRAV    6'b000111           //srav的功能码

`define EXE_MOVZ    6'b001010           //movz的功能码
`define EXE_MOVN    6'b001011           //movn的功能码
`define EXE_MFHI    6'b010000           //mfhi的功能码
`define EXE_MTHI    6'b010001           //mthi的功能码
`define EXE_MFLO    6'b010010           //mflo的功能码
`define EXE_MTLO    6'b010011           //mflo的功能码

`define EXE_ADD     6'b100000           //add的功能码
`define EXE_ADDU    6'b100001           //addu的功能码
`define EXE_SUB     6'b100010           //sub的功能码
`define EXE_SUBU    6'b100011           //subu的功能码
`define EXE_SLT     6'b101010           //slt的功能码
`define EXE_SLTU    6'b101011           //sltu的功能码

`define EXE_MULT    6'b011000           //mult的功能码
`define EXE_MULTU   6'b011001           //multu的功能码
`define EXE_DIV     6'b011010           //div的功能码
`define EXE_DIVU    6'b011011           //divu的功能码

`define EXE_ADDI    6'b001000           //addi的指令码
`define EXE_ADDIU   6'b001001           //addiu的指令码
`define EXE_SLTI    6'b001010           //slti的指令码
`define EXE_SLTIU   6'b001011           //sltiu的指令码
        //跳转指令
`define EXE_JR      6'b001000           //jr的功能码
`define EXE_JALR    6'b001001           //jarl的功能码
`define EXE_J       6'b000010           //j的指令码
`define EXE_JAL     6'b000011           //jal的指令码
        //分支指令，都是通过指令码控制的
`define EXE_BEQ     6'b000100
`define EXE_BGTZ    6'b000111
`define EXE_BLEZ    6'B000110
`define EXE_BNE     6'b000101
//跟在REGIMM后面的分支指令
`define EXE_BLTZ    6'b00000
`define EXE_BLTZAL  6'b10000
`define EXE_BGEZ    6'b00001
`define EXE_BGEZAL  6'b10001

//接在special2类的后面
`define EXE_CLZ         6'b100000           //clk的功能码
`define EXE_CLO         6'b100001           //clo的功能码
`define EXE_MUL         6'b000010           //mul的功能码
`define EXE_MADD        6'b000000           //madd的功能码
`define EXE_MADDU       6'b000001           //
`define EXE_MSUB        6'b000100
`define EXE_MSUBU       6'b000101

`define EXE_SYNC        6'b001111           //sync的功能码
`define EXE_PREF        6'b110011           //pref的指令码
`define EXE_NOP         6'b000000           //nop的指令码
`define EXE_SPECIAL_INST    6'b000000       //SPECIAL类的指令码,用于在op为0的时候
`define EXE_REGIMM_INST     6'b000001       //TODO:这个是干嘛的
`define EXE_SPECIAL2_INST   6'b011100       //SPECIAL2类的指令码

//AluOp
`define EXE_AND_OP      8'b00000001     //AND控制信号
`define EXE_OR_OP       8'b00000010     //这个是在ALU单元运用的，每一个指令有不同的ALUop，单独进行设置的，书上的控制信号是两位的，也就是只有两种情况
`define EXE_XOR_OP      8'b00000011     //XOR
`define EXE_NOR_OP      8'b00000100     //NOR

`define EXE_LUI_OP      8'b00000101     //LUI
`define EXE_SLL_OP      8'b00000110     //SLL逻辑左移
`define EXE_SRA_OP      8'b00000111     //SRA算术右移
`define EXE_SRL_OP      8'b00001000     //SRL逻辑右移

`define EXE_MOVZ_OP     8'b00001001     //movz rd,rs,rt; if(rt==0) rd <- rs;
`define EXE_MOVN_OP     8'b00001010     //movn rd,rs,rt; if(rt!=0) rd <- rs;
`define EXE_MFHI_OP     8'b00001011     //mfhi rd; rd <- hi;
`define EXE_MFLO_OP     8'b00001100     //mflo rd; rd <- lo;
`define EXE_MTHI_OP     8'b00001101     //mthi rs; hi <- rs;
`define EXE_MTLO_OP     8'b00001110     //mtlo rs; lo <- rs;

`define EXE_ADD_OP      8'b00001111     //这类运算指令都是对rs以及rt进行计算，结果存入rd中
`define EXE_ADDU_OP     8'b00010000
`define EXE_SUB_OP      8'b00010001
`define EXE_SUBU_OP     8'b00010010
`define EXE_SLT_OP      8'b00010011
`define EXE_SLTU_OP     8'b00010100

`define EXE_MADD_OP     8'b00010101
`define EXE_MADDU_OP    8'b00010110
`define EXE_MSUB_OP     8'b00010111
`define EXE_MSUBU_OP    8'b00011000

`define EXE_CLZ_OP      8'b00011001     //clz rd,rs; rd <- （rs中前面的0的个数）
`define EXE_CLO_OP      8'b00011010
`define EXE_MUL_OP      8'b00011011     //只保留低32位在rd中
`define EXE_MULT_OP     8'b00011100     //高32位在HI中，低32位在LO中
`define EXE_MULTU_OP    8'b00011101

`define EXE_DIV_OP      8'b00011110     //div rs,rt; {HI,LO} <- rs/rt
`define EXE_DIVU_OP     8'b00011111     //和乘法一样，先换成正数，最后通过异或判断正负，无符号数则不用管

`define EXE_JR_OP       8'b00100000     //jr rs;
`define EXE_JALR_OP     8'b00100001     //jalr rs;|| jalr rs,rd;
`define EXE_J_OP        8'b00100010     //j target;
`define EXE_JAL_OP      8'b00100011     //jal target;
`define EXE_BEQ_OP      8'b00100100     //beq rs,rt,offset; 相等则转移
`define EXE_BGTZ_OP     8'b00100101     //bgtz rs,offset;   大于0则转移
`define EXE_BLEZ_OP     8'b00100110     //blez rs,offset;   小于等于0则转移
`define EXE_BNE_OP      8'b00100111     //bne rs,rt,offset; 不相等则转移
`define EXE_BLTZ_OP     8'b00101000     //bltz rs,offset;   rs的值小于0则转移
`define EXE_BLTZAL_OP   8'b00101001     //bltzal rs,offset; 同上，保存返回地址到$31中
`define EXE_BGEZ_OP     8'b00101010     //bgez rs,offset;   rs的值大于等于0则转移
`define EXE_BGEZAL_OP   8'b00101011     //bgezal rs,offset; 同上

`define EXE_PREF_OP 8'b11111111     //PREF
`define EXE_NOP_OP  8'b00000000     //这个就是流水线中的气泡

//AluSel
`define EXE_RES_LOGIC       3'b001      //用来确定运算类型的，由于现在只有 ori 操作，所以只有逻辑运算
`define EXE_RES_MOVE        3'b010
`define EXE_RES_SHIFT       3'b100      //shift有什么作用
`define EXE_RES_ARITH       3'b101
`define EXE_RES_MUL         3'b110
`define EXE_RES_JUMP_BRANCH 3'b111
`define EXE_RES_NOP         3'b000

//*********** 与指令存储器ROM有关的宏定义 **********************
`define InstAddrBus     31:0        //ROM的地址总线宽度
`define InstBus         31:0        //ROM的数据总线宽度
`define InstMemNum      131071      //ROM的实际大小128KB
`define InstMemNumLog2  17          //ROM实际使用的地址线宽度

//*********** 与通用寄存器Regfile有关的宏定义 **********************
`define RegAddrBus      4:0         //Regfile模块的地址线宽度
`define RegBus          31:0        //Regfile模块的数据线宽度
`define RegWidth        32          //通用寄存器的宽度
`define DoubleRegBus    63:0        //两倍的通用寄存器的数据线宽度
`define DoubleRegWidth  64          //两倍的通用寄存器的宽度
`define RegNum          32          //通用寄存器的数量
`define RegNumLog2      5           //寻址通用寄存器使用的地址位数
`define NOPRegAddr      5'b00000

//************ 与除法相关的宏定义 *********************************
`define DivFree         2'b00
`define DivZero         2'b01
`define DivOn           2'b10
`define DivEnd          2'b11