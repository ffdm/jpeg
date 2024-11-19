`include "define.vh"
module ycbcr2rgb (
    input clk, rstn,
    input unsigned [7:0] y, cb, cr, // signed (N,R)=(16,7)
    input vld_i,
    output reg [7:0] r, g, b,      // unsigned 8 bits
    output reg vld_o
);

wire [16:0] r_tmp;      // (22,14)
wire [16:0] g_tmp;
wire [16:0] b_tmp;

wire [7:0] r_round;  // (8,0) all integer values
wire [7:0] g_round;
wire [7:0] b_round;

wire [16:0] r_tmp1, r_tmp3;
wire [16:0] g_tmp1, g_tmp2, g_tmp3;
wire [16:0] b_tmp1, b_tmp2; 

assign r_tmp1 = ((y << 8) + (y << 5) + (y << 3) + (y << 1)) >> 8;  // 256+32+8+2 = 298
assign r_tmp3 = ((cr << 8) + (cr << 7) + (cr << 4) + (cr << 3)) >> 8; // 256+128+16+8 = 408

assign g_tmp1 = ((y << 8) + (y << 5) + (y << 3) + (y << 1)) >> 8; 
assign g_tmp2 = ((cb << 6) + (cb << 5) + (cb << 2)) >> 8;   // 64+32+4=100
assign g_tmp3 = ((cr << 7) + (cr << 6) + (cr << 4)) >> 8; // 128+64+16=208

assign b_tmp1 = ((y << 8) + (y << 5) + (y << 3) + (y << 1)) >> 8; // 298
assign b_tmp2 = ((cb << 9) + (cb << 2)) >> 8; // 512+4=516

// Color Transformation
assign r_tmp  = r_tmp1 + r_tmp3 - 223;
assign g_tmp  = g_tmp1 - g_tmp2 - g_tmp3 + 136;
assign b_tmp  = b_tmp1 + b_tmp2 - 277;

// Set max value to 255
assign r_round  = |r_tmp[16:8] ? 8'd255 : r_tmp[7:0];
assign g_round  = |g_tmp[16:8] ? 8'd255 : g_tmp[7:0];
assign b_round  = |b_tmp[16:8] ? 8'd255 : b_tmp[7:0];

always @(posedge clk, negedge rstn) begin 
    if (!rstn) begin
        r <= 0;
        g <= 0;
        b <= 0;
        vld_o <= 0;
    end else begin
        if (vld_i) begin
            r <= r_round;
            g <= g_round;
            b <= b_round;
            vld_o <= 1;
        end else begin
            r <= 0;
            g <= 0;
            b <= 0;
            vld_o <= 0;
        end
    end
end

endmodule