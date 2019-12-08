`timescale 1ns / 1ps

`include"define.v"

module LLbit_reg(
    input clk,
    input rst,
    input flush,
    input we,
    input LLbit_i,
    output reg LLbit_o
    );
    always @(posedge clk)begin
        if(rst == `RstEna)begin
            LLbit_o <= 1'b0;
        end
        else if(flush == 1'b1)begin     //发生异常时，设置为0
            LLbit_o <= 1'b0;
        end
        else if(we == `WriteEna)begin
            LLbit_o <= LLbit_i;
        end
    end
endmodule
