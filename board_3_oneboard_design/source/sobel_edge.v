module sobel_edge (
    input             clk,
    input             rst_n,
    input             de_in,
    input      [7:0]  gray_in,
    output reg        de_out,
    output reg [7:0]  edge_out
);

reg [7:0] line0[2:0], line1[2:0], line2[2:0]; // 3�л���
reg [10:0] gx, gy;                            // Sobel �ݶ�
reg        de_d1, de_d2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        line0[0] <= 0; line0[1] <= 0; line0[2] <= 0;
        line1[0] <= 0; line1[1] <= 0; line1[2] <= 0;
        line2[0] <= 0; line2[1] <= 0; line2[2] <= 0;
        gx <= 0; gy <= 0;
        de_out <= 0; edge_out <= 0;
        de_d1 <= 0; de_d2 <= 0;
    end else begin
        // 行缓存移位（保持你原来的写法）
        if (de_in) begin
            line0[0] <= line0[1]; line0[1] <= line0[2]; line0[2] <= line1[0];
            line1[0] <= line1[1]; line1[1] <= line1[2]; line1[2] <= line2[0];
            line2[0] <= line2[1]; line2[1] <= line2[2]; line2[2] <= gray_in;
        end
       
        // 延迟对齐
        de_d1 <= de_in;
        de_d2 <= de_d1;
        de_out <= de_d2;
       
        if (de_d2) begin
            // Gx Gy 计算（符号保持原样）
            gx <= (line0[2] + line1[2]*2 + line2[2]) - (line0[0] + line1[0]*2 + line2[0]);
            gy <= (line0[0] + line0[1]*2 + line0[2]) - (line2[0] + line2[1]*2 + line2[2]);
           
            // 正确计算绝对值（最关键修复）
            wire [10:0] abs_gx = gx[10] ? (~gx[9:0] + 11'd1) : gx[9:0];
            wire [10:0] abs_gy = gy[10] ? (~gy[9:0] + 11'd1) : gy[9:0];
           
            // 幅度（用加法近似 sqrt）
            wire [11:0] mag = abs_gx + abs_gy;
           
            // 输出：先用幅度直接输出（方便调试），看到边缘后再改二值化
            edge_out <= (mag > 255) ? 8'd255 : mag[7:0];
           
            // 如果想直接二值化（常见做法），可以用下面这行替换上面一行
            // localparam THRESH = 60;   // 可调 40~120
            // edge_out <= (mag >= THRESH) ? 8'd255 : 8'd0;
        end else begin
            edge_out <= 0;
        end
    end
end

endmodule