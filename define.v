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

//*********** 与具体指令有关的宏定义 **********************
`define EXE_ORI 6'b001101           //指令ori的指令码
`define EXE_NOP 6'b000000           //指令nop的指令码

//AluOp
`define EXE_OR_OP   8'b00100101     //这个是在ALU单元运用的，每一个指令有不同的ALUop，单独进行设置的
`define EXE_NOP_OP  8'b00000000     //这个就是流水线中的气泡

//AluSel
`define EXE_RES_LOGIC   3'b001      //用来确定运算类型的，由于现在只有 ori 操作，所以只有逻辑运算
`define EXE_RES_NOP     3'b000

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