# RISCV-CPU

Made for EECS151: Introduction to Digital Design on the FPGA @ Berkeley.

## To Run Locally
One needs an FPGA to do so. From there, please consult the Makefile. To run the simulation compilation, run `make synth`. To run the tests, run `make test`. To upload the program onto an FPGA, run `make program`, then boot up the screen using `set SERIALTTY 560000` and then `screen`.

## Fun Features
The base structure is a **4-stage pipeline** with branch prediction and forwarding. The branch predictor is a direct cache, though the implementation of a two-set associative cache is also available. There is an implementation of a 5-stage pipeline as well. There is also a "double-fetch" implementation — two fetch pipelines simultaneously executing two statements, such that there is no need for bubble insertion for jumps or branches.

## Resources
- RISC-V Instruction Set Manual: https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf
- Hardware for Machine Learning: https://inst.eecs.berkeley.edu//~ee290-2
- MIT Eyeriss Tutorial: http://eyeriss.mit.edu/tutorial.html
- FPGA Labs FA22: https://github.com/EECS150/fpga_labs_fa22
