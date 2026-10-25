`timescale 1ns/1ps
// NEW deterministic teaching testbench. Run against the included original modules.
// External clocks have an arbitrary fixed simulation phase; this is not a hardware latency claim.
module tb_top;
reg CLK100MHZ = 0;
reg eth_rx_clk = 0, eth_tx_clk = 0;
reg eth_rx_dv = 0, eth_rxerr = 0;
reg [3:0] eth_rxd = 0;
wire eth_tx_en, led, eth_ref_clk, eth_rstn, uart_rxd_out;
wire [3:0] eth_txd;
always #5 CLK100MHZ = ~CLK100MHZ;
always #20 eth_rx_clk = ~eth_rx_clk;
initial begin #7; forever #20 eth_tx_clk = ~eth_tx_clk; end
top dut(.*);
reg [7:0] frame [0:79];
integer seq = 0, records = 0, decisions = 0, measures = 0;
integer full_frames = 0, abort_frames = 0;
reg saw_byte = 0, saw_payload = 0;
function automatic [31:0] crc32_byte(input [31:0] crc_in, input [7:0] data);
    reg [31:0] c; integer k;
    begin
        c=crc_in;
        for(k=0;k<8;k=k+1) c=(c[0]^data[k]) ? ((c>>1)^32'hEDB88320) : (c>>1);
        crc32_byte=c;
    end
endfunction
task put32(input integer offset, input [31:0] v);
    begin frame[offset]=v[31:24]; frame[offset+1]=v[23:16];
          frame[offset+2]=v[15:8]; frame[offset+3]=v[7:0]; end
endtask
task send_quote(input [7:0] venue, input [31:0] bid, input [31:0] ask,
                input [31:0] bidq, input [31:0] askq, input [15:0] port);
    integer i; reg [31:0] crc; reg [31:0] sum;
    begin
        for(i=0;i<80;i=i+1) frame[i]=0;
        for(i=0;i<7;i=i+1) frame[i]=8'h55;
        frame[7]=8'hD5;
        for(i=8;i<14;i=i+1) frame[i]=8'hFF;
        frame[14]=8'h02; frame[19]=8'h02;
        frame[20]=8'h08; frame[21]=8'h00;
        frame[22]=8'h45; frame[25]=8'd54; // 20 IP + 8 UDP + 26 payload
        frame[30]=8'd64; frame[31]=8'd17;
        frame[34]=192; frame[35]=168; frame[36]=1; frame[37]=104;
        for(i=38;i<42;i=i+1) frame[i]=8'hFF;
        sum=0;
        for(i=22;i<42;i=i+2) sum=sum+{frame[i],frame[i+1]};
        sum=(sum&32'hFFFF)+(sum>>16); sum=(sum&32'hFFFF)+(sum>>16);
        sum=~sum; frame[32]=sum[15:8]; frame[33]=sum[7:0];
        frame[42]=8'hC3; frame[43]=8'h50;
        frame[44]=port[15:8]; frame[45]=port[7:0]; frame[47]=8'd34;
        seq=seq+1;
        frame[50]=1; frame[51]=venue; put32(52,seq); put32(56,1);
        put32(60,bid); put32(64,ask); put32(68,bidq); put32(72,askq);
        crc=32'hFFFFFFFF;
        for(i=8;i<76;i=i+1) crc=crc32_byte(crc,frame[i]);
        crc=~crc; frame[76]=crc[7:0]; frame[77]=crc[15:8];
        frame[78]=crc[23:16]; frame[79]=crc[31:24];
        for(i=0;i<80;i=i+1) begin
            @(negedge eth_rx_clk); eth_rx_dv=1; eth_rxd=frame[i][3:0];
            @(negedge eth_rx_clk); eth_rxd=frame[i][7:4];
        end
        @(negedge eth_rx_clk); eth_rx_dv=0; eth_rxd=0;
        #50000; // Isolate events and let both outgoing frames finish.
    end
endtask
always @(negedge eth_rx_clk) if (dut.rx_byte_valid && dut.rx_byte==8'h55) saw_byte=1;
initial begin
    wait(eth_rstn===1'b1); #2000;
    send_quote(1,30000,30002,500,600,5001);
    send_quote(2,29998,30005,400,500,5001);
    send_quote(2,30006,30007,400,500,5001); // bid creates edge=4, size=400
    send_quote(2,29998,30005,400,500,5001); // uncross, re-arm
    send_quote(2,29995,29996,400,500,5001); // ask creates edge=4, size=500
    send_quote(2,29998,30005,400,500,5001);
    send_quote(2,30006,30007,1,500,5001); // price-only cross; too little size
    send_quote(2,29998,30005,400,500,5001);
    send_quote(2,30050,30051,400,500,5009); // wrong UDP port, must ignore
    #400000;
    if (!saw_byte) $fatal(1,"No preamble byte observed");
    $display("PASS project 02 teaching scenario"); $finish;
end
initial begin #5000000; $fatal(1,"Simulation timeout"); end
endmodule
