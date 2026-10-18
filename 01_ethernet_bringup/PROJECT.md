# Project 01 — Ethernet bring-up: clocks, reset and MII

**PentPort HFT Lab · FPGA mini-project series**  
**Goal:** Receive Ethernet activity and inspect the four-bit PHY interface.  
**Status:** source-based teaching reconstruction; not an exact archived video build.  
**Target profile:** Arty A7-35T, 100 MHz system clock, 100 Mb/s MII.  
**Scope:** simulated lab infrastructure only; no live brokerage connectivity.

## This project's mini-series

### A. What to build
The `top.sv` wrapper contains the source-derived heartbeat counter, clock-IP hookup, PHY reset holdoff and raw MII inputs. TX is held idle. No byte converter, parser or strategy is instantiated.

### B. What to inspect
In ILA, trigger `probe0` on `eth_rx_dv == 1`. Inspect `probe1` as hexadecimal nibbles and `probe2` as the RX error flag. This probe set is sampled in `eth_rx_clk`, not the unrelated 100 MHz system clock. The 25 MHz reference output is not a packet-valid indication.

### C. Finish the mini-series
Explain the difference between reference clock, RX clock, data-valid and the four-bit bus. Success is observing incoming activity on MII. It is not yet decoding a packet. If no activity appears, check cable, PHY reset, physical link and the sender's wired interface before writing a parser.


## Data path

```text
Clock / reset → raw MII → ILA
```

## Files included

| Path | Purpose |
|---|---|
| `rtl/` | Full lesson-specific top and every instantiated user RTL dependency |
| `constraints/arty_a7_35t.xdc` | Pins and primary clocks; external timing review still required |
| `vivado/create_project.tcl` | New standalone-project and IP-generation scaffold |
| `vivado/report_design.tcl` | Utilization, timing and CDC reports |
| `sim/` | New self-checking testbench, simulation-only IP stubs and run script |
| `tools/` | Optional new low-rate lab stimulus and receiver where relevant |
| `SOURCE_MAP.json` | Exact source origins and documented wrapper adaptations |
| `VALIDATION.md` | What was checked and what remains unverified |

## Build this project independently

1. **Extract this project to a short path**, for example `C:/PentPort/01_ethernet_bringup`. Do not work inside a ZIP and do not overwrite the working direct-feed project. All RTL needed for this lesson is in its own `rtl/` folder.
2. Open a **new Vivado session** with no project open. The target in `vivado/create_project.tcl` is `xc7a35ticsg324-1L`, the Arty A7-35T teaching profile. Verify your board/device marking before building; a different board needs its own part, constraints and resource review.
3. In Vivado's **Tcl Console**, run:
   ```tcl
   source {C:/PentPort/01_ethernet_bringup/vivado/create_project.tcl}
   ```
   Adjust only the folder prefix to where you extracted the project. The script creates a separate `build/` project, adds the explicit source list, sets `top`, and generates Clocking Wizard and this lesson's ILA when used. It does not program a device. Running it again will ask you to open the existing `.xpr` rather than silently overwrite it.
4. Check **Sources → Hierarchy**. Exactly one `top` should be present. No unresolved module icons should remain. Do not add `source_archive/`, `sim/ip_stubs.sv`, or files from another lesson as Design Sources.
5. Check the generated **Clocking Wizard**: input 100 MHz, output `clk_out1` 25 MHz, `locked` enabled, active-high `reset` enabled. This teaching wrapper connects reset to zero explicitly. The configuration scaffold is new; the original IP `.xci` files were not supplied.
6. Run **Synthesis**. Then run:
   ```tcl
   source {C:/PentPort/01_ethernet_bringup/vivado/report_design.tcl}
   ```
   Inspect LUTs, BRAM, clocks, unconstrained paths and CDC warnings. A successful parser/elaboration is not timing sign-off. Do not suppress resource-utilization DRC errors.
