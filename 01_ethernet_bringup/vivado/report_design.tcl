# Run after successful synthesis in this project's Vivado session.
open_run synth_1
file mkdir reports
report_utilization -hierarchical -file reports/utilization.rpt
report_timing_summary -report_unconstrained -file reports/timing.rpt
report_clock_interaction -file reports/clock_interaction.rpt
report_cdc -file reports/cdc.rpt
