// Teaching top reconstructed from the uploaded top.sv / top(1).sv.
// This is NOT an exact historical per-video snapshot. Core modules are preserved.
module top(
    input logic CLK100MHZ,
    input logic eth_rx_clk,
    input logic eth_rx_dv,
    input logic eth_rxerr,
    input logic [3:0] eth_rxd,
    input logic eth_tx_clk,
    output logic eth_tx_en,
    output logic [3:0] eth_txd,
    output logic led,
    output logic eth_ref_clk,
    output logic eth_rstn,
    output logic uart_rxd_out
);
logic clk25, clk_locked;
logic [26:0] blink_counter = 0;
logic [16:0] reset_counter = 0;
logic phy_ready = 0;
clk_wiz_0 u_clk (
    .clk_in1(CLK100MHZ), .reset(1'b0),
    .clk_out1(clk25), .locked(clk_locked)
);
always_ff @(posedge CLK100MHZ)
    blink_counter <= blink_counter + 1'b1;
assign eth_ref_clk = clk25;
always_ff @(posedge CLK100MHZ) begin
    if (!clk_locked) begin
        reset_counter <= 0;
        phy_ready <= 0;
    end else if (!phy_ready) begin
        if (reset_counter == 17'd99999) phy_ready <= 1;
        else reset_counter <= reset_counter + 1'b1;
    end
end
assign eth_rstn = phy_ready;

assign eth_tx_en = 1'b0;
assign eth_txd = 4'd0;
assign uart_rxd_out = 1'b1; // No UART measurement output in this project.
assign led = blink_counter[26]; // Heartbeat only, not feed/trade health.

ila_0 u_ila (
    .clk(eth_rx_clk),
    .probe0(eth_rx_dv),
    .probe1(eth_rxd),
    .probe2(eth_rxerr)
);
endmodule
