`timescale 1ns / 1ps

`include"define.v"

module mem(
    input rst,
    input wreg_i,
    input [`RegAddrBus] waddr_i,
    input [`RegBus] wdata_i,
    input [`RegBus] hi_i,
    input [`RegBus] lo_i,
    input whilo_i,
    input [`AluOpBus]aluop_i,           //根据指令类型进行相应的处理
    input [`RegBus] mem_addr_i,         //只是最原始的地址，还需要进行处理
    input [`RegBus] reg2_i,             //写入ram的数据
    //来自ram的数据
    input [`RegBus] mem_data_i,         //放进rt的数据
    //来自LLbit_reg的输入
    input LLbit_i,
    //来自mem_wb的旁路（用于 sc 指令）
    input wb_LLbit_we_i,
    input wb_LLbit_value_i,

    output reg wreg_o,
    output reg [`RegAddrBus] waddr_o,
    output reg [`RegBus] wdata_o,
    output reg [`RegBus] hi_o,
    output reg [`RegBus] lo_o,
    output reg whilo_o,
    //通过mem_wb输出到LLbit_reg的数据
    output reg LLbit_we_o,
    output reg LLbit_value_o,
    //输出到ram的数据
    output reg [`RegBus] mem_data_o,    //存储到ram的数据
    output reg [`RegBus] mem_addr_o,    //存放的地址
    output reg mem_we_o,                //指定是加载还是存储操作
    output reg mem_ce_o,                //相当于是读使能
    //字节选择信号,ram是从传入的地址开始，选择sel个字节的数据的，比如传入的地址是5，sel是1，则选择地址为5,6的数据
    output reg [3:0] mem_sel_o  //这个应该是哪一位为1则获取哪些位置的数据，比如4'b0011则获取后两位的数据
    );
    wire [1:0] n;                       //l r 类型指令，数据的位数
    wire [`RegBus] mem_addr;            //用来存放对齐后的地址
    reg LLbit;      //用于保存LLbit的最新值，这样就可以不用在后面进行判断，从而减少重复的操作

    assign n = 4 - mem_addr_i[1:0];
    assign mem_addr = mem_addr_i - mem_addr_i[1:0];   //减去最低两位后，保持最低两位为0

    //更新LLbit的值
    always @(*)begin
        if(rst == `RstEna)begin
            LLbit <= 1'b0;
        end
        else begin
            if(wb_LLbit_we_i == 1'b1)begin
                LLbit <= wb_LLbit_value_i;
            end
            else begin
                LLbit <= LLbit_i;
            end
        end
    end
    always @(*)begin
        if(rst == `RstEna)begin
            wreg_o <= `WriteDisa;
            waddr_o <= `NOPRegAddr;
            wdata_o <= `ZeroWord;
            whilo_o <= `WriteDisa;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
            mem_data_o <= `ZeroWord;
            mem_addr_o <= `ZeroWord;
            mem_we_o <= `IsRead;        //默认为读操作
            mem_ce_o <= `ChipDisa;      //默认不可操作
            mem_sel_o <= 4'b0000;       //不会出现4'b0000的情况
        end
        else begin
            case(aluop_i)       //与之前不同，这里是按照字节来进行处理的，需要转换一下思维，一个字节对应8位数据
                `EXE_LB_OP: begin
                    mem_data_o <= `ZeroWord;
                    mem_addr_o <= mem_addr;         //我都是用的对齐之后的地址，因为都是处理的对齐后的一个字
                    mem_we_o <= `IsRead;            //比如地址为5，对齐后的地址为4，后面的处理都是在4567这一个字上进行的
                    mem_ce_o <= `ChipEna;           //进行读取操作
                    wreg_o <= `WriteEna;            //写到 rt 里面
                    case(mem_addr_i[1:0])
                        2'b00:  begin   //记住，这是大端存储的方式，所以mem_data_i的高位对应在ram中是低地址
                            wdata_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]};  //进行符号扩展，高位是低地址
                        end
                        2'b01:  begin
                            wdata_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
                        end
                        2'b10:  begin
                            wdata_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
                        end
                        2'b11:  begin
                            wdata_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
                            // mem_sel_o <= 4'b0001;   //书上有这种，但是我觉得这个在加载中没有用，所以去掉了
                        end
                    endcase
                    waddr_o <= waddr_i;         //在前面对waddr_i已经进行了处理，就是rt的地址
                end
                `EXE_LBU_OP: begin
                    mem_data_o <= `ZeroWord;
                    mem_addr_o <= mem_addr;
                    mem_we_o <= `IsRead;
                    mem_ce_o <= `ChipEna;
                    wreg_o <= `WriteEna;
                    case(mem_addr_i[1:0])
                        2'b00:  begin
                            wdata_o <= {24'b0,mem_data_i[31:24]};  //进行无符号扩展
                            mem_sel_o <= 4'b1000;
                        end
                        2'b01:  begin
                            wdata_o <= {24'b0,mem_data_i[23:16]};
                            mem_sel_o <= 4'b0100;
                        end
                        2'b10:  begin
                            wdata_o <= {24'b0,mem_data_i[15:8]};
                            mem_sel_o <= 4'b0010;
                        end
                        2'b11:  begin
                            wdata_o <= {24'b0,mem_data_i[7:0]};
                            mem_sel_o <= 4'b0001;
                        end
                    endcase
                    waddr_o <= waddr_i;
                end
                `EXE_LH_OP: begin
                    if(mem_addr_i[0] == 1'b0)    begin       //地址对齐才能读取
                        mem_data_o <= `ZeroWord;
                        mem_addr_o <= mem_addr;           //因为是直接在这个地址的基础上进行获取数据的，比如地址为6，则获取6,7上的数据
                        mem_we_o <= `IsRead;
                        mem_ce_o <= `ChipEna;
                        wreg_o <= `WriteEna;
                        case(mem_addr_i[1:0])
                            2'b00:  begin
                                wdata_o <= {{16{mem_data_i[31]}},mem_data_i[31:16]};  //进行符号扩展
                                mem_sel_o <= 4'b1100;
                            end
                            2'b10:  begin
                                wdata_o <= {{16{mem_data_i[15]}},mem_data_i[15:0]};
                                mem_sel_o <= 4'b0011;
                            end
                            default:begin
                            end
                        endcase
                        waddr_o <= waddr_i;
                    end
                    else begin
                    end
                end
                `EXE_LHU_OP: begin
                    if(mem_addr_i[0] == 1'b0)    begin
                        mem_data_o <= `ZeroWord;
                        mem_addr_o <= mem_addr;
                        mem_we_o <= `IsRead;
                        mem_ce_o <= `ChipEna;
                        wreg_o <= `WriteEna;
                        case(mem_addr_i[1:0])
                            2'b00:  begin
                                wdata_o <= {16'b0,mem_data_i[31:16]};
                                mem_sel_o <= 4'b1100;
                            end
                            2'b10:  begin
                                wdata_o <= {16'b0,mem_data_i[15:0]};
                                mem_sel_o <= 4'b0011;
                            end
                            default:begin
                            end
                        endcase
                        waddr_o <= waddr_i;
                    end
                    else begin
                    end
                end
                `EXE_LW_OP: begin
                    if(mem_addr_i[1:0] == 2'b00)  begin           //对齐才能读取
                        mem_data_o <= `ZeroWord;
                        mem_addr_o <= mem_addr;     //书上都是用的原始的地址，我用的是处理之后的地址，可能是后面不太一样，暂时先不改，后面看情况再说
                        mem_sel_o <= 4'b1111;       //读取四个字节（一个字）
                        mem_we_o <= `IsRead;
                        mem_ce_o <= `ChipEna;
                        wreg_o <= `WriteEna;
                        wdata_o <= mem_data_i;
                        waddr_o <= waddr_i;
                    end
                    else begin
                    end
                end
                `EXE_LWL_OP: begin  //放在高位，从左边开始放 (L)
                    mem_data_o <= `ZeroWord;
                    mem_addr_o <= mem_addr;     //还是用对齐后的地址获取数据，因为都是在这一个字内进行操作的
                    mem_sel_o <= 4'b1111;       //把一个字都读取出来，因为具体存放什么是在后面控制的
                    mem_we_o <= `IsRead;
                    mem_ce_o <= `ChipEna;
                    wreg_o <= `WriteEna;
                    case(mem_addr_i[1:0])
                        2'd3:  begin    //地址为7，获取7
                            wdata_o <= {mem_data_i[7:0],reg2_i[23:0]}; //将写入的数据放在reg的高位
                        end
                        2'd2:  begin    //地址为6，获取67
                            wdata_o <= {mem_data_i[15:0],reg2_i[15:0]};//mem_data_i中存放的是一个字的数据，其低位为高地址
                        end
                        2'd1:  begin    //当地址为5时，mem_data_i中是4567的数据，而要获取的是567
                            wdata_o <= {mem_data_i[23:0],reg2_i[7:0]};
                        end
                        2'd0:   begin   //地址为4，获取4567
                            wdata_o <= mem_data_i;
                        end
                    endcase
                    waddr_o <= waddr_i;
                end
                `EXE_LWR_OP: begin  //放到低位，从右边开始
                    mem_data_o <= `ZeroWord;
                    mem_addr_o <= mem_addr;     //用对齐后的地址获取数据，因为地址为5时，获取的地址是45
                    mem_sel_o <= 4'b1111;
                    mem_we_o <= `IsRead;
                    mem_ce_o <= `ChipEna;
                    wreg_o <= `WriteEna;
                    case(mem_addr_i[1:0])
                        2'd3:  begin    //地址为7，获取4567
                            wdata_o <= mem_data_i;
                        end
                        2'd2:  begin    //当地址为6时，要获取456
                            wdata_o <= {reg2_i[31:24],mem_data_i[31:8]}; //将写入的数据放在reg的低位
                        end
                        2'd1:  begin    //当地址为5时mem_data_i中是4567，而要获取的是45，低地址在高位
                            wdata_o <= {reg2_i[31:16],mem_data_i[31:16]};
                        end
                        2'd0:   begin   //地址为4，获取4
                            wdata_o <= {reg2_i[31:8],mem_data_i[31:24]};
                        end
                    endcase
                    waddr_o <= waddr_i;
                end
                `EXE_SB_OP: begin
                    wdata_o <= `ZeroWord;
                    wreg_o <= `WriteDisa;
                    mem_addr_o <= mem_addr;
                    mem_we_o <= `IsWrite;
                    mem_ce_o <= `ChipEna;   //在我这里，存储操作都是用的低位的数据，考虑到后面的统一性，所以将每一位都
                    mem_data_o <= {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
                    case(mem_addr_i[1:0])   //因为在ram中的处理是根据addr以及sel进行的
                        2'b00:begin
                            mem_sel_o <= 4'b1000;   //地址为4，存放到第一个
                        end
                        2'b01:begin
                            mem_sel_o <= 4'b0100;   //地址为5，存放到第二个
                        end
                        2'b10:begin
                            mem_sel_o <= 4'b0010;
                        end
                        2'b11:begin
                            mem_sel_o <= 4'b0001;
                        end
                    endcase
                end
                `EXE_SH_OP: begin
                    wdata_o <= `ZeroWord;
                    wreg_o <= `WriteDisa;
                    mem_addr_o <= mem_addr;
                    mem_we_o <= `IsWrite;
                    mem_ce_o <= `ChipEna;
                    mem_data_o <= {reg2_i[15:0],reg2_i[15:0]};  //低位是我要加载的数据（向内存，应该是加载才对）
                    case(mem_addr_i[1:0])
                        2'b00:begin
                            mem_sel_o <= 4'b1100;
                        end
                        2'b10:begin
                            mem_sel_o <= 4'b0011;
                        end
                        default;
                    endcase
                end
                `EXE_SW_OP: begin
                    wdata_o <= `ZeroWord;
                    wreg_o <= `WriteDisa;
                    mem_addr_o <= mem_addr;
                    mem_we_o <= `IsWrite;
                    mem_ce_o <= `ChipEna;
                    mem_sel_o <= 4'b1111;
                    mem_data_o <= reg2_i;
                end
                `EXE_SWL_OP: begin      //从右往左
                    wdata_o <= `ZeroWord;
                    wreg_o <= `WriteDisa;
                    mem_addr_o <= mem_addr;
                    mem_we_o <= `IsWrite;
                    mem_ce_o <= `ChipEna;
                    case(mem_addr_i[1:0])
                        2'b00:   begin  //地址为4，存放4567
                            mem_data_o <= reg2_i;
                            mem_sel_o <= 4'b1111;
                        end
                        2'b01:   begin  //地址为5，存放567
                            mem_data_o <= {8'b0,reg2_i[23:0]};
                            mem_sel_o <= 4'b0111;
                        end
                        2'b10:   begin  //地址为6，存放67
                            mem_data_o <= {16'b0,reg2_i[15:0]};
                            mem_sel_o <= 4'b0011;
                        end
                        2'b11:   begin  //地址为7，存放7
                            mem_data_o <= {24'b0,reg2_i[7:0]};
                            mem_sel_o <= 4'b0001;
                        end
                    endcase
                end
                `EXE_SWR_OP: begin      //从左往右
                    wdata_o <= `ZeroWord;
                    wreg_o <= `WriteDisa;
                    mem_addr_o <= mem_addr;
                    mem_we_o <= `IsWrite;
                    mem_ce_o <= `ChipEna;
                    case(mem_addr_i[1:0]) //这里只需要放进去就好了，处理是在ram中的，所以在这里我把所有的都放到了mem_data_o的低位，在ram中根据sel选择获取的字节数(n+1)
                        2'b00:   begin  //地址为4，加载到4
                            mem_data_o <= {reg2_i[7:0],24'b0};
                            mem_sel_o <= 4'b1000;
                        end
                        2'b01:   begin  //地址为5，加载到45
                            mem_data_o <= {reg2_i[15:0],16'b0};
                            mem_sel_o <= 4'b1100;
                        end
                        2'b10:   begin
                            mem_data_o <= {reg2_i[23:0],8'b0};
                            mem_sel_o <= 4'b1110;
                        end
                        2'b11:   begin
                            mem_data_o <= reg2_i;
                            mem_sel_o <= 4'b1111;
                        end
                    endcase
                end
                `EXE_LL_OP: begin       //对比lw指令，只是多了对LLbit_reg的操作
                    mem_data_o <= `ZeroWord;
                    mem_addr_o <= mem_addr;     //书上都是用的原始的地址，我用的是处理之后的地址，可能是后面不太一样，暂时先不改，后面看情况再说
                    mem_sel_o <= 4'b1111;       //读取四个字节（一个字）
                    mem_we_o <= `IsRead;
                    mem_ce_o <= `ChipEna;
                    wreg_o <= `WriteEna;
                    wdata_o <= mem_data_i;
                    waddr_o <= waddr_i;
                    //正式操作，主要是控制LLbit_reg的信号，这是对mem_wb新增的端口
                    LLbit_we_o <= 1'b1;
                    LLbit_value_o <= 1'b1;
                end
                `EXE_SC_OP: begin           //对比sb指令，只是多了个判断以及对LLbit_reg的操作
                    if(LLbit == 1'b1)begin
                        wdata_o <= `ZeroWord;
                        wreg_o <= `WriteDisa;
                        mem_addr_o <= mem_addr;
                        mem_we_o <= `IsWrite;
                        mem_ce_o <= `ChipEna;
                        mem_sel_o <= 4'b1111;
                        mem_data_o <= reg2_i;
                        LLbit_we_o <= 1'b1;
                        LLbit_value_o <= 1'b0;
                    end
                    else begin
                        wdata_o <= 32'b0;
                    end
                end
                default:    begin               //当不是加载存储指令时
                    wreg_o <= wreg_i;
                    waddr_o <= waddr_i;
                    wdata_o <= wdata_i;
                    whilo_o <= whilo_i;
                    hi_o <= hi_i;
                    lo_o <= lo_i;
                    mem_we_o <= `WriteDisa;
                    mem_addr_o <= `ZeroWord;
                    mem_sel_o <= 4'b1111;       //默认读取一个字
                    mem_ce_o <= 1'b0;
                end
            endcase
        end
    end
endmodule
