# Validation status

- File paths and module/port wiring: static checks performed during packaging.
- Original source modules: hash-checked against the supplied uploads.
- Python fixture/receiver: syntax and binary-format tests performed during packaging.
- Node protocol parser (Project 10): 6 tests passed. Backend/frontend JavaScript syntax checked.
- HDL simulation: testbench supplied, **not run here**; no simulator installed.
- Vivado synthesis/implementation/timing/resource fit: **not run here**.
- Physical Ethernet, FPGA programming, ILA and UART: **not tested here**.

Do not relabel static checks as hardware verification. Testbench PASS criteria are expected assertions, not a claim that this package has already produced that result on your board.
