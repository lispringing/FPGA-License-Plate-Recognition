`timescale 1ps/1ps
module Sobel_Edge_Detector
(
    input				clk,
    input				rst_n,

    input				de_in,      // 二值化 DE
    input		[7:0]	data_in,     // 二值化数据 0/255

    output	reg			de_out,     // 输出 DE（2拍）
    output	reg			edge_out    // 边缘输出
);

//-----------------------------------
// 3×3矩阵生成
//-----------------------------------
wire				matrix_de;
wire		[7:0]	p11, p12, p13;
wire		[7:0]	p21, p22, p23;
wire		[7:0]	p31, p32, p33;

matrix_gen_3x3_simple u_mat
(
    .clk		(clk),
    .rst_n		(rst_n),
    .de_in		(de_in),
    .data_in	(data_in),
    .de_out		(matrix_de),
    .p11		(p11),
    .p12		(p12),
    .p13		(p13),
    .p21		(p21),
    .p22		(p22),
    .p23		(p23),
    .p31		(p31),
    .p32		(p32),
    .p33		(p33)
);

//-----------------------------------
// Sobel Gx 计算（全部非阻塞赋值）
//-----------------------------------
reg	[9:0]	gx_temp1, gx_temp2;
reg	[9:0]	gx;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        gx_temp1 <= 0;
        gx_temp2 <= 0;
        gx       <= 0;
    end
    else begin
        gx_temp1 <= p13 + (p23 << 1) + p33;
        gx_temp2 <= p11 + (p21 << 1) + p31;
        gx       <= (gx_temp1 >= gx_temp2) ? (gx_temp1 - gx_temp2) : (gx_temp2 - gx_temp1);
    end
end

//-----------------------------------
// Sobel Gy 计算
//-----------------------------------
reg	[9:0]	gy_temp1, gy_temp2;
reg	[9:0]	gy;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        gy_temp1 <= 0;
        gy_temp2 <= 0;
        gy       <= 0;
    end
    else begin
        gy_temp1 <= p11 + (p12 << 1) + p13;
        gy_temp2 <= p31 + (p32 << 1) + p33;
        gy       <= (gy_temp1 >= gy_temp2) ? (gy_temp1 - gy_temp2) : (gy_temp2 - gy_temp1);
    end
end

//-----------------------------------
// 总和
//-----------------------------------
reg [10:0] sum;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        sum <= 0;
    else
        sum <= gx + gy;
end

//-----------------------------------
// 阈值判决
//-----------------------------------
reg edge_r;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        edge_r <= 0;
    else if(sum > 80)   // 灵敏度可调
        edge_r <= 1;
    else
        edge_r <= 0;
end

//-----------------------------------
// DE 同步 2拍延迟
//-----------------------------------
reg de_d0;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        de_d0  <= 0;
        de_out <= 0;
        edge_out <= 0;
    end
    else begin
        de_d0  <= matrix_de;
        de_out <= de_d0;
        edge_out <= edge_r;
    end
end

endmodule