7. If synthesis is successful and you have reviewed the constraints, run **Implementation**, inspect timing, then **Generate Bitstream**. Do not use an old `.bit` after a failed build. This collection has not been synthesized, routed or hardware-tested in Vivado here.
8. Connect the board's USB/JTAG cable and Ethernet to an **isolated lab network**. In Hardware Manager, select the actual FPGA and program the newly generated `build/01_ethernet_bringup.runs/impl_1/top.bit`. When the lesson includes ILA, use the `.ltx` generated from that same implementation; when ILA is absent, clear the probes-file fields.
9. Wait for the Ethernet link to negotiate. These lessons assume **100 Mb/s MII**, with 25 MHz RX/TX clocks. A blinking user LED is generally only a system-clock heartbeat; it is not proof of parsing, a valid strategy or an exchange fill.

### When Clocking Wizard / ILA generation differs in your Vivado release

Use the IP Catalog to create `clk_wiz_0` and, when listed below, `ila_0` with the settings in this guide. Keep the port names and probe widths exact. Generate Output Products and update compile order. Do not replace a missing IP with an empty synthesis stub. The local simulation stubs exist only to exercise logic in a testbench.

## ILA configuration for this project

**Sampling clock:** `eth_rx_clk`. **Depth:** 1,024 samples. These probes observe one clock domain; do not swap the ILA clock independently of the signals.

| Probe | Width | Signal / packed fields |
|---:|---:|---|
| 0 | 1 | `eth_rx_dv` |
| 1 | 4 | `eth_rxd` |
| 2 | 1 | `eth_rxerr` |

## Supply input without changing PEX

**Using your existing lab:** keep PEX1/PEX2 and the legacy FPGA gateway on their already-working settings. The gateway's **26-byte UDP 5001** feed is the input for Projects 01–10. The later partitioned multicast streams do not match these decoders. The exchange/gateway C++ application remains an external dependency; its full source was not part of the uploads used here.

**Optional standalone teaching stimulus:** `tools/lab_quote_sender.py` is a newly written fixture sender so a student can run this lesson without the PEX services. It is not a replacement exchange and is not presented as the Python file from the original video. Run it only on an isolated lab subnet, with the existing gateway sender stopped/disconnected for this test; two sources feeding the same simple strategy can corrupt the demonstration.

From PowerShell in this project folder, for a wired PC whose actual local address is `192.168.1.50` on a `/24` lab subnet:

```powershell
py -3 tools/lab_quote_sender.py --bind 192.168.1.50 --broadcast 192.168.1.255 --cycles 10 --allow-lab-broadcast
```

Replace those example IPs with the PC's real wired-interface address and your lab subnet's broadcast. Do not assign an address already used by another device. The script sends at low rate, alternates two venues, creates bid- and ask-triggered crosses, uncrosses to re-arm, and sends a price cross with insufficient size. It does not send actual order-entry requests to an external broker.

## The legacy teaching packet used here

This is the **original simplified gateway protocol**, not the later ITCH-style/PXI2 direct feed. All multibyte fields below are unsigned big-endian. Prices are integer cents.

| Payload offset | Size | Meaning |
|---:|---:|---|
| 0 | 1 | Message type: 1 = quote |
| 1 | 1 | Venue: 1 = PEX1, 2 = PEX2 |
| 2–5 | 4 | Sequence |
| 6–9 | 4 | Legacy symbol ID |
| 10–13 | 4 | Bid price |
| 14–17 | 4 | Ask price |
| 18–21 | 4 | Bid size |
| 22–25 | 4 | Ask size |

Receive on UDP **5001**. In these historical modules, the strategy and outgoing order payload use **legacy symbol 1**. This is not direct-feed instrument ID 1001. Keeping that limitation is deliberate: these lessons document the earlier series; dynamic instruments belong to the separate experimental project.

The parser counts Ethernet-header bytes starting with destination MAC byte zero after the preamble/SFD. The decoder's payload offsets above begin at UDP payload byte zero. Do not mix these two index spaces.

## Repeatable logic test

