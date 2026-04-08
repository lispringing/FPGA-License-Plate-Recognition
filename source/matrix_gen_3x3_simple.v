`timescale 1ps/1ps
module matrix_gen_3x3_simple
(
    input				clk,
    input				rst_n,

    input				de_in,
    input		[7:0]	data_in,

    output	reg			de_out,

    output	reg	[7:0]	p11, p12, p13,
    output	reg	[7:0]	p21, p22, p23,
    output	reg	[7:0]	p31, p32, p33
);

reg [7:0] line1 [959:0];
reg [7:0] line2 [959:0];
reg [9:0] cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt <= 0;
    else if(de_in)
        cnt <= cnt + 1;
    else
        cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        p11 <= 0; p12 <=0; p13 <=0;
        p21 <= 0; p22 <=0; p23 <=0;
        p31 <= 0; p32 <=0; p33 <=0;
    end
    else if(de_in) begin
        p11 <= p12; p12 <= p13; p13 <= line1[cnt];
        p21 <= p22; p22 <= p23; p23 <= line2[cnt];
        p31 <= p32; p32 <= p33; p33 <= data_in;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        de_out <= 0;
    else
        de_out <= de_in;
end

always @(posedge clk) begin
    if(de_in) begin
        line2[cnt] <= line1[cnt];
        line1[cnt] <= data_in;
    end
end

endmodule