`timescale 1ps/1ps
module erosion_using_your_matrix
(
    input           clk,
    input           rst_n,

    // 输入：来自二值化
    input           de_in,
    input           data_in,        // 1bit 二值数据 0/1

    // 输出：去噪后 -> 给 Sobel
    output  reg     de_out,
    output  reg     data_out
);

// --------------------- 第1次腐蚀 ---------------------
wire        mat1_de;
wire [7:0]  p11_1,p12_1,p13_1;
wire [7:0]  p21_1,p22_1,p23_1;
wire [7:0]  p31_1,p32_1,p33_1;
reg         erosion1_result;
reg         de1_d0, de1_out;
reg         data1_out;

matrix_gen_3x3_simple u_mat1
(
    .clk        (clk),
    .rst_n      (rst_n),
    .de_in      (de_in),
    .data_in    (data_in ? 8'd255 : 8'd0),
    .de_out     (mat1_de),
    .p11(p11_1),.p12(p12_1),.p13(p13_1),
    .p21(p21_1),.p22(p22_1),.p23(p23_1),
    .p31(p31_1),.p32(p32_1),.p33(p33_1)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        erosion1_result <= 0;
    else begin
        erosion1_result <=  (p11_1 > 128) & (p12_1 > 128) & (p13_1 > 128)
                        & (p21_1 > 128) & (p22_1 > 128) & (p23_1 > 128)
                        & (p31_1 > 128) & (p32_1 > 128) & (p33_1 > 128);
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        de1_d0 <= 0;
        de1_out <= 0;
        data1_out <= 0;
    end
    else begin
        de1_d0 <= mat1_de;
        de1_out <= de1_d0;
        data1_out <= erosion1_result;
    end
end

// --------------------- 第2次腐蚀（效果翻倍）---------------------
wire        mat2_de;
wire [7:0]  p11_2,p12_2,p13_2;
wire [7:0]  p21_2,p22_2,p23_2;
wire [7:0]  p31_2,p32_2,p33_2;
reg         erosion2_result;
reg         de2_d0;

matrix_gen_3x3_simple u_mat2
(
    .clk        (clk),
    .rst_n      (rst_n),
    .de_in      (de1_out),
    .data_in    (data1_out ? 8'd255 : 8'd0),
    .de_out     (mat2_de),
    .p11(p11_2),.p12(p12_2),.p13(p13_2),
    .p21(p21_2),.p22(p22_2),.p23(p23_2),
    .p31(p31_2),.p32(p32_2),.p33(p33_2)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        erosion2_result <= 0;
    else begin
        erosion2_result <=  (p11_2 > 128) & (p12_2 > 128) & (p13_2 > 128)
                        & (p21_2 > 128) & (p22_2 > 128) & (p23_2 > 128)
                        & (p31_2 > 128) & (p32_2 > 128) & (p33_2 > 128);
    end
end

// --------------------- 最终输出 ---------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        de2_d0 <= 0;
        de_out <= 0;
        data_out <= 0;
    end
    else begin
        de2_d0 <= mat2_de;
        de_out <= de2_d0;
        data_out <= erosion2_result;
    end
end

endmodule