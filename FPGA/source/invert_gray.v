module invert_gray (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        de_in,
    input  wire [7:0]  gray_in,
    output reg         de_out,
    output reg  [7:0]  gray_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            de_out <= 1'b0;
            gray_out <= 8'd0;
        end else begin
            de_out <= de_in;
            gray_out <= 8'd255 - gray_in;   // È¡·´
        end
    end
endmodule