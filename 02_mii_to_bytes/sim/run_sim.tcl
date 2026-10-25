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
