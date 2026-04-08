module draw_box #(
    parameter IMG_W         = 960,
    parameter BOX_COLOR     = 24'h00FF00,
    parameter W_H_RATIO     = 3,
    parameter FILTER_STEP   = 5,      // 防抖阈值：变化小于3像素不更新
    parameter BOX_THICKNESS = 1       // 框加粗：2表示左右各2像素，共5像素宽
)(
    input           clk,
    input           rst_n,

    input           de_in,
    input           vs_in,
    input           hs_in,
    input [23:0]    rgb_in,

    input [9:0]     plate_left,
    input [9:0]     plate_right,
    input [8:0]     plate_top,
    input [8:0]     plate_bottom,

    output          de_out,
    output          vs_out,
    output          hs_out,
    output [23:0]   rgb_out
);

/* synthesis PAP_MARK_DEBUG="1" */

// ============================================================
// 1. 坐标计数（保持不变）
// ============================================================
reg [9:0] x_cnt;
reg [8:0] y_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)         x_cnt <= 0;
    else if (!de_in)    x_cnt <= 0;
    else                x_cnt <= x_cnt + 1'd1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)                             y_cnt <= 0;
    else if (vs_in)                         y_cnt <= 0;
    else if (de_in && x_cnt == IMG_W - 1)  y_cnt <= y_cnt + 1'd1;
end

// ============================================================
// 2. 帧结束信号（VS下降沿检测）
// ============================================================
reg vs_d1;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) vs_d1 <= 1'b0;
    else vs_d1 <= vs_in;
end
wire vs_frame_end = vs_d1 && !vs_in; // 一帧结束

// ============================================================
// 3. 【核心1】帧锁存 + 坐标滤波（彻底防抖）
// ============================================================
reg [9:0] lock_left;
reg [9:0] lock_right;
reg [8:0] lock_bottom;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        lock_left   <= 10'd200;  // 初始默认值
        lock_right  <= 10'd400;
        lock_bottom <= 9'd300;
    end else if(vs_frame_end) begin  // 只有帧结束才更新
        // 左边界滤波：变化小于FILTER_STEP不更新
        if( (plate_left > lock_left + FILTER_STEP) || (plate_left < lock_left - FILTER_STEP) )
            lock_left <= plate_left;

        // 右边界滤波
        if( (plate_right > lock_right + FILTER_STEP) || (plate_right < lock_right - FILTER_STEP) )
            lock_right <= plate_right;

        // 下边界滤波
        if( (plate_bottom > lock_bottom + FILTER_STEP) || (plate_bottom < lock_bottom - FILTER_STEP) )
            lock_bottom <= plate_bottom;
    end
end

// ============================================================
// 4. 自动计算上边界（用锁存后的稳定坐标）
// ============================================================
wire [9:0] plate_w = (lock_right > lock_left) ? (lock_right - lock_left) : 0;
wire [8:0] plate_h;
assign plate_h = (W_H_RATIO == 3) ? (plate_w >> 2) + (plate_w >> 4) : // 3:1
                 (W_H_RATIO == 4) ? (plate_w >> 2) :                     // 4:1
                 (plate_w >> 2);                                           // 默认4:1
wire [8:0] calc_plate_top = (lock_bottom > plate_h) ? (lock_bottom - plate_h) : 0;

// ============================================================
// 5. 【核心2】框加粗（BOX_THICKNESS控制粗细）
// ============================================================
wire on_top    = (y_cnt >= calc_plate_top - BOX_THICKNESS) && (y_cnt <= calc_plate_top + BOX_THICKNESS) &&
                 (x_cnt >= lock_left) && (x_cnt <= lock_right);
wire on_bottom = (y_cnt >= lock_bottom - BOX_THICKNESS) && (y_cnt <= lock_bottom + BOX_THICKNESS) &&
                 (x_cnt >= lock_left) && (x_cnt <= lock_right);
wire on_left   = (x_cnt >= lock_left - BOX_THICKNESS) && (x_cnt <= lock_left + BOX_THICKNESS) &&
                 (y_cnt >= calc_plate_top) && (y_cnt <= lock_bottom);
wire on_right  = (x_cnt >= lock_right - BOX_THICKNESS) && (x_cnt <= lock_right + BOX_THICKNESS) &&
                 (y_cnt >= calc_plate_top) && (y_cnt <= lock_bottom);

wire is_box = de_in && (on_top || on_bottom || on_left || on_right);

// ============================================================
// 6. 输出打拍对齐（保持不变）
// ============================================================
reg        de_r,  vs_r,  hs_r;
reg [23:0] rgb_r;
reg        is_box_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        de_r     <= 0;
        vs_r     <= 0;
        hs_r     <= 0;
        rgb_r    <= 0;
        is_box_r <= 0;
    end else begin
        de_r     <= de_in;
        vs_r     <= vs_in;
        hs_r     <= hs_in;
        rgb_r    <= rgb_in;
        is_box_r <= is_box;
    end
end

assign de_out  = de_r;
assign vs_out  = vs_r;
assign hs_out  = hs_r;
assign rgb_out = is_box_r ? BOX_COLOR : rgb_r;

endmodule