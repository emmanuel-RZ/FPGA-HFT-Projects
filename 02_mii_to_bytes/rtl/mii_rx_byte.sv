module mii_rx_byte(
    input  logic       rx_clk,
    input  logic       rst_n,
    input  logic       rx_dv,
    input  logic       rx_er,
    input  logic [3:0] rxd,
    output logic [7:0] rx_byte,
    output logic       rx_byte_valid
);

logic       half_byte;
logic [3:0] low_nibble;

always_ff @(posedge rx_clk or negedge rst_n) begin
    if (!rst_n) begin
        half_byte <= 1'b0;
        low_nibble <= 4'b0;
        rx_byte <= 8'b0;
        rx_byte_valid <= 1'b0;
    end else begin
        rx_byte_valid <= 1'b0;

        if (rx_dv && !rx_er) begin
            if (!half_byte) begin
                low_nibble <= rxd;
                half_byte <= 1'b1;
            end else begin
                rx_byte <= {rxd, low_nibble};
                rx_byte_valid <= 1'b1;
                half_byte <= 1'b0;
            end
        end else begin
            half_byte <= 1'b0;
        end
    end
end

endmodule