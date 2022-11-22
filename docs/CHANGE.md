## Changelog
1. Bug fix: Adding rst register in case rst signal goes low in the middle of a cycle. The register helps make sure we null out `inst_fd` in case rst signal was high before.
2. Bug fix: ALU signal for SRA and SRL were not being correctly generated from the control logic. 
3. Bug fix: changed the assignment of immediate upper 20 bits, ensure sign extension. 
4. Logic Update: the thirteen bits being pulled out of pc are not [13:0] but [15:2]. This is reflected in FETCH INST.
5. Logic Update: Since DMEM output needs to be delayed by one clock cycle and `rd` is equal to `inst_mw[11:7]`, we need to delay `rd` by one clock cycle as well.