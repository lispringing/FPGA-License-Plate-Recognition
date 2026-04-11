// 灰度化增强模块 - 适配国内全类型车牌（新能源/军牌/黄牌/蓝牌）
// 核心优化：1. 分色权重校准 2. 对比度增强 3. 2拍延迟 4. RGB32输入
module gray_convert (
    input  wire        clk,        // 时钟：对接pix_clk_in
    input  wire        rst_n,      // 复位：对接ddr_ip_rst_n && ddr_init_done
    input  wire        de_in,      // 输入数据有效：对接zoom_de_out
    input  wire [7:0]  r_in,       // 红通道：对接zoom_data_out[31:24]
    input  wire [7:0]  g_in,       // 绿通道：对接zoom_data_out[21:14]
    input  wire [7:0]  b_in,       // 蓝通道：对接zoom_data_out[11:4]
    output reg         de_out,     // 输出数据有效：给fifo1的video1_de_in
    output reg  [7:0]  gray_out    // 8bit灰度输出：给gray_rgb32
);

// ===================== 1. 内部参数定义（只改对比度增益，其他不动）=====================
localparam R_WEIGHT = 8'd85;
localparam G_WEIGHT = 8'd155;
localparam B_WEIGHT = 8'd18;
localparam CONTRAST_GAIN = 3'd4; // 【暴力修改】对比度拉到最大
localparam BRIGHTNESS_OFFSET = 5'd0;

// ===================== 2. 内部寄存器（只加算法相关寄存器）=====================
reg [21:0] gray_temp;
reg de_d1;
reg [7:0] gray_raw;
reg [9:0] gray_enhance;
reg is_blue_bg;
reg is_yellow_bg;
reg is_green_bg;
reg is_bg;

// ===================== 3. 时序逻辑：2拍延迟（只改算法部分）=====================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gray_temp   <= 22'd0;
        de_d1       <= 1'b0;
        de_out      <= 1'b0;
        gray_raw    <= 8'd0;
        gray_enhance<= 10'd0;
        gray_out    <= 8'd0;
        is_blue_bg  <= 1'b0;
        is_yellow_bg<= 1'b0;
        is_green_bg <= 1'b0;
        is_bg       <= 1'b0;
    end else begin
        // ---------------- 第1拍：加权灰度计算 + 【暴力底色识别】----------------
        if (de_in) begin
            gray_temp <= (r_in * R_WEIGHT) + (g_in * G_WEIGHT) + (b_in * B_WEIGHT);
            
            // 【暴力修改1】更严格、更宽泛的底色识别，确保不漏掉任何一个底色像素
            is_blue_bg  <= (b_in > r_in + 20) && (b_in > g_in + 20); // 蓝底：B明显大
            is_yellow_bg<= (r_in > 120) && (g_in > 120) && (b_in < 110); // 黄底：RG高B低
            is_green_bg <= (g_in > r_in + 15) && (g_in > b_in + 15); // 绿底：G明显大
            is_bg       <= is_blue_bg || is_yellow_bg || is_green_bg;
        end else begin
            gray_temp <= 22'd0;
            is_blue_bg  <= 1'b0;
            is_yellow_bg<= 1'b0;
            is_green_bg <= 1'b0;
            is_bg       <= 1'b0;
        end
        de_d1 <= de_in;

        // ---------------- 第2拍：【暴力对比度拉伸】 + 【暴力反相】----------------
        gray_raw <= gray_temp[15:8];
        // 【暴力修改2】对比度拉到4，彻底拉开底和字的差距
        gray_enhance <= ((gray_raw - 8'd128) * CONTRAST_GAIN) + 8'd128 + BRIGHTNESS_OFFSET;
        
        // 【暴力修改3】是底色直接输出0（纯黑），是字符直接输出255（纯白），彻底消灭灰色
        if (is_bg) begin
            gray_out <= 8'd0; // 底色直接钉死纯黑
        end else begin
            // 字符直接钉死纯白
            if (gray_enhance > 10'd128)
                gray_out <= 8'd255;
            else
                gray_out <= 8'd0;
        end
        
        de_out <= de_d1;
    end
end

endmodule