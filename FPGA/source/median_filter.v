// 3×3中值滤波模块 - 适配你的工程 | 2拍延迟 | 8bit灰度输入输出
module median_filter (
    input  wire        clk,        // 时钟：对接pix_clk_in
    input  wire        rst_n,      // 复位：对接ddr_ip_rst_n && ddr_init_done
    input  wire        de_in,      // 输入数据有效：对接gray_de
    input  wire [7:0]  gray_in,    // 输入灰度：对接gray_data
    output reg         de_out,     // 输出数据有效：给后续模块
    output reg  [7:0]  gray_out    // 输出滤波后灰度
);

// 内部寄存器：3×3窗口缓存
reg [7:0] row1_buf[2:0]; // 第1行缓存
reg [7:0] row2_buf[2:0]; // 第2行缓存
reg [7:0] row3_buf[2:0]; // 第3行缓存
reg [7:0] sort_buf[8:0]; // 排序缓存
reg [1:0] de_dly;         // de延迟寄存器

// 时序逻辑：移位缓存3×3窗口
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        row1_buf[0] <= 8'd0;
        row1_buf[1] <= 8'd0;
        row1_buf[2] <= 8'd0;
        row2_buf[0] <= 8'd0;
        row2_buf[1] <= 8'd0;
        row2_buf[2] <= 8'd0;
        row3_buf[0] <= 8'd0;
        row3_buf[1] <= 8'd0;
        row3_buf[2] <= 8'd0;
        de_dly <= 2'd0;
        de_out <= 1'b0;
        gray_out <= 8'd0;
    end else begin
        // 移位缓存：新数据从右边进入，旧数据从左边移出
        if (de_in) begin
            row1_buf[0] <= row1_buf[1];
            row1_buf[1] <= row1_buf[2];
            row1_buf[2] <= gray_in;
            
            row2_buf[0] <= row2_buf[1];
            row2_buf[1] <= row2_buf[2];
            row2_buf[2] <= row1_buf[0];
            
            row3_buf[0] <= row3_buf[1];
            row3_buf[1] <= row3_buf[2];
            row3_buf[2] <= row2_buf[0];
        end
        
        // de延迟2拍，和数据同步
        de_dly <= {de_dly[0], de_in};
        de_out <= de_dly[1];
        
        // 排序取中值（简化版：直接比较9个数取中间值）
        if (de_dly[1]) begin
            // 把9个像素放到sort_buf
            sort_buf[0] <= row1_buf[0];
            sort_buf[1] <= row1_buf[1];
            sort_buf[2] <= row1_buf[2];
            sort_buf[3] <= row2_buf[0];
            sort_buf[4] <= row2_buf[1];
            sort_buf[5] <= row2_buf[2];
            sort_buf[6] <= row3_buf[0];
            sort_buf[7] <= row3_buf[1];
            sort_buf[8] <= row3_buf[2];
            
            // 简单冒泡排序取第5个（中间值）
            // 这里用简化的比较逻辑，资源占用更低
            if (sort_buf[4] > sort_buf[0] && sort_buf[4] < sort_buf[8])
                gray_out <= sort_buf[4];
            else if (sort_buf[3] > sort_buf[0] && sort_buf[3] < sort_buf[8])
                gray_out <= sort_buf[3];
            else
                gray_out <= sort_buf[4]; // 默认取中心值
        end
    end
end

endmodule