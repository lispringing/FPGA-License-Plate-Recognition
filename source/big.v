`timescale 1ps/1ps
module bit_dilation_your_matrix
(
    input           clk,
    input           rst_n,

    input           de_in,      // 二值化/Sobel DE
    input           data_in,    // 1bit 输入

    output  reg     de_out,
    output  reg     data_out    // 膨胀结果
);

// 调用你自己的 3×3 矩阵！
wire        mat_de;
wire [7:0]  p11,p12,p13;
wire [7:0]  p21,p22,p23;
wire [7:0]  p31,p32,p33;

matrix_gen_3x3_simple u_mat
(
    .clk        (clk),
    .rst_n      (rst_n),
    .de_in      (de_in),
    .data_in    (data_in ? 8'd255 : 8'd0), // 转8位
    .de_out     (mat_de),
    .p11(p11),.p12(p12),.p13(p13),
    .p21(p21),.p22(p22),.p23(p23),
    .p31(p31),.p32(p32),.p33(p33)
);

//--------------------------------------
// 膨胀：3×3任意一个为白 → 输出白
//--------------------------------------
wire dilation_result = 
    (p11 > 128) | (p12 > 128) | (p13 > 128) |
    (p21 > 128) | (p22 > 128) | (p23 > 128) |
    (p31 > 128) | (p32 > 128) | (p33 > 128);

//--------------------------------------
// 2拍同步输出
//--------------------------------------
reg de_d0;
reg dilat_r;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        de_d0   <= 0;
        dilat_r <= 0;
        de_out  <= 0;
        data_out<= 0;
    end
    else begin
        de_d0   <= mat_de;
        dilat_r <= dilation_result;
        de_out  <= de_d0;
        data_out<= dilat_r;
    end
end

endmodule