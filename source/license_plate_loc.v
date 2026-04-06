// 稳定不闪版车牌定位模块 - 修复版
module license_plate_loc (
    input wire clk,
    input wire rst_n,
    input wire de_in,
    input wire [7:0] bin_in,
    input wire [31:0] original_rgb,
    input wire [11:0] x_act,
    input wire [11:0] y_act,
    output reg de_out,
    output reg [31:0] loc_rgb_out
);

parameter W = 960;
parameter H = 540;

// ------------------ 稳定框寄存器 ------------------
reg [11:0] box_xmin, box_xmax;
reg [11:0] box_ymin, box_ymax;
reg box_valid;                    // 当前帧是否有有效框

// ------------------ 临时统计（当前帧） ------------------
reg [11:0] x_min, x_max;
reg [11:0] y_min, y_max;
reg de_1d;

// ------------------ 帧结束信号（推荐写法） ------------------
wire frame_end;
assign frame_end = de_1d && !de_in && (y_act == H-1);  // de 下降沿 + 最后一行

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        de_1d <= 1'b0;
    else 
        de_1d <= de_in;
end

// ------------------ 逐像素统计亮区 ------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x_min <= W;
        x_max <= 0;
        y_min <= H;
        y_max <= 0;
    end
    else begin
        if (frame_end) begin
            // 一帧结束，复位统计
            x_min <= W;
            x_max <= 0;
            y_min <= H;
            y_max <= 0;
        end
        else if (de_in && bin_in > 80) begin   // 阈值可调，建议80~120
            if (x_act < x_min) x_min <= x_act;
            if (x_act > x_max) x_max <= x_act;
            if (y_act < y_min) y_min <= y_act;
            if (y_act > y_max) y_max <= y_act;
        end
    end
end

// ------------------ 一帧结束时更新稳定框 ------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        box_xmin  <= 0;
        box_xmax  <= 0;
        box_ymin  <= 0;
        box_ymax  <= 0;
        box_valid <= 1'b0;
    end
    else if (frame_end) begin
        if ((x_max - x_min > 40) && (y_max - y_min > 15)) begin  // 最小尺寸过滤
            box_xmin  <= x_min;
            box_xmax  <= x_max;
            box_ymin  <= y_min;
            box_ymax  <= y_max;
            box_valid <= 1'b1;
        end else begin
            box_valid <= 1'b0;   // 太小认为是噪声
        end
    end
end

// ------------------ 输出 + 画红框 ------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        de_out      <= 1'b0;
        loc_rgb_out <= 32'h0;
    end
    else begin
        de_out <= de_in;
        
        if (de_in && box_valid) begin
            // 画矩形框：上下横线 + 左右竖线
            if ( (y_act == box_ymin || y_act == box_ymax) ||
                 (x_act == box_xmin || x_act == box_xmax) ) begin
                loc_rgb_out <= 32'hFF0000;     // 纯红色 (R=255, G=0, B=0)
            end
            else begin
                loc_rgb_out <= original_rgb;   // 原图像
            end
        end
        else begin
            loc_rgb_out <= original_rgb;       // 非有效区域或无框时透传原图
        end
    end
end

endmodule