module plate_locate_light #(
    parameter IMG_W = 960,
    parameter IMG_H = 540
)(
    input            clk,
    input            rst_n,
    input            de_in,
    input            vs_in,
    input            pixel_bit,
    input            h_proj_done,
    input            v_proj_done,

    output reg [9:0] plate_left,
    output reg [9:0] plate_right,
    output reg [8:0] plate_top,
    output reg [8:0] plate_bottom
);

// ============================================================
// 像素坐标计数
// ============================================================
reg [9:0] x_cnt;
reg [8:0] y_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)         x_cnt <= 0;
    else if (!de_in)    x_cnt <= 0;
    else                x_cnt <= x_cnt + 1'd1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)                              y_cnt <= 0;
    else if (vs_in)                          y_cnt <= 0;
    else if (de_in && x_cnt == IMG_W - 1)   y_cnt <= y_cnt + 1'd1;
end

// ============================================================
// 行投影：每行扫描完成后统计该行白像素数
// 在行尾（x_cnt == IMG_W-1）锁存并判断
// ============================================================
reg [9:0] row_pix_cnt;   // 当前行白像素累计

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        row_pix_cnt <= 0;
    else if (vs_in || (de_in && x_cnt == IMG_W - 1))
        row_pix_cnt <= 0;           // 行末或帧头复位
    else if (de_in && pixel_bit)
        row_pix_cnt <= row_pix_cnt + 1'd1;
end

// 行边界检测：在行尾采样
reg [8:0] min_row, max_row;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        min_row <= IMG_H;
        max_row <= 0;
    end else if (vs_in) begin
        // 帧头复位，准备新一帧检测
        min_row <= IMG_H;
        max_row <= 0;
    end else if (de_in && x_cnt == IMG_W - 1) begin
        // 行末：判断本行是否为有效行
        if (row_pix_cnt > 40) begin
            if (y_cnt < min_row) min_row <= y_cnt;
            if (y_cnt > max_row) max_row <= y_cnt;
        end
    end
end

// ============================================================
// 列投影：需要按列累计整帧的白像素数
// 使用列计数RAM或逐列扫描方式
// 这里采用轻量化方案：记录每列是否出现过白像素行
// 用一个移位寄存器标记当前列在本帧是否有效
// ============================================================

// 每列白像素计数（整帧累计）
// 为节省资源，用一维数组存储每列的计数值
reg [8:0] col_pix_cnt [0:IMG_W-1];  // 每列最多 540 行
integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < IMG_W; i = i + 1)
            col_pix_cnt[i] <= 0;
    end else if (vs_in) begin
        // 帧头清零所有列计数
        for (i = 0; i < IMG_W; i = i + 1)
            col_pix_cnt[i] <= 0;
    end else if (de_in && pixel_bit) begin
        // 当前像素为白，对应列计数+1
        col_pix_cnt[x_cnt] <= col_pix_cnt[x_cnt] + 1'd1;
    end
end

// 列边界检测：在每个像素时刻实时更新
reg [9:0] min_col, max_col;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        min_col <= IMG_W;
        max_col <= 0;
    end else if (vs_in) begin
        min_col <= IMG_W;
        max_col <= 0;
    end else if (de_in) begin
        // 当前列累计值超过阈值，更新边界
        if (col_pix_cnt[x_cnt] > 40) begin
            if (x_cnt < min_col) min_col <= x_cnt;
            if (x_cnt > max_col) max_col <= x_cnt;
        end
    end
end

// ============================================================
// 输出坐标（帧末锁存，加边距保护）
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        plate_top    <= 0;
        plate_bottom <= IMG_H - 1;
        plate_left   <= 0;
        plate_right  <= IMG_W - 1;
    end else if (vs_in) begin
        // 在帧头（上一帧结束时）锁存坐标，供当前帧画框使用
        if (min_row < max_row && min_col < max_col) begin
            plate_top    <= (min_row >= 2) ? min_row - 2 : 0;
            plate_bottom <= (max_row <= IMG_H - 3) ? max_row + 2 : IMG_H - 1;
            plate_left   <= (min_col >= 2) ? min_col - 2 : 0;
            plate_right  <= (max_col <= IMG_W - 3) ? max_col + 2 : IMG_W - 1;
        end
    end
end

endmodule
