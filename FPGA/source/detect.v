module plate_detect
(
    input               clk,
    input               rst_n,
    
    input               vsync,
    input               hsync,
    input               de,
    input               img_bit,
    
    output reg [9:0]    box_top,
    output reg [9:0]    box_bottom,
    output reg [9:0]    box_left,
    output reg [9:0]    box_right,
    output reg          box_valid
);

// 所有变量声明 全部放在最顶部 (修复报错)
integer i;
integer j;

// 水平投影
reg [10:0] h_cnt;
reg [9:0]  h_project [0:511];
reg [9:0]  h_max_val;
reg [9:0]  h_max_pos;
reg [9:0]  h_min_pos;

// 垂直投影
reg [10:0] v_cnt;
reg [9:0]  v_project [0:959];
reg [9:0]  v_max_val;
reg [9:0]  v_min_pos;
reg [9:0]  v_max_pos;

// 水平投影计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        h_cnt <= 0;
    end else if(vsync) begin
        h_cnt <= 0;
    end else if(de) begin
        h_cnt <= h_cnt + 1'b1;
    end
end

// 水平投影积分
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<512;i=i+1) h_project[i] <= 0;
    end else if(vsync) begin
        for(i=0;i<512;i=i+1) h_project[i] <= 0;
    end else if(de && img_bit) begin
        h_project[h_cnt] <= h_project[h_cnt] + 1'b1;
    end
end

// 找水平峰值
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        h_max_val <= 0;
        h_max_pos <= 0;
    end else if(vsync) begin
        h_max_val <= 0;
        h_max_pos <= 0;
    end else if(de) begin
        if(h_project[h_cnt] > h_max_val) begin
            h_max_val <= h_project[h_cnt];
            h_max_pos <= h_cnt;
        end
    end
end

// 垂直投影
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        v_cnt <= 0;
    end else if(vsync) begin
        v_cnt <= 0;
    end else if(de) begin
        v_cnt <= v_cnt + 1'b1;
    end
end

// 垂直投影积分
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(j=0;j<960;j=j+1) v_project[j] <= 0;
    end else if(vsync) begin
        for(j=0;j<960;j=j+1) v_project[j] <= 0;
    end else if(de && img_bit) begin
        v_project[v_cnt] <= v_project[v_cnt] + 1'b1;
    end
end

// 输出最终框
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        box_top    <= 0;
        box_bottom <= 0;
        box_left   <= 0;
        box_right  <= 0;
        box_valid  <= 0;
    end else if(vsync) begin
        box_top    <= h_max_pos - 30;
        box_bottom <= h_max_pos + 30;
        box_left   <= 100;
        box_right  <= 800;
        box_valid  <= 1;
    end
end

endmodule