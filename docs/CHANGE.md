## Changelog
1. Bug fix: Adding rst register in case rst signal goes low in the middle of a cycle. The register helps make sure we null out `inst_fd` in case rst signal was high before.
2. Bug fix: ALU signal for SRA and SRL were not being correctly generated from the control logic. 
3. Bug fix: changed the assignment of immediate upper 20 bits, ensure sign extension. 
4. Logic Update: the thirteen bits being pulled out of pc are not [13:0] but [15:2]. This is reflected in FETCH INST.
5. Logic Update: Since DMEM output needs to be delayed by one clock cycle and `rd` is equal to `inst_mw[11:7]`, we need to delay `rd` by one clock cycle as well.
6. Logic Update: half-word stores don't mean storing the top or bottom half, they mean storing the bottom half into the top half LOCATION. Same for bytes.
7. Bug Fix: Forwarding WB->FD should only happen if rd exists in MW instruction.
8. Bug fix: Writing to rd doesn't need reg write en to be clocked.
9. Bug fix: changed the inst_fd assignment to next_inst as synchronous instead of clocked in the rst block.
10. Bug fix: Because the PC is calculated one cycle before the instruction, in JAL handling, we insert a nop in the FD pipeline (`x_is_jal`). Then, we resolve next_pc using EX stage values instead of FD stage values (for the same reason). 
11. Bug Fix: Swapped the pc + 4 value in next_pc to be pc_fd. Because we are inserting a nop, we want to pc to stay at the same value if the branch is not taken so we can run the instruction at that pc. 
12. Logic Update: The CSRI immediate value is stored in the rs1 location, needed to index into instruction to retrieve, then assign to CSR. Passed the second CSRRWI test as well as all hazard tests. Moved immediate logic to imm_generator. 