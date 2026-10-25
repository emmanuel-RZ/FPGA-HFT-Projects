# Teaching constraints assembled from the conversation pin mapping and Digilent's
# Arty-A7-35 master XDC (Rev D/E). D10 is FPGA TX -> USB-UART RX.
# Do not use A9 for uart_rxd_out; A9 is the opposite UART direction.
# This is a pin/primary-clock bring-up file, NOT completed external timing sign-off.
# No input/output delay budget or broad false-path suppression is invented here.
# Before deployment: close MII board/PHY I/O timing and review all CDC/reset paths.
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {CLK100MHZ}]
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {led}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {eth_ref_clk}]
set_property -dict {PACKAGE_PIN C16 IOSTANDARD LVCMOS33} [get_ports {eth_rstn}]
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS33} [get_ports {eth_rx_clk}]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports {eth_rx_dv}]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {eth_rxerr}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[0]}]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[1]}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[2]}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {eth_rxd[3]}]
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports {eth_tx_clk}]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {eth_tx_en}]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports {eth_txd[0]}]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports {eth_txd[1]}]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports {eth_txd[2]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {eth_txd[3]}]
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports {uart_rxd_out}]
create_clock -name sys_clk -period 10.000 [get_ports CLK100MHZ]
create_clock -name eth_rx_clock -period 40.000 [get_ports eth_rx_clk]
create_clock -name eth_tx_clock -period 40.000 [get_ports eth_tx_clk]
# The 40 ns periods are the 100 Mb/s MII teaching profile; do not run this
# constraint set for a PHY negotiated at 10 Mb/s.
