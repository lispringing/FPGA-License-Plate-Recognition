module horizon_projection #(
    parameter IMG_H = 540,
    parameter IMG_W = 960
)(
    input           clk,
    input           rst_n,
    input           de_in,
    input           vs_in,
    input           pixel_bit,
    output reg      proj_done
);

/* synthesis PAP_MARK_DEBUG="1" */

reg [9:0] x_cnt;
reg [8:0] y_cnt;
reg [8:0] row_sum;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        x_cnt <= 0;
    else if(!de_in)
        x_cnt <= 0;
    else
        x_cnt <= x_cnt + 1'd1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        y_cnt <= 0;
    else if(vs_in)
        y_cnt <= 0;
    else if(de_in && x_cnt == IMG_W - 1)
        y_cnt <= y_cnt + 1'd1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        row_sum <= 0;
    else if(vs_in || !de_in)
        row_sum <= 0;
    else if(de_in && pixel_bit)
        row_sum <= row_sum + 1'd1;
end

reg vs_d0, vs_d1;
always @(posedge clk) vs_d0 <= vs_in;
always @(posedge clk) vs_d1 <= vs_d0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        proj_done <= 0;
    else
        proj_done <= (!vs_d0 && vs_d1);
end

endmodule