A **new self-checking testbench** and simulation-only clock/ILA stubs are included. They are teaching support written for this package, not historical video files. They exercise the supplied RTL using valid serialized lab frames, a wrong-port frame, two cross directions, and an insufficient-size case where applicable.

Open a separate empty Vivado session and run:

```tcl
source {C:/PentPort/01_ethernet_bringup/sim/run_sim.tcl}
```

The test runs until `$finish`; look for `PASS project 01 teaching scenario` or a `$fatal` message. The simulation substitutes the clock generator/ILA, so it does **not** verify the physical PHY, MMCM lock behavior, jitter, metastability, I/O timing, board routing, or Vivado resource fit. These HDL testbenches are included but were **not executed in this environment**, which has no HDL simulator or Vivado installation. The completed local checks are listed in `VALIDATION.md`.

## Limits inherited from the source, not silently repaired

These are educational lab modules, not a production exchange adapter. The original parser assumes untagged Ethernet II, IPv4 with a 20-byte header, UDP 5001, a 26-byte payload, and its original preamble pattern. It does not implement a complete defensive IP/UDP length, FCS, fragmentation, VLAN, checksum or session-validation pipeline. It must not be attached to arbitrary market feeds and treated as production-safe.

The original arb uses stored quotes and a one-trade lock/re-arm rule; it does not implement quote-age limits, exchange acknowledgments, fill-based inventory, full risk limits or an atomic two-venue execution guarantee. The toggle-based CDC assumes events are spaced far enough apart and associated data stay stable; this is not a lossless general-purpose queue.

The supplied XDC contains verified pin assignments and primary clocks, **not completed board/PHY I/O timing or CDC sign-off**. It deliberately does not invent external delay budgets or hide CDC paths with broad false-path exceptions. Review timing and CDC reports before treating any programmed build as reliable hardware.

## Troubleshooting without mixing versions

| Symptom | Check first |
|---|---|
| Module not found | Add all files from this lesson's explicit source list as SystemVerilog; refresh hierarchy |
| Unconnected clock-IP reset | Use this wrapper and a generated `clk_wiz_0` with active-high reset enabled |
| ILA probes missing / corrupted | Use the matching `.bit` and `.ltx`, the correct probe widths and a running sample clock |
| No payload / quote | 100 Mb/s link, untagged IPv4 UDP 5001, exact 26-byte teaching payload |
| No trade | Correct legacy symbol 1, both venues initialized, gross edge >= 2 cents, size >= 100, lock re-armed |
| UDP receiver remains empty | This lesson actually includes TX; correct port 5002; one listener; broadcast reaches that host |
| UART monitor stays empty | Project 10 bitstream, D10 output, correct COM port, 1 Mbaud, no competing serial process |
| Dashboard says replay | Stop `--replay`; it is not FPGA data |

## Reference and provenance notes

Core `.sv` modules listed as unchanged in `SOURCE_MAP.json` are copied from the user's uploaded files. New material consists of the standalone `top.sv` wiring, IP/build scripts, board constraint assembly, fixture sender/receiver, testbench and, for Project 10, the paired teaching frontend/backend. Exact file hashes identify the copies. No exact per-video snapshot is claimed where none was supplied.

Additional primary references used only for the new setup scaffolding (not to replace PEX semantics):

- Digilent, Arty-A7-35 master XDC: https://github.com/Digilent/digilent-xdc/blob/master/Arty-A7-35-Master.xdc
- AMD, using IP Tcl commands: https://docs.amd.com/r/en-US/ug896-vivado-ip/Using-IP-Tcl-Commands-In-Design-Flows
- AMD, Clocking Wizard customization: https://docs.amd.com/r/en-US/ug939-vivado-designing-with-ip-tutorial/Step-3-Customize-the-Clocking-Wizard
- AMD, ILA product guide PG172: https://docs.amd.com/v/u/en-US/pg172-ila
- Node SerialPort usage: https://serialport.io/docs/guide-usage/
- `ws` project documentation: https://github.com/websockets/ws

The physical pin file does not substitute for timing verification. Reconstructed lesson numbers are an instructional sequence, not proof of the original publication dates or video numbering.

