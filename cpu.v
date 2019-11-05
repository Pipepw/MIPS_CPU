`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/05 15:07:12
// Design Name: 
// Module Name: cpu
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
`include"ex_mem.v"
`include"ex.v"
`include"id_ex.v"
`include"id.v"
`include"if_id.v"
`include"mem_wb.v"
`include"mem.v"

module cpu(
    input clk,rst,
    input [`InstBus] rom_data_i,        //存储器传输进来的指令

    output rom_ce_o,                    //通过控制pc，从而控制整个处理器
    output [`InstAddrBus] rom_addr_o    //指令存储器的输入地址
    );

/********************每个部件之间的连线******************/

    //pc的输出以及if_id的输入
    wire [`InstAddrBus] pc_if;      //通向if_id

    //if_id的输出与id的输入
    wire [`InstAddrBus] pc_id;      //TODO:指令的地址，id拿来干嘛
    wire [`InstBus] inst;           //指令

    //id的输出与regfile的输入
    wire [`RegAddrBus] reg1_addr;   //第一个读取的寄存器地址
    wire reg1_read;                 //第一个读使能信号
    wire [`RegAddrBus] reg2_addr;   //第二个读取的寄存器地址
    wire reg2_read;                 //第二个读使能信号

    //regfile的输出与id的输入
    wire [`RegBus] reg1_data;       //第一个寄存器数据
    wire [`RegBus] reg2_data;       //第二个寄存器数据

    //id的输出与id_ex的输入
    wire [`AluOpBus] aluop_id;      //alu控制
    wire [`AluSelBus] alusel_id;    //alu运算类型
    wire [`RegBus] reg1_id;         //源操作数1
    wire [`RegBus] reg2_id;         //源操作数2
    wire [`RegAddrBus] reg_addr_id; //写入的寄存器地址
    wire wreg_id;                   //写使能信号

    //id_ex的输出与ex的输入
    wire [`AluOpBus] aluop_ex;      //alu控制
    wire [`AluSelBus] alusel_ex;    //alu运算类型
    wire [`RegBus] reg1_ex;         //源操作数1
    wire [`RegBus] reg2_ex;         //源操作数2
    wire [`RegAddrBus] reg_addr_ex; //写入的寄存器地址
    wire wreg_ex;                   //写使能信号

    //ex的输出与ex_men的输入
    wire [`RegBus] wdata_ex;        //写入的数据
    wire [`RegAddrBus] waddr_ex;    //写入的寄存器地址
    wire wreg_ex_mem;               //写使能信号

    //ex_mem的输出与mem的输入
    wire [`RegBus] wdata_mem;        //写入的数据
    wire [`RegAddrBus] waddr_mem;    //写入的寄存器地址
    wire wreg_mem;                   //写使能信号

    //mem的输出与mem_wb的输入
    wire [`RegBus] wdata_mem_mem;    //写入的数据
    wire [`RegAddrBus] waddr_mem_mem;//写入的寄存器地址
    wire wreg_mem_mem;               //写使能信号

    //mem_wb的输出与regfile的输入
    wire [`RegBus] wdata_reg;        //写入的数据
    wire [`RegAddrBus] waddr_reg;    //写入的寄存器地址
    wire wreg_reg;                   //写使能信号

/*******************每个部件的实例化************************/
    //regfile的实例化
    regfile regfile0(
        .clk(clk),
        .rst(rst),
        .we(wreg_reg),
        .waddr(waddr_reg),
        .wdata(wdata_reg),
        .re1(reg1_read),
        .re2(reg2_read),
        .raddr1(reg1_addr),
        .raddr2(reg2_addr),

        .rdata1(reg1_data),
        .rdata2(reg2_data)
    );

    //pc的实例化
    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst),

        .pc(pc_if),
        .ce(rom_ce_o)
    );

    assign rom_addr_o = pc_if; //我没用到的，指令存储器的输入地址

    //if_id的实例化
    if_id if_id0(
        .clk(clk),
        .rst(rst),
        .if_pc(pc_if),
        .if_inst(rom_data_i), //指令存储器的值

        .id_pc(pc_id),
        .id_inst(inst)
    );

    //id的实例化
    id id0(
        .rst(rst),
        .pc_i(pc_id),
        .inst_i(inst),
        .reg1_data_i(reg1_data),
        .reg2_data_i(reg2_data),

        .reg1_read_o(reg1_read),
        .reg2_read_o(reg2_read),
        .reg1_addr_o(reg1_addr),
        .reg2_addr_o(reg2_addr),
        .wreg_o(wreg_id),
        .waddr_o(reg_addr_id),
        .reg1_o(reg1_id),
        .reg2_o(reg2_id),
        .aluop_o(aluop_id),
        .alusel_o(alusel_id)
    );

    //id_ex的实例化
    id_ex id_ex0(
        .clk(clk),
        .rst(rst),
        .id_alusel(alusel_id),
        .id_aluop(aluop_id),
        .id_wreg(wreg_id),
        .id_waddr(reg_addr_id),
        .id_reg1(reg1_id),
        .id_reg2(reg2_id),

        .ex_alusel(alusel_ex),
        .ex_aluop(aluop_ex),
        .ex_wreg(wreg_ex),
        .ex_waddr(reg_addr_ex),
        .ex_reg1(reg1_ex),
        .ex_reg2(reg2_ex)
    );

    //ex的实例化
    ex ex0(
        .rst(rst),
        .alusel_i(alusel_ex),
        .aluop_i(aluop_ex),
        .reg1_i(reg1_ex),
        .reg2_i(reg2_ex),
        .wreg_i(wreg_ex),
        .waddr_i(reg_addr_ex),

        .wreg_o(wreg_mem),
        .waddr_o(waddr_mem),
        .wdata_o(wdata_mem)
    );

    //ex_mem的实例化
    ex_mem ex_me0(
        .clk(clk),
        .rst(rst),
        .ex_waddr(waddr_ex),
        .ex_wdata(wdata_ex),
        .ex_wreg(wreg_ex),

        .mem_waddr(waddr_mem),
        .mem_wdata(wdata_mem),
        .mem_wreg(wreg_mem)
    );

    //mem的实例化
    mem mem0(
        .rst(rst),
        .wreg_i(wreg_mem),
        .waddr_i(waddr_mem),
        .wdata_i(wdata_mem),

        .wreg_o(wreg_mem_mem),
        .waddr_o(waddr_mem_mem),
        .wdata_o(wdata_mem_mem)
    );

    //mem_wb的实例化
    mem_wb mem_wb0(
        .clk(clk),
        .rst(rst),
        .mem_reg(wreg_mem_mem),
        .mem_waddr(waddr_mem_mem),
        .mem_wdata(wdata_mem_mem),

        .wb_reg(wreg_reg),
        .wb_waddr(waddr_reg),
        .wb_wdata(wdata_reg)
    );
endmodule
