`timescale 1ps/1ps
module binarization(
    input               clk             ,
    input               rst_n           ,

    input               de_in           ,
    input       [7:0]   data_in         ,

    output reg          de_out          ,
    output reg          binary_out      ,

    input       [7:0]   Binary_Threshold
);

reg         binary_r;
reg         de_d0;

// 第1拍：二值化计算
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        binary_r <= 1'b0;
    else begin
        if(data_in > Binary_Threshold)
            binary_r <= 1'b1;
        else
            binary_r <= 1'b0;
    end
end

// 第1拍：DE打一拍
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        de_d0 <= 1'b0;
    else
        de_d0 <= de_in;
end

// 第2拍：输出结果（总共 2拍 延迟）
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        binary_out <= 1'b0;
        de_out     <= 1'b0;
    end
    else begin
        binary_out <= binary_r;
        de_out     <= de_d0;
    end
end

endmodule