## Complete files

Each heading below is a path relative to this project directory. The same files are also supplied separately in the ZIP; no source needs to be copied from a different lesson. Generated Vivado output products, bitstreams and third-party npm dependencies are intentionally not embedded.

### `.gitignore`

````text
build/
sim_build/
.Xil/
*.jou
*.log
*.wdb
node_modules/
__pycache__/
````

### `PROJECT_META.json`

````json
{
  "project": 1,
  "slug": "01_ethernet_bringup",
  "title": "Ethernet bring-up: clocks, reset and MII",
  "goal": "Receive Ethernet activity and inspect the four-bit PHY interface.",
  "probe_clock": "eth_rx_clk",
  "probes": [
    {
      "index": 0,
      "signal": "eth_rx_dv",
      "width": 1
    },
    {
      "index": 1,
      "signal": "eth_rxd",
      "width": 4
    },
    {
      "index": 2,
      "signal": "eth_rxerr",
      "width": 1
    }
  ],
  "historical_exact_snapshot": false
}
````

### `SOURCE_MAP.json`

````json
{
  "rtl/top.sv": {
    "kind": "new teaching wrapper",
    "sources": [
      "top.sv",
      "top(1).sv"
    ],
    "changes": "Only the modules for this project are instantiated; explicit clock-IP reset; project-specific ILA probes. Project 8 disables speculative TX; project 5 latches the first decision on the LED."
  }
}
````

### `VALIDATION.md`

````markdown
# Validation status

- File paths and module/port wiring: static checks performed during packaging.
- Original source modules: hash-checked against the supplied uploads.
- Python fixture/receiver: syntax and binary-format tests performed during packaging.
- Node protocol parser (Project 10): 6 tests passed. Backend/frontend JavaScript syntax checked.
- HDL simulation: testbench supplied, **not run here**; no simulator installed.
- Vivado synthesis/implementation/timing/resource fit: **not run here**.
- Physical Ethernet, FPGA programming, ILA and UART: **not tested here**.

Do not relabel static checks as hardware verification. Testbench PASS criteria are expected assertions, not a claim that this package has already produced that result on your board.
````

### `constraints/arty_a7_35t.xdc`

````tcl
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
````

### `rtl/top.sv`

````systemverilog
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
````

### `sim/ip_stubs.sv`

````systemverilog
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
````

### `sim/run_sim.tcl`

