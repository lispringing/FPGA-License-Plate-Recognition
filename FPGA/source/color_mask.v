module color_mask #(
    parameter THRESHOLD = 20,        // 调低，更灵敏
    parameter COLOR_BLUE   = 1,
    parameter COLOR_YELLOW = 1,
    parameter COLOR_GREEN  = 1,
    parameter COLOR_BLACK  = 1
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        vs_in, 
    input  wire        de_in,
    input  wire [31:0] rgb_in,
    output reg         vs_out,
    output reg         de_out,
    output reg  [31:0] rgb_out
);

    wire [7:0] R = rgb_in[31:24];
    wire [7:0] G = rgb_in[21:14];
    wire [7:0] B = rgb_in[11:4];

    reg color_match;

    always @(*) begin
        color_match = 1'b0;

        // -------------------------- 蓝牌（不变）--------------------------
        if (COLOR_BLUE)
            color_match = color_match || ((B > R + 20) && (B > G + 20));

        // -------------------------- 黄牌（专用判据）--------------------------
        if (COLOR_YELLOW)
            color_match = color_match || (
                (R > 120) && (G > 120) && (B < 100) &&
                (R - B > 40) && (G - B > 40)
            );

        // -------------------------- 绿牌（渐变新能源专用）--------------------------
        if (COLOR_GREEN)
            color_match = color_match || (
                (G > R + 20) && (G > B + 20) &&
                ((R > 180 && G > 180 && B > 180) ||    // 上半部分白色
                 (G > 100 && B < 100 && R < 120))      // 下半部分绿色
            );

    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            de_out <= 1'b0;
            rgb_out <= 32'd0;
        end else begin
            de_out <= de_in;
            if (de_in && color_match)
                rgb_out <= rgb_in;
            else
                rgb_out <= 32'h404040;  // 灰色背景
        end
    end

    always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        vs_out <= 1'b0;
    else
        vs_out <= vs_in;  // 和 de_out <= de_in 同级
    end

endmodule