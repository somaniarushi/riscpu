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
13. Bug fix: Updating ALUSEL to handle for LUI instructions by passin on IMM within any operations with RS1.
14. Bug fix: Immediate sign extension in immediate generator.
15. Logic update: Moved CSR tohost value generation from the FD to the X stage. Previously, it was loading into tohost old values stored in a register when we haven't finished writing to it. 
16. Bug Fix: Removed logic from loading FD rs1/rs2 values into X stage branch rs1 and rs2. Was used as means to write to rd in CSR instructions, but per spec, rd in CSR instructions will always be x0 and thus never written to.
17. Bug fix: For SHAMT instructions, only extract lowermost 5 bits from the immediate.
18. Bug fix: Sign extend immediates for store instructions.
19. Bug fix: Add logic to check that the instruction must be load or store for UART before turning on UART handshake interface values. All echo tests passed immediately :)
20. Bug fix: Sign extend the load from BIOS.
21. Bug fix: Remove sign extension for UART.
22. Bug fix: Update testbench to allow for stalling period.(300 -> 500, line 61 bios_tb)
23. Logic Update: Instead of the input to the IMEM being `pc_in`, let the input to IMEM be `next_pc`. This will allow updating the IMEM in one cycle for jal/jalr/branches.
24. Bug fix: Set IMEM_ENA = 1 to enable writing to the IMEM. This will make the FPGA work.
25. Bug fix: Fix UARt indexing to be 8 bits to account for cycle/instruction counting read properly.
26. change `pc_sel` to be set on the negative clock edge to account for COMBINATIONAL LOOP alert. Equivalently, change `is_br_guess` to simply `bp_enable`.
27. Logic Update: Changed branch prediction logic. Wrapped pc selection in bp_enable condition. Saving prior branch prediction and compare with branch taken boolean to determine pc. 
28. Logic Update: Resolving jal in one clock cycle.
29. Bug fix: Making sure that jalr does not error when transistioning, thus allowing jal (resolved in fd) to function properly.