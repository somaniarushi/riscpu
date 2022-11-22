module control_logic (
    input clk,
    input [31:0] inst_fd,
    input [31:0] inst_x,
    input [31:0] inst_mw,
    input brlt,
    input breq,
    output reg [1:0] pc_sel,
    output reg is_j_or_b,
    output reg wb2d_a,
    output reg wb2d_b,
    output reg brun,
    output reg reg_wen,
    output reg [1:0] asel,
    output reg [1:0] bsel,
    output reg [3:0] alu_sel,
    output reg bios_dmem,
    output reg mem_rw,
    output reg [1:0] wb_sel
);

    // Setting PCSel
    /*
        1. If the instruction in inst-FD is a JAL instruction, it's time to jump -> PC + imm, PC Sel = 0
        2. If the branch of inst-X is taken or inst-X is JALR, then jump to ALU value -> ALU, PC Sel = 1
        3. If none of the above 2 are true, go to PC + 4, PC Sel = 2
    */
    wire fd_is_jal, x_is_jal, x_is_jalr, x_branch_taken;
    // assign fd_is_jal = inst_fd[6:0] == 7'h6F;
    assign x_is_jal = inst_x[6:0] == 7'h6F;
    assign x_is_jalr = inst_x[6:0] == 7'h67 && inst_x[14:12] == 3'h0;
    assign x_branch_taken = 0; // FIXME: DO BRANCHING

    always @(*) begin
        if (x_is_jalr || x_branch_taken) begin
            pc_sel = 1;
        end else if (x_is_jal) begin
            pc_sel = 0;
        end else begin
            pc_sel = 2;
        end
    end

    // Setting isJorB
    /*
        1. If inst-X is a JALR instruction, set to true.
        2. If inst-X is a branch instruction, set to true.
        TODO: Anything missing here?
    */
    wire x_is_branch;
    assign x_is_branch = inst_x[6:0] == 7'h63;
    always @(*) begin
        if (x_is_jalr || x_is_branch || x_is_jal) begin
            is_j_or_b = 1;
        end else begin
            is_j_or_b = 0;
        end
    end

    wire mw_rd_exists = inst_mw[6:0] != 7'h63 && inst_mw[6:0] != 7'h23;
    wire fd_rs1_exists = inst_fd[6:0] == 7'h33 || inst_fd[6:0] == 7'h23 || inst_fd[6:0] == 7'h63 || inst_fd[6:0] == 7'h03 ||inst_fd[6:0] == 7'h13 || inst_fd[6:0] == 7'h67 || inst_fd[6:0] == 7'h73;
    wire fd_rs2_exists = inst_fd[6:0] == 7'h33 || inst_fd[6:0] == 7'h23 || inst_fd[6:0] == 7'h63;

    // Setting wb2d-a
    /* Conflict between rs1 when rd of inst-MW = rs1 of inst-FD. */
    wire [4:0] rd_instmw, rs1_instfd;
    assign rd_instmw = inst_mw[11:7];
    assign rs1_instfd = inst_fd[19:15];
    always @(*) begin
        if ((rd_instmw == rs1_instfd) && mw_rd_exists && fd_rs1_exists) begin // a conflict exists, forwarding required
            wb2d_a = 1;
        end else begin
            wb2d_a = 0;
        end
    end

    // Setting wb2d-b
    /* Conflict between rs2 when rd of inst-MW  = rs2 of inst-FD. */
    wire [4:0] rs2_instfd;
    assign rs2_instfd = inst_fd[24:20];
    always @(*) begin
        if ((rd_instmw == rs2_instfd) && mw_rd_exists && fd_rs2_exists) begin
            wb2d_b = 1;
        end else begin
            wb2d_b = 0;
        end
    end

    // Setting brUN
    /* Branch unsigned = 1 if the inst type is B and func3[3:1] == "11" */
    wire x_is_unsigned = inst_x[14:12] == 3'b110 || inst_x[14:12] == 3'b111; // BLTU or BGEU
    always @(*) begin
        if (x_is_branch && x_is_unsigned) begin
            brun = 1;
        end else begin
            brun = 0;
        end
    end

    // Setting ASEL
    /*
        ASel[0] = 0 when RS1 is used. 1 when PC is used. Instruction is AUIPC, or jump or branch
        ASel[1] = 1 when WB forwarding is used. Conflict between rs1 and rd.
    */
    wire [4:0] rs1_instx;
    assign rs1_instx = inst_x[19:15];
    wire x_rs1_exists; // rs1 exists in types R, I, S, and B
    wire [6:0] x_opc = inst_x[6:0];
    assign x_rs1_exists = x_opc == 7'h33 || x_opc == 7'h23 || x_opc == 7'h63 || x_opc == 7'h03 ||x_opc == 7'h13 || x_opc == 7'h67 || x_opc == 7'h73;

    always @(*) begin
        // Forwarding Conflict
        if ((rd_instmw == rs1_instx) && x_rs1_exists && mw_rd_exists) begin
            asel[1] = 1;
        end else begin
            asel[1] = 0;
        end

        // PC or rs1
        if (inst_x[6:0] == 7'h17 || inst_x[6:0] == 7'h6F || inst_x[6:0] == 7'h63) begin
            asel[0] = 1;
        end else begin
            asel[0] = 0;
        end
    end

    // Setting BSEL
    /*
        BSel[0] = 0 when RS1 is used. 1 when IMM is used. If the instruction is not an R-type, select IMM.
        BSel[1] = 1 when WB forwarding is used. Conflict] between rs2 and rd.
    */
    wire [4:0] rs2_instx = inst_x[24:20];
    wire x_rs2_exists; // Needs to be R, S, or B type
    assign x_rs2_exists = x_opc == 7'h33 || x_opc == 7'h23 || x_opc == 7'h63;
    always @(*) begin
        // Forwarding
        if ((rd_instmw == rs2_instx) && x_rs2_exists && mw_rd_exists) begin
            bsel[1] = 1;
        end else begin
            bsel[1] = 0;
        end

        // IMM vs PC
        if (inst_x[6:0] != 7'h33) begin
            bsel[0] = 1;
        end else begin
            bsel[0] = 0;
        end
    end

    wire [2:0] x_func3 = inst_x[14:12];
    wire [6:0] x_func7 = inst_x[31:25];

    // Setting ALUSel
    /*
        ADD = 0, SUB = 1, SLL = 2, SLT = 3
        SLTU = 4, XOR = 5, SRL = 6, SRA = 7, OR = 8,
        AND = 9
    */
    // For R-Type
    always @(*) begin
        if (x_opc == 7'h33) begin
            case (x_func3)
                3'b000: alu_sel = (x_func7 == 7'b0) ? 0 : 1;
                3'b001: alu_sel = 2;
                3'b010: alu_sel = 3;
                3'b011: alu_sel = 4;
                3'b100: alu_sel = 5;
                3'b101: alu_sel = (x_func7 == 7'b0) ? 6 : 7;
                3'b110: alu_sel = 8;
                3'b111: alu_sel = 9;
                default: alu_sel = 0;
            endcase
        end
        // For I-Type instructions
        else if (x_opc == 7'h13 || x_opc == 7'h67 || x_opc == 7'h73) begin
            case (x_func3)
                3'b000: alu_sel = 0;
                3'b001: alu_sel = 2;
                3'b010: alu_sel = 3;
                3'b011: alu_sel = 4;
                3'b100: alu_sel = 5;
                3'b101: alu_sel = (x_func7 == 7'b0) ? 6 : 7;
                3'b110: alu_sel = 8;
                3'b111: alu_sel = 9;
                default: alu_sel = 0;
            endcase
        end
        // For every other instruction -> default to add
        else begin
            alu_sel = 0;
        end
    end

    // Setting bios_dmem
    /*
        If bios_dmem = 1, then use BIOS. Otherwise, use DMEM.
    */
    always @(*) begin
        bios_dmem = 0;
    end

    // Setting MemRW
    /*
    1. If the instruction is an S-type, then write, otherwise read.
    */
    always @(*) begin
        if (inst_x[6:0] == 7'h23) begin // TODO: inst_mw?
            mem_rw = 1;
        end else begin
            mem_rw = 0;
        end
    end

    // Setting RegWen
    /*
        1. If the type of instruction is not branch or store, we're writing to RD.
        2. Otherwise, set to 0.
    */
    reg register_wen;
    always @(*) begin
        // Instruction is branch or store.
        if (inst_mw[6:0] == 7'h23 || inst_mw[6:0] == 7'h63) begin
            register_wen = 0;
        end else begin
            register_wen = 1;
        end
    end

    always @(posedge clk) begin
        reg_wen <= register_wen;
    end

    // Setting WBSEL
    /*
        1. If inst_mw = jal or jalr -> writing PC + 4. WBSEL = 2
        2. If inst_mw = lw | lh | lb -> writing Mem, WBSEL = 1
        3. Else -> writing ALU, WBSEL = 0
    */
    wire instmw_is_jalr = inst_mw[6:0] == 7'h67 && inst_mw[14:12] == 3'h0;
    wire instmw_is_jal = inst_mw[6:0] == 7'h6F;
    wire instmw_is_load = inst_mw[6:0] == 7'h03;
    always @(*) begin
        if (instmw_is_jal || instmw_is_jalr) begin
            wb_sel = 2;
        end else if (instmw_is_load) begin
            wb_sel = 1;
        end else begin
            wb_sel = 0;
        end
    end

endmodule