````tcl
# NEW simulation-only project. Use a separate Vivado session from hardware builds.
set root [file normalize [file join [file dirname [info script]] ..]]
if {[llength [get_projects -quiet]] != 0} {error "Close the current project before this simulation-only run."}
create_project teaching_sim [file join $root sim_build] -part xc7a35ticsg324-1L -force
foreach f [glob -directory [file join $root rtl] *.sv] {add_files -norecurse $f}
add_files -fileset sim_1 -norecurse [list [file join $root sim ip_stubs.sv] [file join $root sim tb_top.sv]]
set_property top tb_top [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral
run all
close_sim
````

### `sim/tb_top.sv`

````systemverilog
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
    $display("PASS project 01 teaching scenario"); $finish;
end
initial begin #5000000; $fatal(1,"Simulation timeout"); end
endmodule
````

### `tools/lab_quote_sender.py`

````python
#!/usr/bin/env python3
"""New optional teaching stimulus; NOT the original Python sender or a PEX exchange.
Run only on an isolated lab network. It never executes/acknowledges/fills orders.
"""
import argparse
import socket
import struct
import time

def quote(venue, seq, bid, ask, bid_size, ask_size):
    return struct.pack('!BBIIIIII', 1, venue, seq, 1, bid, ask, bid_size, ask_size)

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--bind', required=True, help='IPv4 address of your WIRED adapter')
    p.add_argument('--broadcast', required=True, help='Lab subnet broadcast, e.g. 192.168.1.255')
    p.add_argument('--cycles', type=int, default=10)
    p.add_argument('--interval', type=float, default=0.05, help='Seconds between packets; >=0.01')
    p.add_argument('--allow-lab-broadcast', action='store_true')
    a = p.parse_args()
    if not a.allow_lab_broadcast: p.error('Explicit --allow-lab-broadcast is required')
    if not (1 <= a.cycles <= 1000) or a.interval < 0.01: p.error('Use 1..1000 cycles and interval >=0.01')
    socket.inet_aton(a.bind); socket.inet_aton(a.broadcast)
    # Prices in integer cents; symbol 1 is the legacy teaching namespace.
    scenarios = [
        ('PEX1 baseline', 1, 30000,30002,500,600),
        ('PEX2 baseline', 2, 29998,30005,400,500),
        ('BID cross', 2, 30006,30007,400,500),
        ('uncross', 2, 29998,30005,400,500),
        ('ASK cross', 2, 29995,29996,400,500),
        ('uncross', 2, 29998,30005,400,500),
        ('price cross but size 1: speculative abort', 2,30006,30007,1,500),
        ('uncross', 2,29998,30005,400,500),
    ]
    seq = 0
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        s.bind((a.bind,0))
        for _ in range(a.cycles):
            for label,v,bid,ask,bq,aq in scenarios:
                seq += 1
                s.sendto(quote(v,seq,bid,ask,bq,aq),(a.broadcast,5001))
                print(f'{seq}: {label}', flush=True)
                time.sleep(a.interval)
if __name__ == '__main__':
    try: main()
    except KeyboardInterrupt: pass
    except (OSError, ValueError) as e: raise SystemExit(f'Lab stimulus failed: {e}')
````

### `vivado/create_project.tcl`

````tcl
# New reproducibility scaffold. Run in a NEW Vivado session.
# source {C:/PentPort/01_ethernet_bringup/vivado/create_project.tcl}
set root [file normalize [file join [file dirname [info script]] ..]]
set target_part xc7a35ticsg324-1L
set project_name 01_ethernet_bringup
set out [file join $root build]
if {[llength [get_projects -quiet]] != 0} {error "Close the current project first; this script does not modify existing projects."}
if {[file exists [file join $out $project_name.xpr]]} {error "Project already exists. Open its .xpr instead, or rename the build folder for a fresh run."}
create_project $project_name $out -part $target_part
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set source_names {top.sv}
foreach name $source_names {
    set f [file join $root rtl $name]
    if {![file isfile $f]} {error "Missing RTL: $f"}
    add_files -norecurse $f
    set_property file_type SystemVerilog [get_files $f]
}
add_files -fileset constrs_1 -norecurse [file join $root constraints arty_a7_35t.xdc]
set_property top top [get_filesets sources_1]
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_wiz_0
set_property -dict [list CONFIG.PRIM_IN_FREQ {100.000} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.000} CONFIG.USE_RESET {true} CONFIG.RESET_TYPE {ACTIVE_HIGH} CONFIG.USE_LOCKED {true}] [get_ips clk_wiz_0]
generate_target all [get_ips clk_wiz_0]
create_ip -name ila -vendor xilinx.com -library ip -module_name ila_0
set_property -dict [list CONFIG.C_NUM_OF_PROBES {3} CONFIG.C_DATA_DEPTH {1024} CONFIG.C_PROBE0_WIDTH {1} CONFIG.C_PROBE1_WIDTH {4} CONFIG.C_PROBE2_WIDTH {1}] [get_ips ila_0]
generate_target all [get_ips ila_0]
update_compile_order -fileset sources_1
puts "Project created. Run synthesis, inspect utilization and timing, then implementation."
puts "This script does not program hardware or overwrite your working project."
````

### `vivado/report_design.tcl`

````tcl
# Run after successful synthesis in this project's Vivado session.
open_run synth_1
file mkdir reports
report_utilization -hierarchical -file reports/utilization.rpt
report_timing_summary -report_unconstrained -file reports/timing.rpt
report_clock_interaction -file reports/clock_interaction.rpt
report_cdc -file reports/cdc.rpt
````
