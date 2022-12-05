module cpu #(
    parameter CPU_CLOCK_FREQ = 50_000_000,
    parameter RESET_PC = 32'h4000_0000,
    parameter BAUD_RATE = 115200
) (
    input clk,
    input rst,
    input bp_enable,
    input serial_in,
    output serial_out
);
    // FIXME: Add ZERO things out on rst


    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    reg [11:0] bios_addra, bios_addrb;
    reg [31:0] bios_douta, bios_doutb;
    reg bios_ena, bios_enb;
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
    reg [13:0] dmem_addr;
    reg [31:0] dmem_din, dmem_dout;
    reg [3:0] dmem_we;
    reg dmem_en;
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
    reg [31:0] imem_dina, imem_doutb;
    reg [13:0] imem_addra, imem_addrb;
    reg [3:0] imem_wea;
    reg imem_ena;
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
    reg [7:0] uart_tx_data_in;
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
    reg [31:0] tohost_csr;

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

    // Bits that determine which unit to read from
    reg [3:0] mem_out_sel;

    /*
    Control logic values
    */

    // Selecting next PC
    reg [2:0] pc_sel;
    // Selecting inst from BIOS or IMEM
    reg inst_sel;
    // Selection whether to input a nop or not
    reg is_j;
    // Selecting whether to forward from WB to Decode
    reg wb2d_a, wb2d_b;
    // Selecting values for branch comparison
    reg brun;
    // Selecting values that input to the ALU
    reg [1:0] asel, bsel;
    // Selecting operation performed by the ALU
    reg [3:0] alu_sel;
    // Selects whether the memory unit reads or writes.
    reg mem_rw;
    // Selects which memory unit to read from
    reg [1:0] mem_sel;
    // Selects writeback values
    reg [1:0] wb_sel;
    // Select reg wr en
    reg reg_wen;
    // Is equal to 1 when the branch is set to taken.
    reg br_taken;
    // Predicted value for branch prediction
    reg br_pred_taken;
    // Mispredict — returns true if the branch mispredicted.
    reg mispredict;

    reg pred_taken;
    always @(posedge clk) pred_taken <= br_pred_taken;

    reg [31:0] rs1_fd, rs2_fd, csr_reg;

    control_logic cl (
      // Inputs
      .clk(clk),
      .inst_fd(inst_fd),
      .inst_x(inst_x),
      .inst_mw(inst_mw),
      .brlt(brlt),
      .breq(breq),
      .pred_taken(pred_taken),
      .mem_out_sel(mem_out_sel),
      // Outputs
      .pc_sel(pc_sel),
      .is_j(is_j),
      .wb2d_a(wb2d_a),
      .wb2d_b(wb2d_b),
      .brun(brun),
      .reg_wen(reg_wen),
      .asel(asel),
      .bsel(bsel),
      .alu_sel(alu_sel),
      .mem_rw(mem_rw),
      .wb_sel(wb_sel),
      .br_taken(br_taken),
      .mispredict(mispredict),
      .mem_sel(mem_sel)
    );

    /* Fetch and Decode Section
      1. Calculate next PC based on PCSel (control logic)
         given PC + 4, ALU, and PC + imm as options
      2. Use IMEM to find the instruction stored at addr
         Simultaneously, find the instruction stored at addr in BIOS
         Choose between IMEM and BIOS based on PC[30] (InstSel)
      3. If isJump Control Signal is true, change the instruction to 13.
      4. Read in regFile values of ra1 and ra2

      5. From Writeback stage -> handle wa and rd.
      6. Output rs1 and rs2, selecting between each and WB with the control signal MW2D-A and MW2D-B

      7. Register the values of PC, rs1, rs2, immediate, and instruction
      8. Don't register the value of PC if isJump = true (stall)
    */

    // PC updater
    reg [31:0] next_pc;
    wire [31:0] pc_imm = pc_fd + imm_fd;
    wire [31:0] rs1_imm = rs1_fd + imm_fd;

    fetch_next_pc # (
        .RESET_PC(RESET_PC)
    ) fn (
      // Inputs
      .clk(clk),
      .rst(rst),
      .pc(pc_fd),
      .pc_imm(pc_imm),
      .rs1_imm(rs1_imm),
      .alu(alu_x),
      .pc_sel(pc_sel),
      .br_taken(br_taken),
      .br_pred_taken(br_pred_taken),
      .mispredict(mispredict),
      // Outputs
      .next_pc(next_pc)
    );

    reg [31:0] br_taken_cache;
    always @(posedge clk) begin
      br_taken_cache <= br_taken;
    end

    wire fd_is_branch = inst_fd[6:0] == 7'h63;
    wire x_is_branch = inst_x[6:0] == 7'h63;
    wire mw_is_branch = inst_mw[6:0] == 7'h63;
    branch_predictor bpred (
      .clk(clk),
      .reset(rst),
      .pc_guess(pc_fd),
      .is_br_guess(bp_enable && fd_is_branch),

      // TODO: Make sure this isn't doing worse
      // by making more cache misses
      .pc_check(pc_mw),
      .is_br_check(bp_enable && mw_is_branch),
      .br_taken_check(br_taken_cache),

      .br_pred_taken(br_pred_taken)
    );

    assign bios_ena = 1;
    assign inst_sel = pc_fd[30];
    fetch_instruction fi (
      // Inputs
      .pc(next_pc),
      .bios_dout(bios_douta),
      .imem_dout(imem_doutb),
      .is_j(is_j),
      .inst_sel(inst_sel),
      // Outputs
      .bios_addr(bios_addra),
      .imem_addr(imem_addrb),
      .inst(inst_fd)
    );

    immediate_generator immgen (
      // Inputs
      .inst(inst_fd),
      // Outputs
      .imm(imm_fd)
    );

    // Sets ra1 and ra2
    // Handles forwarding for rs1, rs2 and wb_val
    read_from_reg regread (
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
      .rs1(rs1_fd),
      .rs2(rs2_fd)
    );

    // Writeback
    assign we = reg_wen;
    assign wa = inst_mw[11:7];
    assign wd = wb_val;

    reg [31:0] rs1, rs2;
    always @(posedge clk) begin
      if (rst) begin
        pc_fd <= RESET_PC;
        pc_x <= 0;
        imm_x <= 0;
        inst_x <= 0;
        rs1 <= 0;
        rs2 <= 0;
      end else begin
        pc_fd <= next_pc;
        pc_x <= pc_fd;
        imm_x <= imm_fd;
        inst_x <= (mispredict) ? 32'h13 : inst_fd;
        rs1 <= rs1_fd;
        rs2 <= rs2_fd;
      end
    end

    // You can take the counters out of the critical path for slightly worse
    // functionality.
    wire reset_counters = alu_mw == 32'h80000018;

    /*
      Cycle counter for system.
    */
    reg [31:0] cycle_count;
    always @(posedge clk) begin
      if (rst  || reset_counters) begin
        cycle_count <= 0;
      end else begin
        cycle_count <= cycle_count + 1;
      end
    end

    /*
      Instruction Counter for system.
      Increments every time a new pc enters the system. Does not count nops.
    */
    reg [31:0] inst_count;
    always @(posedge clk) begin
      if (rst || reset_counters) begin
        inst_count <= 0;
      end else begin
        if (!is_j && (pred_taken == br_taken)) begin
            inst_count <= inst_count + 1;
        end
      end
    end

    reg [31:0] branch_counter;
    always @(posedge clk) begin
      if (rst || reset_counters) begin
        branch_counter <= 0;
      end else begin
        if (mw_is_branch) begin
          branch_counter <= branch_counter + 1;
        end
      end
    end

    reg [31:0] branch_correct;
    always @(posedge clk) begin
      if (rst || reset_counters) begin
        branch_correct <= 0;
      end else begin
        if (x_is_branch && !mispredict) begin
          branch_correct <= branch_correct + 1;
        end
      end
    end


    /*
      Execute Section
      1. Given PC_X + RS1 + RS2 + IMM_X + INST_X
      2. Calculate branch prediction — takes BrUN as input and outputs BrLT and BrEq
      3. Pre-ALU MUX — based on ASel and BSel — choose between different values the input to the ALU.
      3. ALU — takes rs1 and rs2 as inputs and returns the calculated output based on ALUSel
      4. Forward ALU val to MEM and circle back to next PC for jalr
    */

    reg [31:0] rs1_br, rs2_br;
    reg [31:0] rs1_in, rs2_in;


    always @(posedge clk) begin
      if (rst) begin
        tohost_csr <= 0;
      end else begin
        // I type CSR
        if (inst_x[6:0] == 7'h73) begin
          if (inst_x[14] == 1) begin
              tohost_csr <= imm_x;
          end else begin
              tohost_csr <= rs1_br;
          end
        end
      end
    end

    ex_forwarding forwarder (
      // Inputs
      .rs1(rs1),
      .rs2(rs2),
      .wb_val(wb_val),
      .asel(asel),
      .bsel(bsel),
      .pc(pc_x),
      .imm(imm_x),
      // Outputs
      .rs1_in(rs1_in),
      .rs2_in(rs2_in),
      .rs1_br(rs1_br),
      .rs2_br(rs2_br)
    );

    branch_comp comparator (
      // Inputs
      .brun(brun),
      .rs1(rs1_br),
      .rs2(rs2_br),
      // Outputs
      .brlt(brlt),
      .breq(breq)
    );


    alu alunit (
      // Inputs
      .rs1(rs1_in),
      .rs2(rs2_in),
      .alu_sel(alu_sel),
      // Outputs
      .out(alu_x)
    );

    always @(posedge clk) begin
      if (rst) begin
        pc_mw <= 0;
        inst_mw <= 0;
        alu_mw <= 0;
        imm_mw <= 0;
      end else begin
        pc_mw <= pc_x;
        inst_mw <= inst_x;
        alu_mw <= alu_x;
        imm_mw <= imm_x;
      end
    end


    /*
      Memory and Writeback Section
      1. Memory Prep Operations:
        - To calculate addr, choose between alu_x and imm_x + wb basd on prevmrs1
        - To calculate data, choose between wb and rs2 basd on PrevMem
      2. Memory operations
        - Write to IMEM if relevant
        - Read from BIOS and DMEM
        - Load extend DMEM
        - Choose between BIOS and DMEM as relevant
      3. Writeback
        - Choose between PC + 4, ALU_MW and Mem based on WBSEL
        - Writeback in DECODE stage the value based on RegWEn
    */

    reg [31:0] mem_bios_dout;
    reg [31:0] mem_dmem_dout;

    // Writing to DMEM
    reg [3:0] wr_mask;
    gen_wr_mask masker (
      .inst(inst_x),
      .addr(alu_x),
      .mask(wr_mask)
    );


    reg [31:0] data_in;
    data_in_gen datagen (
      .in(rs2_br),
      .mask(wr_mask),
      .out(data_in)
    );

    // Reading from DMEM
    always @(*) begin
      if (alu_x[31:30] == 2'b00 && alu_x[28] == 1) begin
        dmem_addr = alu_x[15:2];
        dmem_en = 1;
        dmem_din = data_in;
        dmem_we = wr_mask;
      end else begin
        dmem_addr = 0;
        dmem_en = 0;
        dmem_din = 0;
        dmem_we = 0;
      end
    end
    assign mem_dmem_dout = dmem_dout;

    // Reading from BIOS
    assign bios_addrb = alu_x[13:2];
    assign bios_enb = 1;
    assign mem_bios_dout = bios_doutb;

    // Read from UART

    wire [31:0] alu_uart = alu_x;
    wire [31:0] inst_uart = inst_x;

    reg [31:0] uart_data_out;
    wire uart_op = alu_uart[31:28] == 4'b1000;
    always @(*) begin
      if (uart_op && (inst_uart[6:0] == 7'h03)) begin
        // UART control signal
        case (alu_uart[7:0])
          'h0: uart_data_out = {30'b0, uart_rx_data_out_valid, uart_tx_data_in_ready};
          'h4: uart_data_out = {24'b0, uart_rx_data_out};
          'h10: uart_data_out = cycle_count;
          'h14: uart_data_out = inst_count;
          'h1c: uart_data_out = branch_counter;
          'h20: uart_data_out = branch_correct;
          default: uart_data_out = 32'b0;
        endcase
      end
      // Default
      else begin
        uart_data_out = 32'b0;
      end
    end

    // Write to UART
    always @(*) begin
      if (uart_op && inst_uart[6:0] == 7'h23 && alu_uart[3:0] == 'h8) begin
          uart_tx_data_in = data_in[7:0];
      end else begin
        uart_tx_data_in = 8'b0;
      end
    end

    // Assign control signals, check instruction is actually a UART command
    assign uart_rx_data_out_ready = (alu_uart == 32'h80000004) && (inst_uart[6:0] == 7'h03);
    assign uart_tx_data_in_valid = (alu_uart == 32'h80000008) && (inst_uart[6:0] == 7'h23);


    // Write to IMEM
    assign imem_ena = 1;
    always @(*) begin
      if (alu_x[31:29] == 3'b001 && pc_x[30] == 1) begin
        imem_addra = alu_x[15:2];
        imem_dina = data_in;
        imem_wea = wr_mask;
      end else begin
        imem_addra = 0;
        imem_dina = 0;
        imem_wea = 0;
      end
    end

    reg [31:0] bios_lex;
    load_extender blexer (
      .in(mem_bios_dout),
      .out(bios_lex),
      .inst(inst_mw),
      .addr(alu_mw)
    );

    reg [31:0] dmem_lex;
    load_extender lexer (
      .in(mem_dmem_dout),
      .out(dmem_lex),
      .inst(inst_mw),
      .addr(alu_mw)
    );

    reg [31:0] uart_out;
    always @(posedge clk) uart_out <= uart_data_out;

    reg [31:0] uart_lex;
    assign uart_lex = uart_out;

    assign mem_out_sel = alu_mw[31:28];
    wb_selector wber (
      // Inputs
      .mem_bios_dout(bios_lex),
      .dmem_lex(dmem_lex),
      .uart_out(uart_lex),
      .pc(pc_mw),
      .alu(alu_mw),
      .wb_sel(wb_sel),
      .mem_sel(mem_sel),
      // Outputs
      .wb_val(wb_val)
    );

endmodule
