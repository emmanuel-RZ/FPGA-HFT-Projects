# New reproducibility scaffold. Run in a NEW Vivado session.
# source {C:/PentPort/02_mii_to_bytes/vivado/create_project.tcl}
set root [file normalize [file join [file dirname [info script]] ..]]
set target_part xc7a35ticsg324-1L
set project_name 02_mii_to_bytes
set out [file join $root build]
if {[llength [get_projects -quiet]] != 0} {error "Close the current project first; this script does not modify existing projects."}
if {[file exists [file join $out $project_name.xpr]]} {error "Project already exists. Open its .xpr instead, or rename the build folder for a fresh run."}
create_project $project_name $out -part $target_part
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set source_names {mii_rx_byte.sv top.sv}
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
set_property -dict [list CONFIG.C_NUM_OF_PROBES {3} CONFIG.C_DATA_DEPTH {1024} CONFIG.C_PROBE0_WIDTH {1} CONFIG.C_PROBE1_WIDTH {8} CONFIG.C_PROBE2_WIDTH {6}] [get_ips ila_0]
generate_target all [get_ips ila_0]
update_compile_order -fileset sources_1
puts "Project created. Run synthesis, inspect utilization and timing, then implementation."
puts "This script does not program hardware or overwrite your working project."
