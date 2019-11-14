`timescale 1ns / 1ps

`include "define.v"

module ctrl(
    input rst,
    input stallreq_from_id,
    input stallreq_from_ex,

    output reg [5:0] stall  //加上pc一共6个阶段，1表示暂停
    );
    //暂停操作就是让中间件的输出保持不变，在最外层加一个判断条件就行了，只有不是暂停时才按照指令进行
    //不然则是简单的保持输出值不变
    //最后是作用在pc、if_id、id_ex、ex_mem、mem_wb、regfile上的，保持这几个的值不变
    always @(*)begin
        if(rst == `RstEna)begin
            stall <= 6'b000000;
        end
        else begin  //不只是让pc暂停，是为了不重复执行指令
            if(stallreq_from_id == `Stop)begin
                stall <= 6'b000111;//在id阶段也显示为暂停操作
            end
            else if(stallreq_from_ex == `Stop)begin
                stall <= 6'b001111;//在ex阶段也是暂停操作
            end
            else begin
                stall <= 6'b000000;
            end
        end
    end
endmodule
