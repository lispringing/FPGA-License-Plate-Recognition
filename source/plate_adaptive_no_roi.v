// 【动态自适应二值化】去掉ROI | 全图处理 | 盘古50K专属
module plate_adaptive_no_roi (
    input  wire        clk,         // 像素时钟，接pix_clk_in
    input  wire        rst_n,       // 复位，接ddr_ip_rst_n && ddr_init_done
    input  wire        de_in,       // 输入de：接中值滤波的median_de
    input  wire [7:0]  gray_in,     // 输入灰度图：接中值滤波的median_data
    output reg         de_out,      // 输出de：给FIFO2
    output reg  [7:0]  bin_out      // 输出全图动态自适应二值图
);

// ===================== 核心参数（仅保留动态阈值偏移量）=====================
parameter THRESH_OFFSET  = 8'd45;      // 动态阈值偏移量（唯一调优参数）

// ===================== 3×3行缓存（动态局部均值核心）=====================
reg [7:0] row1[2:0], row2[2:0], row3[2:0];
integer i;
reg [9:0] local_mean;  // 动态计算的局部均值（每像素都不一样）
reg [1:0] de_dly;      // de信号同步延迟

// ===================== 核心逻辑（去掉所有ROI相关判断）=====================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // 复位所有寄存器
        for(i=0; i<3; i=i+1) begin
            row1[i] <= 8'd0;
            row2[i] <= 8'd0;
            row3[i] <= 8'd0;
        end
        local_mean <= 10'd0;
        de_dly <= 2'd0;
        de_out <= 1'b0;
        bin_out <= 8'd0;
    end else begin
        // 1. 3×3窗口移位（逐行加载，动态计算局部均值）
        if(de_in) begin
            row1[0] <= row1[1]; row1[1] <= row1[2]; row1[2] <= gray_in;
            row2[0] <= row2[1]; row2[1] <= row2[2]; row2[2] <= row1[0];
            row3[0] <= row3[1]; row3[1] <= row3[2]; row3[2] <= row2[0];
        end

        // 2. de信号同步（匹配3×3窗口处理节拍）
        de_dly <= {de_dly[0], de_in};
        de_out <= de_dly[1]; // 输出de和处理后的像素对齐

        // 3. 动态计算局部均值（自适应核心：每3×3窗口算一次均值）
        if(de_dly[0]) begin
            local_mean <= (row1[0] + row1[1] + row1[2] +
                           row2[0] + row2[1] + row2[2] +
                           row3[0] + row3[1] + row3[2]) / 9;
        end

        // 4. 动态自适应二值化（全图处理，无ROI限制）
        if(de_dly[1]) begin // 仅保留de有效判断，去掉ROI判断
            // 动态阈值 = 局部均值 + THRESH_OFFSET
            bin_out <= (gray_in > local_mean + THRESH_OFFSET) ? 8'd255 : 8'd0;
        end else begin
            bin_out <= 8'd0;
        end
    end
end

endmodule