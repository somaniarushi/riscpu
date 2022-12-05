.section    .start
.global     _start

_start:

# Follow a convention
# x1 = result register 1
# x2 = result register 2
# x10 = argument 1 register
# x11 = argument 2 register
# x20 = flag register

# Test ADD
li x10, 100         # Load argument 1 (rs1)
li x11, 200         # Load argument 2 (rs2)
add x1, x10, x11    # Execute the instruction being tested
li x20, 1           # Set the flag register to stop execution and inspect the result register
                    # Now we check that x1 contains 300

# Test BEQ
li x2, 100          # Set an initial value of x2
beq x0, x0, branch1 # This branch should succeed and jump to branch1
li x2, 123          # This shouldn't execute, but if it does x2 becomes an undesirable value
branch1: li x1, 500 # x1 now contains 500
li x20, 2           # Set the flag register
                    # Now we check that x1 contains 500 and x2 contains 100

# TODO: add more tests here
li x10, 0
lui x10, 0x80000
addi x10, x10, 0x14
lw x1, 0(x10)
li x20, 3

li x10, 1000
jal x1, jump2
jump2: sw x1 0(x10)
lw x2 0(x10)
addi x2, x2, 100
li x20, 4

li x2, 100
jal x1, jump3
addi x10, x1, 1000
jump3: beq x2, x1, branch3
addi x2, x0, 100
j last
branch3: addi x2, x0, 150
last: li x20, 5


done: j done
