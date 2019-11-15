`timescale 1ns / 1ps

`include"define.v"

module ex(
    input rst,
    input [`AluSelBus] alusel_i,
    input [`AluOpBus] aluop_i,
    input [`RegBus] reg1_i,
    input [`RegBus] reg2_i,
    input wreg_i,
    input [`RegAddrBus] waddr_i,
    input [`RegBus] hi_i,
    input [`RegBus] lo_i,
    //wb和mem的旁路数据
    input [`RegBus] wb_hi_i,
    input [`RegBus] wb_lo_i,
    input wb_whilo_i,
    input [`RegBus] mem_hi_i,
    input [`RegBus] mem_lo_i,
    input mem_whilo_i,
    //来自ex_mem保存的数据
    input [`DoubleRegBus] hilo_temp_i,
    input [1:0] cnt_i,

    output reg wreg_o,
    output reg [`RegAddrBus] waddr_o,
    output reg [`RegBus] wdata_o,
    output reg [`RegBus] hi_o,
    output reg [`RegBus] lo_o,
    output reg whilo_o,
    output reg stallreq,
    output reg [`DoubleRegBus] hilo_temp_o,
    output reg [1:0] cnt_o

    );
    //保存逻辑运算的结果（因为现在只有一个 ori 指令，所以只考虑这个）
    reg[`RegBus] logicout;
    reg[`RegBus] shifters;  //移位运算的结果
    reg[`RegBus] moveres;
    reg[`RegBus] arithout;
    reg[`RegBus] HI;
    reg[`RegBus] LO;

    wire ov_sum;
    // wire reg1_eq_reg2;                  //相等，相等有什么用呢？答：没用到
    wire reg1_lt_reg2;                  //1小于2
    wire [`RegBus] reg2_i_mux;          //reg2的补码
    // wire [`RegBus] reg1_i_not;          //reg1的反码，这个有什么用呢？答：书上是在找1的时候用到了，而我不需要这个
    wire [`RegBus] result_sum;          //加法的结果
    wire [`RegBus] opdata1_mult;        //被乘数，这两个有什么用呢？
    wire [`RegBus] opdata2_mult;        //乘数，答：这两个是用来转换成正数的，只有都为正数时，其乘法的结果才是正确的
    wire [`DoubleRegBus] hilo_temp;     //临时保存乘法结果，这个结果中可能是为负的，用于接下来转成负数形式
    reg [`DoubleRegBus] hilo_temp1;     //用于临时保存乘累的操作
    reg [`DoubleRegBus] mulres;         //保存乘法的结果
    reg [5:0] stallreq_mas;
    //对比id.v以及ex.v,可以发现：对于输出的数据，一般是在另一个块里面进行操作的
    //我觉得 alusel 存在的意义在于使不同之类的指令并行化，不然每次只有一个结果，那么输出一个结果就可以了，何必多此一举进行选择

    //逻辑运算
    always @(*)begin
        if(rst == `RstEna)begin
            logicout <= `ZeroWord;
        end
        else begin
            case(aluop_i)
                `EXE_AND_OP:begin
                    logicout <= reg1_i & reg2_i;
                end
                `EXE_OR_OP:begin
                    logicout <= reg1_i | reg2_i;
                end
                `EXE_XOR_OP:begin
                    logicout <= reg1_i ^ reg2_i;
                end
                `EXE_NOR_OP:begin
                    logicout <= ~(reg1_i | reg2_i);
                end
                `EXE_LUI_OP:    begin
                    logicout <= reg2_i;
                end
                default:
                    logicout <= `ZeroWord;
            endcase
        end
    end

    //移位运算
    always @(*)begin
        if(rst == `RstEna)  begin
            shifters <= `ZeroWord;
        end
        case(aluop_i)
            `EXE_SLL_OP:    begin
                shifters <= reg2_i << reg1_i[4:0];//低5位
            end
            `EXE_SRL_OP:   begin
                shifters <= reg2_i >> reg1_i[4:0];
            end
            `EXE_SRA_OP:   begin
                // shifters <= reg1_i >>> reg2_i;//>>>表示算术右移，不能这样用，因为>>>会根据数据类型进行相应的操作，而我不知道怎么将无符号数转化为有符号数
                shifters <= {{32{reg2_i[31]}}}<<(6'd32-{1'b0,reg1_i[4:0]})
                            | reg2_i >> reg1_i[4:0];//太巧妙了，不过其实就是对高位进行补符号位，
            end
            default:begin
                shifters <= `ZeroWord;
            end
        endcase
    end

    //移动运算
    always @(*) begin
        if(rst == `RstEna) begin
            moveres <= `ZeroWord;
        end
        else begin
            moveres <= `ZeroWord;   //TODO:为什么要在这里加一个赋0，试一下不加会怎么样
            case(aluop_i)
                `EXE_MFHI_OP:   begin
                    moveres <= HI;
                end
                `EXE_MFLO_OP:   begin
                    moveres <= LO;
                end
                `EXE_MOVZ_OP:   begin
                    moveres <= reg1_i;
                end
                `EXE_MOVN_OP:   begin
                    moveres <= reg1_i;
                end
                default:begin
                end
            endcase
        end
    end

    //简单算术运算
    //发现了一个特点，在always块中只进行最后的赋值操作，其余的操作都是放到外面进行的
    //算术运算的预处理，组合逻辑用assign赋值语句就好了
    //当发生减法以及有符号数比较时，需要转换为补码，其中有符号数比较其实就是拿两个数相减的结果进行判断的
    //计算机中存储的数据已经是补码的形式了，再次取补码是因为 -A = A的补码，也就是为了将减法转换为加法运算
    //这个其实并不是补码运算，因为补码运算是将非符号位取反，而这里是对所有进行取反
    assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) ||
                        (aluop_i == `EXE_SUBU_OP) ||
                        (aluop_i == `EXE_SLT_OP)) ?
                        (~reg2_i+1):reg2_i;
    // assign reg1_i_not = ~reg1_i;    //还是不知道这个有什么用，没用
    assign result_sum = reg1_i + reg2_i_mux;
    //溢出判断先不考虑指令类型，只要符号不同则是溢出，不一定会用到
    assign ov_sum = (reg1_i[`RegWidth-1]==reg2_i[`RegWidth-1]&&result_sum[`RegWidth-1]!=reg1_i[`RegWidth-1])?1:0;
    // assign reg1_eq_reg2 = (reg1_i == reg2_i)? 1:0;
    //当为无符号比较时，或者都为正数或都为负数时则需要比较
    //否则当前负后正时返回1，否则返回0TODO:这里与书上不一样，有可能出错
    assign reg1_lt_reg2 = ((aluop_i == `EXE_SLTU_OP)||(reg1_i[`RegWidth-1]&&reg2_i[`RegWidth-1]) ||
            (!reg1_i[`RegWidth-1]&&!reg2_i[`RegWidth-1])) ?
            (reg1_i<reg2_i):((reg1_i[`RegWidth-1]&&!reg2_i[`RegWidth-1]) ?  //前负后正：说明前小后大
            1:0);

    always @(*)begin
        if(rst == `RstEna)begin
            arithout <= `ZeroWord;
        end
        else begin
            case(aluop_i)
                //运算的结果都是存放到regfile里面的，所以用一个相同的输出就行了
                //加法运算，所有的运算都是一样的，其实加I的在前面就不应该有
                `EXE_ADD_OP,`EXE_ADDU_OP:    begin
                    arithout <= result_sum;
                end
                //减法运算
                `EXE_SUB_OP,`EXE_SUBU_OP:  begin
                    arithout <= result_sum;
                end
                //比较运算
                `EXE_SLT_OP,`EXE_SLTU_OP:  begin
                    arithout <= reg1_lt_reg2;
                end
                //找rs的0，不是0时退出，是0则继续查找，从高位开始
                `EXE_CLZ_OP:    begin   //因为for循环不能和非阻塞赋值语句一起使用，所以只能一位一位的查找
                    arithout <= reg1_i[`RegWidth-1]?0:
                                reg1_i[`RegWidth-2]?1:
                                reg1_i[`RegWidth-3]?2:
                                reg1_i[`RegWidth-4]?3:
                                reg1_i[`RegWidth-5]?4:
                                reg1_i[`RegWidth-6]?5:
                                reg1_i[`RegWidth-7]?6:
                                reg1_i[`RegWidth-8]?7:
                                reg1_i[`RegWidth-9]?8:
                                reg1_i[`RegWidth-10]?9:
                                reg1_i[`RegWidth-11]?10:
                                reg1_i[`RegWidth-12]?11:
                                reg1_i[`RegWidth-13]?12:
                                reg1_i[`RegWidth-14]?13:
                                reg1_i[`RegWidth-15]?14:
                                reg1_i[`RegWidth-16]?15:
                                reg1_i[`RegWidth-17]?16:
                                reg1_i[`RegWidth-18]?17:
                                reg1_i[`RegWidth-19]?18:
                                reg1_i[`RegWidth-20]?19:
                                reg1_i[`RegWidth-21]?20:
                                reg1_i[`RegWidth-22]?21:
                                reg1_i[`RegWidth-23]?22:
                                reg1_i[`RegWidth-24]?23:
                                reg1_i[`RegWidth-25]?24:
                                reg1_i[`RegWidth-26]?25:
                                reg1_i[`RegWidth-27]?26:
                                reg1_i[`RegWidth-28]?27:
                                reg1_i[`RegWidth-29]?28:
                                reg1_i[`RegWidth-30]?29:
                                reg1_i[`RegWidth-31]?30:
                                reg1_i[`RegWidth-32]?31:32;
                end
                //找1，当为1时，则继续向下，为0则直接出结果
                `EXE_CLO_OP:    begin
                    arithout <= !reg1_i[`RegWidth-1]?0:
                                !reg1_i[`RegWidth-2]?1:
                                !reg1_i[`RegWidth-3]?2:
                                !reg1_i[`RegWidth-4]?3:
                                !reg1_i[`RegWidth-5]?4:
                                !reg1_i[`RegWidth-6]?5:
                                !reg1_i[`RegWidth-7]?6:
                                !reg1_i[`RegWidth-8]?7:
                                !reg1_i[`RegWidth-9]?8:
                                !reg1_i[`RegWidth-10]?9:
                                !reg1_i[`RegWidth-11]?10:
                                !reg1_i[`RegWidth-12]?11:
                                !reg1_i[`RegWidth-13]?12:
                                !reg1_i[`RegWidth-14]?13:
                                !reg1_i[`RegWidth-15]?14:
                                !reg1_i[`RegWidth-16]?15:
                                !reg1_i[`RegWidth-17]?16:
                                !reg1_i[`RegWidth-18]?17:
                                !reg1_i[`RegWidth-19]?18:
                                !reg1_i[`RegWidth-20]?19:
                                !reg1_i[`RegWidth-21]?20:
                                !reg1_i[`RegWidth-22]?21:
                                !reg1_i[`RegWidth-23]?22:
                                !reg1_i[`RegWidth-24]?23:
                                !reg1_i[`RegWidth-25]?24:
                                !reg1_i[`RegWidth-26]?25:
                                !reg1_i[`RegWidth-27]?26:
                                !reg1_i[`RegWidth-28]?27:
                                !reg1_i[`RegWidth-29]?28:
                                !reg1_i[`RegWidth-30]?29:
                                !reg1_i[`RegWidth-31]?30:
                                !reg1_i[`RegWidth-32]?31:32;
                end
                default:begin
                    arithout <= `ZeroWord;
                end
            endcase
        end
    end

    //乘法运算
    //如果按照现实中的乘法，乘出来的结果是源码，而在计算机中应该是补码，所以需要取其补码，这个补码与上面的补码不同
    //如果是负数，那么需要对其取补码计算，只有在是有符号乘法时，才需要进行补码处理
    assign opdata1_mult = ((aluop_i == `EXE_MULT_OP || aluop_i == `EXE_MUL_OP||
                            aluop_i == `EXE_MADD_OP || aluop_i == `EXE_MSUB_OP)
                            &&reg1_i[`RegWidth-1])?(~reg1_i+1):reg1_i;
    assign opdata2_mult = ((aluop_i == `EXE_MULT_OP || aluop_i == `EXE_MUL_OP||
                            aluop_i == `EXE_MADD_OP || aluop_i == `EXE_MSUB_OP)
                            &&reg2_i[`RegWidth-1])?(~reg2_i+1):reg2_i;
    assign hilo_temp = opdata1_mult * opdata2_mult;
    always @(*) begin
        if(rst == `RstEna)begin
            mulres <= {`ZeroWord,`ZeroWord};
        end
        else if(aluop_i == `EXE_MULT_OP || aluop_i == `EXE_MUL_OP||
                aluop_i == `EXE_MADD_OP || aluop_i == `EXE_MSUB_OP) begin//有符号数乘法
            //如果异或为真，说明相乘为负数，则需要取其补码形式
            if (reg1_i[`RegWidth-1]^reg2_i[`RegWidth-1]) begin
                mulres <= (~hilo_temp + 1);
            end
            else begin
                mulres <= hilo_temp;
            end
        end
        else begin
            mulres <= hilo_temp;
        end
    end

    //乘累加以及乘累减运算
    always @(*)begin
        if(rst == `RstEna)begin
            hilo_temp_o <= {`ZeroWord,`ZeroWord};
            cnt_o <= 2'b00;
            hilo_temp1 <= {`ZeroWord,`ZeroWord};
            stallreq_mas <= `NoStop;
        end
        else begin
            if(aluop_i == `EXE_MADD_OP || aluop_i == `EXE_MADDU_OP)begin
                if(cnt_i == 2'b00)begin
                    hilo_temp_o <= mulres;   //这个是在mulres发生变化的时候执行，所以不用担心赋值失败
                    cnt_o <= 2'b01;
                    stallreq_mas <= `Stop;
                end
                else if(cnt_i == 2'b01)begin
                    hilo_temp_o <= {`ZeroWord,`ZeroWord};
                    cnt_o <= 2'b10;
                    hilo_temp1 <= hilo_temp_i + {HI,LO};
                    stallreq_mas <= `NoStop;
                end
                else begin
                end
            end
            else if(aluop_i == `EXE_MSUB_OP || aluop_i == `EXE_MSUBU_OP)begin
                if(cnt_i == 2'b00)begin
                    hilo_temp_o <= ~mulres + 1;   //是HILO减去乘的结果，所以需要对其进行取反
                    cnt_o <= 2'b01;
                    stallreq_mas <= `Stop;
                end
                else if(cnt_i == 2'b01)begin
                    hilo_temp_o <= {`ZeroWord,`ZeroWord};
                    cnt_o <= 2'b10;
                    hilo_temp1 <= hilo_temp_i + {HI,LO};
                    stallreq_mas <= `NoStop;
                end
                else begin
                end
            end
            else begin
                hilo_temp_o <= {`ZeroWord,`ZeroWord};
                cnt_o <= 2'b00;
                stallreq_mas <= `NoStop;
            end
        end //!rst
    end

    //暂停流水线
    always @(*)begin
        stallreq = stallreq_mas;
    end

    //根据 alusel 选择输出结果
    always @(*)begin
        waddr_o <= waddr_i;
        if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_SUB_OP))&&(ov_sum == `True_v))begin
            wreg_o <= `WriteDisa;
        end
        else begin
            wreg_o <= wreg_i;
        end
        case (alusel_i)
            `EXE_RES_LOGIC:begin
                wdata_o <= logicout;
            end
            `EXE_RES_SHIFT:begin
                wdata_o <= shifters;
            end
            `EXE_RES_MOVE:begin
                wdata_o <= moveres;
            end
            `EXE_RES_ARITH:begin
                wdata_o <= arithout;
            end
            `EXE_RES_MUL:begin
                wdata_o <= mulres[31:0];
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end

    //流向hilo_reg的数据
    always @(*)begin
        if(rst == `RstEna)begin
            whilo_o <= `WriteDisa;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
        else if(aluop_i == `EXE_MTHI_OP)begin
            whilo_o <= `WriteEna;
            hi_o <= reg1_i;     //将hi赋为新值，lo保持不变
            lo_o <= LO;
        end
        else if(aluop_i == `EXE_MTLO_OP)begin
            whilo_o <= `WriteEna;
            hi_o <= HI;
            lo_o <= reg1_i;
        end
        //为什么是相同的，不应该一个是有符号数，一个是无符号数吗？之前计算的是有符号数乘法，那么无符号数乘法有是什么样的呢？
        //答：在之前的处理中，已经根据运算的不同的处理mulres，也就是说：其结果既可能是有符号的，也可能是无符号的
        else if(aluop_i == `EXE_MULT_OP || aluop_i == `EXE_MULTU_OP)begin
            whilo_o <= `WriteEna;
            hi_o <= mulres[63:32];
            lo_o <= mulres[31:0];
        end
        else if(aluop_i == `EXE_MADD_OP || aluop_i == `EXE_MADDU_OP ||
                aluop_i == `EXE_MSUB_OP || aluop_i == `EXE_MSUBU_OP)begin
                    whilo_o <= `WriteEna;
                    hi_o <= hilo_temp1[63:32];
                    lo_o <= hilo_temp1[31:0];
                end
        else begin
            whilo_o <= `WriteDisa;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end
    end

    //准备工作：将HI和LO的现值准备好
    always @(*) begin
        if(rst == `RstEna)begin
            {HI,LO} <= {`ZeroWord,`ZeroWord};
        end
        //旁路的选择
        else if(mem_whilo_i == `WriteEna) begin    //优先判断mem，因为mem比wb后写回，也就是比wb更新
            {HI,LO} <= {mem_hi_i,mem_lo_i};
        end
        else if(wb_whilo_i == `WriteEna) begin
            {HI,LO} <= {wb_hi_i,wb_lo_i};
        end
        else begin
            {HI,LO} <= {hi_i,lo_i};
        end
    end
endmodule
