module sobel_edge #(
    parameter THRESHOLD = 60     // 车牌最清晰值，先用60，调不过来再改50~80
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        de_in,
    input  wire [7:0]  gray_in,
    output reg         de_out,
    output reg  [7:0]  edge_out
);

    reg [7:0] line0[0:2], line1[0:2], line2[0:2];
    reg [9:0] gx_temp1, gx_temp2, gy_temp1, gy_temp2;
    reg [9:0] gx_abs, gy_abs;
    reg [10:0] mag;
    reg de_d1, de_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line0[0]<=0; line0[1]<=0; line0[2]<=0;
            line1[0]<=0; line1[1]<=0; line1[2]<=0;
            line2[0]<=0; line2[1]<=0; line2[2]<=0;
            de_out <= 0; edge_out <= 0;
            de_d1 <= 0; de_d2 <= 0;
        end else begin
            // 行缓存移位
            if (de_in) begin
                line0[0] <= line0[1]; line0[1] <= line0[2]; line0[2] <= line1[0];
                line1[0] <= line1[1]; line1[1] <= line1[2]; line1[2] <= line2[0];
                line2[0] <= line2[1]; line2[1] <= line2[2]; line2[2] <= gray_in;
            end

            de_d1  <= de_in;
            de_d2  <= de_d1;
            de_out <= de_d2;

            if (de_d2) begin
                // 官方手册精确计算
                gx_temp1 <= line0[2] + (line1[2]<<1) + line2[2];
                gx_temp2 <= line0[0] + (line1[0]<<1) + line2[0];
                gy_temp1 <= line2[0] + (line2[1]<<1) + line2[2];
                gy_temp2 <= line0[0] + (line0[1]<<1) + line0[2];

                gx_abs <= (gx_temp1 >= gx_temp2) ? gx_temp1 - gx_temp2 : gx_temp2 - gx_temp1;
                gy_abs <= (gy_temp1 >= gy_temp2) ? gy_temp1 - gy_temp2 : gy_temp2 - gy_temp1;

                mag    <= gx_abs + gy_abs;

                // 黑底白边（手册推荐，效果最好）
                edge_out <= (mag >= THRESHOLD) ? 8'd255 : 8'd0;
            end else begin
                edge_out <= 0;
            end
        end
    end
endmodule