**1. How many stages is the datapath you’ve drawn? (i.e. How many cycles does it take to execute 1 instruction?)**

3-cycle datapath, divided into FD/X/MW

1. **How do you handle ALU → ALU hazards?**

```
addi x1, x2, 100
addi x2, x1, 100
```

ALU to ALU forwarding (see purple).

The value of the output of the ALU is stored at the end of the EX stage, and can therefore be forwarded to the next instruction coming into the ALU.

From here, the crucial step becomes determining whether to select the forwarded value or not. This is chosen by a control signal `ALU2ALU`A and `ALU2ALU`B, which is `True` iff `rd` and `rs1/rs2` clash. These are calculated by the control signal handler ingesting `

1. **How do you handle ALU → MEM hazards?**

```
addi x1, x2, 100
sw x1, 0(x3)
```

First, we outline the conflict. Occurs when `addi` is in the writeback stage and the `sw` instruction is in the decode stage. Since we are using synchronous reads and writes we cannot read and write from the same register in the same cycle. At the end of this cycle, the x1 value read in holds the previous value.

To fix this, we enable forwarding from the writeback value `val`. We add a mux at the start of the MEM stage, choosing between `val` and `rs2` with the control signal `PrevMem`.

`PrevMem` is calculated in the EX stage and passed onto the WB stage in order to give us access to both instructions `instX` and `instMW`. To determine whether a hazard is occurring, we check the equivalence between `rd` of `instMW` and the `rs2` of `instX`.

4 **How do you handle MEM → ALU hazards?**

```
lw x1, 0(x3)
addi x1, x1, 100
```

The hazard occurs when `addi` is in the EX stage and `lw` is in the WB stage. `addi` has a dependency on x1, and it is being written to in the first instruction.

To fix this, we implement MEM to ALU forwarding logic with the writeback value `val`. We change the mux before the ALU to a 4-channel mux and ensure the control signal `ASel` can handle 4 different inputs. We use `ASel` to choose the `mem` input on the mux instead of `rs1`, so that the newly obtained value from the WB stage is forwarded to our EX stage.

5. **How do you handle MEM → MEM hazards?**

```
lw x1, 0(x2)
sw x1, 4(x2)
```

These hazards will be correctly handled by `PrevMem` — since `PrevMem` detects a conflict between `rd` of the `writeback` stage and `rs2` of the next stage. Here, the same conflict exists, and `x1` will be updated to represent the correct value.

also consider:

```
lw x1, 0(x2)
sw x3, 0(x1)
```

This is a conflict between `rd` and `rs1` and therefore cannot be handled by our `PrevMem` handler. Instead, we introduce another signal `PrevMRS1` that is calculated in the EX stage and registered and forwarded to the MW stage. It is calculated using `instX` and `instMW`, which would allow us to easily detect conflicts.

If there is a conflict, we update the value of `addr` (`rs1 + imm`) to be `val + imm`, where `val` is the output of the previously executed stage. `imm` is forwarded from the previous part as well. Cons: This increases the net time spent in the MW stage by one adder. However, assuming this isn’t the critical path, we save time by not introducing a stall.

1. **Do you need special handling for 2-cycle apart hazards?**

```
addi x1, x2, 100
nop
addi x1, x1, 100
```

Yes, we do need special handling. Let’s clarify the error here. When `x1` is in the writeback stage, `addi x1, x1, 100` is being decoded — which means `rs1` will evaluate to the stale value of `x1` because of synchronous read-writes.

Our solution involves a control signal `MW2D`, which detects a `rs1-rd` conflict or `rs2-rd` conflict between `instFD` and `instMW`. If there is a conflict, we use the value `val` that is a wire connected to the output of the final mux in the WB stage. This would update the value of `rs1/rs2` to the correct value going into the `ALU`.

We believe this extends the length of the critical path, however — still think this is the best technique to handle this conflict.

1. **How do you handle branch control hazards? (What is the mispredict latency, what prediction scheme are you using, are you just injecting NOPs until the branch is resolved, what about data hazards in the branch?)**

We are not including branch prediction right now. Instead, given `instX` is a branching instruction, we freeze PC (turning off WE) and insert a nop. After EX is done, we know whether we want to take the branch or not, and have the correct value of the PC (forwarded from the ALU). We update these and keep going.

To fix this we inject one NOP. We add a mux that chooses between the next instruction and the NOP instruction `ADDI x0, x0, 0`  using the control signal `isBorJ`. In this way, whenever there is a branch or jump instruction in the EX stage, instead of reading in the next instruction with some branch prediction we run the NOP.

This causes a latency of 1 stalled cycle. This also prevents any wrongly predicted instructions from writing into memory and creating data hazards.



1. **How do you handle jump control hazards? Consider jal and jalr separately. What optimizations can be made to special-case handle jal?**

We handle for jump hazards using forwarding to the Fetch stage (here, FD).

First, we consider `jal`. For `jal`, we need `PC + imm`. We calculate `imm` in the decode stage, and have `PC` from fetch. Thus, we can resolve the branch by `FD`. We create a forwarding from the end of `FD` to update the `PC` correctly. The `jal` instruction continues through the pipeline and writes `rd` = `PC + 4` correctly using pre-existing structures.

Next, we consider `jalr`. Since we need both `rs1` and `imm` in `jalr`, we must use the ALU. We considered creating an extra `adder` to attempt to resolve this in the `FD` stage —however, this would not account for forwarding and other hazard handlings. It is therefore, better in our opinion to insert a `nop` in the pipeline while the `ALU` calculates the next PC. We do this in a similar fashion to branch hazard handling (see above) — here the condition is if the `instX` is a `jalr`.

1. **What is the most likely critical path in your design?**

We suspect that the F/D stage is the critical path in our design. This is because we assume that the IMEM/BIOS block + the Regfile block + an arbitrary number of muxes + the PC register all collectively take more time than any other stage. This is because memory fetching is typically more inefficient that simple calculations or muxes.

1. **Where do the UART modules, instruction, and cycle counters go? How are you going to drive `uart_tx_data_in_valid` and `uart_rx_data_out_ready` (give logic expressions)?**

The UART modules, instruction and cycle counters are in the MEM stage (MW) with DMEM.

Logic Expressions:

`uart_tx_data_in_valid` = addr is in I/O part of memory AND instruction is load.

`uart_rx_data_out_ready` = addr is in I/O part of memory AND instruction is store.

1. **What is the role of the CSR register? Where does it go?**

We put the CSR in the decode (F/D) stage. This is because, in the decode stage, we have all the values we need to correctly set the CSR. The CSR is supposed to demonstrate the “end” of a program to the user. While the program is executing, the CSR register’s value is `0`. When the program is successfully done evaluating, it is `1`. When the program aborts or errors, it is a non-zero value that is not one.

1. **When do we read from BIOS for instructions? When do we read from IMem for instructions?**

BIOS is our underlying instruction fetching system. When we get the location of a program that we want to run from our UART, then BIOS instructions are read, which details how to load the instructions of this program into memory, and finally jump to it.

Once we are in this program space, we read from IMEM to get subsequent instructions in that program.



1. **How do we switch from BIOS address space to IMem address space? In which case can
we write to IMem, and why do we need to write to IMem? How do we know if a memory
instruction is intended for DMem or any IO device?**

BIOS at the end of loading all the instructions jumps to the first instruction of the program. This tranfers us to IMEM address space. We can write to IMEM when we are loading a program while in BIOS before we jump to IMEM address space. Our memory architecture defines restrictions upon PCs based on what part of the program we’re executing from (IMEM/BIOS). While we’re in BIOS, we want to be writing to IMEM. While we’re in IMEM, we want to be writing to DMEM. We enforce this using control signals that determine the write-enabling of all these sections.