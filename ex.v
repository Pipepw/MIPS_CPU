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

    output reg wreg_o,
    output reg [`RegAddrBus] waddr_o,
    output reg [`RegBus] wdata_o,
    output reg [`RegBus] hi_o,
    output reg [`RegBus] lo_o,
    output reg whilo_o

    );
    //保存逻辑运算的结果（因为现在只有一个 ori 指令，所以只考虑这个）
    reg[`RegBus] logicout;
    reg[`RegBus] shifters;  //移位运算的结果
    reg[`RegBus] moveres;
    reg[`RegBus] HI;
    reg[`RegBus] LO;
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
            moveres <= `ZeroWord;
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

    //根据 alusel 选择输出结果
    always @(*)begin
        wreg_o <= wreg_i;
        waddr_o <= waddr_i;
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
