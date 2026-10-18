`timescale 1ns/1ps
// NEW simulation-only IP substitutes. NEVER add this file to synthesis.
// Models the 4:1 clock ratio, not the MMCM's analog behavior or lock timing.
module clk_wiz_0(input wire clk_in1, input wire reset,
                 output wire clk_out1, output reg locked = 0);
reg [1:0] divider = 0;
reg [4:0] lock_count = 0;
assign clk_out1 = divider[1];
always @(posedge clk_in1) begin
    if (reset) begin divider <= 0; lock_count <= 0; locked <= 0; end
    else begin
        divider <= divider + 1'b1;
        if (lock_count < 16) lock_count <= lock_count + 1'b1;
        else locked <= 1;
    end
end
endmodule
module ila_0(input wire clk, input wire [0:0] probe0, input wire [3:0] probe1, input wire [0:0] probe2);
endmodule
