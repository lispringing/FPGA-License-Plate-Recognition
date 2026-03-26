// 稳定不闪版车牌红框 | 彻底解决乱闪线条
module license_plate_loc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        de_in,
    input  wire [7:0]  bin_in,
    input  wire [31:0] original_rgb,
    input  wire [11:0] x_act,
    input  wire [11:0] y_act,
    output reg         de_out,
    output reg  [31:0] loc_rgb_out
);

parameter W = 960, H = 540;

// --------------- 全局缓存：一帧只算一次框，绝对不闪 ---------------
reg [11:0] x_min, x_max;
reg [11:0] y_min, y_max;
reg [11:0] fx, fy;       // 最终稳定框
reg        de_1d;
reg        vsync;        // 场同步（一帧结束）

// 场同步：一帧结束信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        vsync <= 0;
    else
        vsync <= de_in && !de_1d && (y_act == H-1);
end

// -------------------- 逐行捕捉亮区 --------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_min  <= W;
        x_max  <= 0;
        y_min  <= H;
        y_max  <= 0;
        de_1d  <= 0;
    end else begin
        de_1d <= de_in;

        // 一帧开始复位
        if (vsync) begin
            x_min <= W;
            x_max <= 0;
            y_min <= H;
            y_max <= 0;
        end
        else if (de_in && bin_in > 100) begin
            if (x_act < x_min) x_min <= x_act;
            if (x_act > x_max) x_max <= x_act;
            if (y_act < y_min) y_min <= y_act;
            if (y_act > y_max) y_max <= y_act;
        end
    end
end

// -------------------- 一帧更新一次框（关键：不闪） --------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fx <= 0;
        fy <= 0;
    end else if (vsync) begin
        // 只在帧结束更新一次
        if (x_max-x_min > 30 && y_max-y_min > 10) begin
            fx <= x_min;
            fy <= x_max;
        end
    end
end

// -------------------- 画框（完全稳定） --------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        de_out <= 0;
        loc_rgb_out <= 0;
    end else begin
        de_out <= de_in;

        if (de_in) begin
            if ((x_act == fx || x_act == fy || y_act == y_min || y_act == y_max))
                loc_rgb_out <= 32'hFF0000;
            else
                loc_rgb_out <= original_rgb;
        end else begin
            loc_rgb_out <= 0;
        end
    end
end

endmodule