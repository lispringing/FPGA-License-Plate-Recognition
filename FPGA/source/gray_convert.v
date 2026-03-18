module gray_convert (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        de_in,
    input  wire [7:0]  r_in,
    input  wire [7:0]  g_in,
    input  wire [7:0]  b_in,
    output reg         de_out,
    output reg  [7:0]  gray_out
);

    reg de_d1;
    reg [15:0] gray_temp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            de_out    <= 0;
            gray_out  <= 0;
            de_d1     <= 0;
            gray_temp <= 0;
        end else begin
            // 第1拍：计算（寄存器化）
            if (de_in) begin
                gray_temp <= (r_in * 77) + (g_in * 150) + (b_in * 29);  // ITU-R BT.601 标准
            end

            // 第2拍：输出（严格对齐）
            de_d1  <= de_in;
            de_out <= de_d1;

            if (de_d1) begin
                gray_out <= (gray_temp > 255) ? 8'd255 : gray_temp[7:0];
            end else begin
                gray_out <= 0;
            end
        end
    end
endmodule