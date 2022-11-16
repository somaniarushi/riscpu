module cpu #(
    parameter CPU_CLOCK_FREQ = 50_000_000,
    parameter RESET_PC = 32'h4000_0000,
    parameter BAUD_RATE = 115200
) (
    input clk,
    input rst,
    input serial_in,
    output serial_out
);
    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    wire [11:0] bios_addra, bios_addrb;
    wire [31:0] bios_douta, bios_doutb;
    wire bios_ena, bios_enb;
    bios_mem bios_mem (
      .clk(clk),
      .ena(bios_ena),
      .addra(bios_addra),
      .douta(bios_douta),
      .enb(bios_enb),
      .addrb(bios_addrb),
      .doutb(bios_doutb)
    );

    // Data Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [13:0] dmem_addr;
    wire [31:0] dmem_din, dmem_dout;
    wire [3:0] dmem_we;
    wire dmem_en;
    dmem dmem (
      .clk(clk),
      .en(dmem_en),
      .we(dmem_we),
      .addr(dmem_addr),
      .din(dmem_din),
      .dout(dmem_dout)
    );

    // Instruction Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [31:0] imem_dina, imem_doutb;
    wire [13:0] imem_addra, imem_addrb;
    wire [3:0] imem_wea;
    wire imem_ena;
    imem imem (
      .clk(clk),
      .ena(imem_ena),
      .wea(imem_wea),
      .addra(imem_addra),
      .dina(imem_dina),
      .addrb(imem_addrb),
      .doutb(imem_doutb)
    );

    // Register file
    // Asynchronous read: read data is available in the same cycle
    // Synchronous write: write takes one cycle
    reg we;
    reg [4:0] ra1, ra2, wa;
    reg [31:0] wd;
    wire [31:0] rd1, rd2;
    reg_file rf (
        .clk(clk),
        .we(we),
        .ra1(ra1), .ra2(ra2), .wa(wa),
        .wd(wd),
        .rd1(rd1), .rd2(rd2)
    );

    // On-chip UART
    //// UART Receiver
    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    wire uart_rx_data_out_ready;
    //// UART Transmitter
    wire [7:0] uart_tx_data_in;
    wire uart_tx_data_in_valid;
    wire uart_tx_data_in_ready;
    uart #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) on_chip_uart (
        .clk(clk),
        .reset(rst),

        .serial_in(serial_in),
        .data_out(uart_rx_data_out),
        .data_out_valid(uart_rx_data_out_valid),
        .data_out_ready(uart_rx_data_out_ready),

        .serial_out(serial_out),
        .data_in(uart_tx_data_in),
        .data_in_valid(uart_tx_data_in_valid),
        .data_in_ready(uart_tx_data_in_ready)
    );

    // CSR handling
    reg [31:0] tohost_csr = 0;

    // The PCs for the instructions in the pipeline
    reg [31:0] pc_fd;
    reg [31:0] pc_x;
    reg [31:0] pc_mw;

    // The three instructions in the pipeline
    reg [31:0] inst_fd;
    reg [31:0] inst_x;
    reg [31:0] inst_mw;

    // The immediate value associated with the instruction.
    reg [31:0] imm_fd;
    reg [31:0] imm_x;
    reg [31:0] imm_mw;

    // The ALU output associated with the stage.
    reg [31:0] alu_x;
    reg [31:0] alu_mw;

    // The memory and writeback value associated with the instruction.
    reg [31:0] mem_val;
    reg [31:0] wb_val;

    // Values inputed into control logic from branch comp
    reg brlt, breq;

    /*
    Control logic values
    */

    // Selecting next PC
    reg [1:0] pc_sel;
    // Selecting inst from BIOS or IMEM
    reg inst_sel;
    // Selection whether to input a nop or not
    reg is_j_or_b;
    // Selecting whether to forward from WB to Decode
    reg mw2d_a, mw2d_b;
    // Selecting values for branch comparison
    reg brun;
    // Selecting values that input to the ALU
    reg [1:0] asel, bsel;
    // Selecting operation performed by the ALU
    reg [31:0] alu_sel;

    control_logic cl (
      // Inputs
      .inst_fd(inst_fd),
      .inst_x(inst_x),
      .inst_mw(inst_mw),
      .brlt(brlt),
      .breq(breq),
      // Outputs
      .pc_sel(pc_sel),
      .is_j_or_b(is_j_or_b),
      .wb2d_a(wb2d_a),
      .wb2d_b(wb2d_b),
      .brun(brun),
      .asel(asel),
      .bsel(bsel),
      .alu_sel(alu_sel)
    );

    /* Fetch and Decode Section
      1. Calculate next PC based on PCSel (control logic)
         given PC + 4, ALU, and PC + imm as options
      2. Use IMEM to find the instruction stored at addr
         Simultaneously, find the instruction stored at addr in BIOS
         Choose between IMEM and BIOS based on PC[30] (InstSel)
      3. If isJump Control Signal is true, change the instruction to 13. (#TODO: Execute)
      4. Read in regFile values of ra1 and ra2

      5. From Writeback stage -> handle wa and rd. (#TODO: Writeback)
      6. Output rs1 and rs2, selecting between each and WB with the control signal MW2D-A and MW2D-B (#TODO: Writeback)

      7. Register the values of PC, rs1, rs2, immediate, and instruction
      8. Don't register the value of PC if isJump = true (stall)
    */

    // PC updater
    reg [31:0] next_pc;
    fetch_next_pc(
      // Inputs
      .pc(pc_fd),
      .imm(imm_fd),
      .alu(alu_x),
      .pc_sel(pc_sel),
      // Outputs
      .next_pc(next_pc)
    );


    assign bios_ena = 1; // FIXME: ???
    assign imem_ena = 1;

    assign inst_sel = pc_fd[30]; // Lock in inst_sel to it's corresponding value

    fetch_instruction (
      // Inputs
      .pc(pc_fd),
      .bios_dout(bios_douta),
      .imem_dout(imem_doutb),
      .is_j_or_b(is_j_or_b),
      .inst_sel(inst_sel),
      // Outputs
      .bios_addr(bios_addra),
      .imem_addr(imem_addrb),
      .inst(inst_fd),
    );

    immediate_generator (
      // Inputs
      .inst(inst_fd),
      // Outputs
      .imm(imm_fd)
    );


    reg [31:0] rs1, rs2;

    // TODO: we (write enable) set??
    read_from_reg (
      // Inputs
      .inst(inst_fd),
      .wb2d_a(wb2d_a),
      .wb2d_b(wb2d_b),
      .rd1(rd1),
      .rd2(rd2),
      .wb_val(wb_val),
      // Outputs
      .ra1(ra1),
      .ra2(ra2),
      .rs1(rs1),
      .rs2(rs2)
    );

    // Writeback TODO

    // Clocking block
    always @(posedge clk) begin
      pc_x <= pc_fd;
      inst_x <= inst_fd;
      pc_fd <= (is_j_or_b) ? pc_fd : next_pc; // Is is j or b -> insert nop
    end

    assign imm_x = imm_fd;

    /*
      Execute Section
      1. Given PC_X + RS1 + RS2 + IMM_X + INST_X
      2. Calculate branch prediction — takes BrUN as input and outputs BrLT and BrEq
      3. Pre-ALU MUX — based on ASel and BSel — choose between different values the input to the ALU.
      3. ALU — takes rs1 and rs2 as inputs and returns the calculated output based on ALUSel
      4. Forward ALU val to MEM and circle back to next PC for jalr
    */

    branch_predictor (
      // Inputs
      .brun(brun),
      .rs1(rs1),
      .rs2(rs2),
      // Outputs
      .brlt(brlt),
      .breq(breq)
    );

    reg [31:0] rs1_in, rs2_in;

    ex_forwarding(
      // Inputs
      .rs1(rs1),
      .rs2(rs2),
      .mem(mem_val),
      .alu(alu_mw),
      .asel(asel),
      .bsel(bsel),
      // Outputs
      .rs1_in(rs1_in),
      .rs2_in(rs2_in)
    );

    alu (
      // Inputs
      .rs1(rs1_in),
      .rs2(rs2_in),
      .alu_sel(alu_sel),
      // Outputs
      .out(alu_x)
    );

    always @(posedge clk) begin
      pc_mw <= pc_x;
      inst_mw <= inst_x;
      alu_mw <= alu_x;
      imm_mw <= imm_x;
    end

endmodule
