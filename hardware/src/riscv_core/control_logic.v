`include "opcode.vh"

module control_logic (
    input clk,
    input bp_enable,
    input [31:0] inst_fd,
    input [31:0] inst_x,
    input [31:0] inst_mw,
    input brlt,
    input breq,
    input pred_taken,
    input [3:0] mem_out_sel,
    output reg [2:0] pc_sel,
    output reg is_j,
    output reg wb2d_a,
    output reg wb2d_b,
    output reg brun,
    output reg reg_wen,
    output reg [1:0] asel,
    output reg [1:0] bsel,
    output reg [3:0] alu_sel,
    output reg mem_rw,
    output reg [1:0] wb_sel,
    output reg br_taken,
    output reg mispredict,
    output reg [1:0] mem_sel
);

    // Setting PCSel
    /*
        1. If the instruction in inst-FD is a JAL instruction, it's time to jump -> PC + imm, PC Sel = 0
        2. If the branch of inst-X is taken or inst-X is JALR, then jump to ALU value -> ALU, PC Sel = 1
        3. If none of the above 2 are true, go to PC + 4, PC Sel = 2
    */
    wire [6:0] x_opc = inst_x[6:0];


    wire [2:0] x_func3 = inst_x[14:12];
    wire [6:0] x_func7 = inst_x[31:25];

    wire x_is_jal = x_opc == 7'h6F;
    wire x_is_jalr = x_opc == 7'h67;
    wire x_is_branch = x_opc == 7'h63;

    wire fd_is_branch = inst_fd[6:0] == 7'h63;
    wire fd_is_jal = inst_fd[6:0] == 7'h6F;
    wire fd_is_jalr = inst_fd[6:0] == 7'h67 && inst_fd[14:12] == 3'h0;

    wire mw_rd_exists = inst_mw[6:0] != 7'h63 && inst_mw[6:0] != 7'h23 && inst_mw[11:7] != 0;
    wire x_rd_exists = x_opc != 7'h63 && x_opc != 7'h23 && inst_x[11:7] != 0;
    wire fd_rs1_exists = inst_fd[6:0] == 7'h33 || inst_fd[6:0] == 7'h23 || inst_fd[6:0] == 7'h63 || inst_fd[6:0] == 7'h03 ||inst_fd[6:0] == 7'h13 || inst_fd[6:0] == 7'h67 || inst_fd[6:0] == 7'h73;
    wire fd_rs2_exists = inst_fd[6:0] == 7'h33 || inst_fd[6:0] == 7'h23 || inst_fd[6:0] == 7'h63;
    wire x_rs1_exists = x_opc == 7'h33 || x_opc == 7'h23 || x_opc == 7'h63 || x_opc == 7'h03 || x_opc == 7'h13 || x_opc == 7'h67 || x_opc == 7'h73;
    wire x_rs2_exists = x_opc == 7'h33 || x_opc == 7'h23 || x_opc == 7'h63;

    wire instmw_is_jalr = inst_mw[6:0] == 7'h67 && inst_mw[14:12] == 3'h0;
    wire instmw_is_jal = inst_mw[6:0] == 7'h6F;
    wire instmw_is_load = inst_mw[6:0] == 7'h03;

    wire [4:0] rd_instmw = inst_mw[11:7];
    wire [4:0] rs1_instfd = inst_fd[19:15];
    wire [4:0] rd_instx = inst_x[11:7];
    wire [4:0] rs2_instfd = inst_fd[24:20];
    wire [4:0] rs1_instx = inst_x[19:15];
    wire [4:0] rs2_instx = inst_x[24:20];

    wire fd_x_rs1_conflict = x_rd_exists && fd_rs1_exists && (rs1_instfd == rd_instx);
    reg fd_x_conflict_cache;
    always @(posedge clk) fd_x_conflict_cache <= fd_x_rs1_conflict;

    assign mispredict = x_is_branch && (br_taken != pred_taken);

    always @(*) begin
        if (mispredict) pc_sel = 1;
        else if (fd_is_branch) pc_sel = 3;
        else if (fd_is_jal) pc_sel = 4;
        else if (fd_is_jalr && !fd_x_rs1_conflict) pc_sel = 5;
        else if (x_is_branch) pc_sel = 1;
        else if (x_is_jalr && fd_x_conflict_cache) pc_sel = 2;
        else pc_sel = 0;
    end

    // Setting isJorB
    /*
        1. If inst-X is a JALR instruction, set to true.
        2. If inst-X is a branch instruction, set to true.
    */
    // If there was a conflict, then we're noping, otherwise,
    // We've already jumped to the right instruction.
    assign is_j = (x_is_jalr && fd_x_conflict_cache);

    // Setting wb2d-a
    /* Conflict between rs1 when rd of inst-MW = rs1 of inst-FD. */
    assign wb2d_a = (rd_instmw == rs1_instfd) && mw_rd_exists && fd_rs1_exists;

    // Setting wb2d-b
    /* Conflict between rs2 when rd of inst-MW  = rs2 of inst-FD. */
    assign wb2d_b = (rd_instmw == rs2_instfd) && mw_rd_exists && fd_rs2_exists;

    // Setting brUN
    /* Branch unsigned = 1 if the inst type is B and func3[3:1] == "11" */
    wire x_is_unsigned = x_func3 == `FNC_BLTU || x_func3 == `FNC_BGEU; // BLTU or BGEU
    assign brun = x_is_branch && x_is_unsigned;

    // Set br_taken

    always @(*) begin
        if (x_is_branch) begin
            case (x_func3)
                `FNC_BEQ: br_taken = breq;
                `FNC_BNE: br_taken = !breq;
                `FNC_BLT: br_taken = brlt;
                `FNC_BGE: br_taken = !brlt;
                `FNC_BLTU: br_taken = brlt;
                `FNC_BGEU: br_taken = !brlt;
            endcase
        end else begin
            br_taken = 0;
        end
    end

    // Setting ASEL
    /*
        ASel[0] = 0 when RS1 is used. 1 when PC is used. Instruction is AUIPC, or jump or branch
        ASel[1] = 1 when WB forwarding is used. Conflict between rs1 and rd.
    */
    assign asel[1] = (rd_instmw == rs1_instx) && x_rs1_exists && mw_rd_exists;
    assign asel[0] = (x_opc == 7'h17 || x_opc == 7'h6F || x_opc == 7'h63);

    // Setting BSEL
    /*
        BSel[0] = 0 when RS1 is used. 1 when IMM is used. If the instruction is not an R-type, select IMM.
        BSel[1] = 1 when WB forwarding is used. Conflict] between rs2 and rd.
    */
    assign bsel[1] = (rd_instmw == rs2_instx) && x_rs2_exists && mw_rd_exists;
    assign bsel[0] = x_opc != 7'h33 && x_opc != 7'h73;

    // Setting ALUSel
    /*
        ADD = 0, SUB = 1, SLL = 2, SLT = 3
        SLTU = 4, XOR = 5, SRL = 6, SRA = 7, OR = 8,
        AND = 9, PASSIMM = 10
    */
    // For R-Type
    always @(*) begin
        if (x_opc == 7'h33 || x_opc == 7'h13 || x_opc == 7'h67) begin
            case (x_func3)
                3'b000: alu_sel = (x_opc == 7'h33 && x_func7 != 7'b0);
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
        // If instruction = LUI, set alu to pass immediate onwards
        else if (x_opc == 7'h37) begin
            alu_sel = 10;
        end
        // For every other instruction -> default to add
        else begin
            alu_sel = 0;
        end
    end

    // Setting MemRW
    /*
    1. If the instruction is an S-type, then write, otherwise read.
    */
    assign mem_rw = x_opc == 7'h23;

    always @(*) begin
        case (mem_out_sel)
            4'b0100: mem_sel = 2;
            4'b1000: mem_sel = 1;
            default: mem_sel = 0;
        endcase
    end

    // Setting RegWen
    /*
        1. If the type of instruction is not branch or store, we're writing to RD.
        2. Otherwise, set to 0.
    */
    assign reg_wen = mw_rd_exists;

    // Setting WBSEL
    /*
        1. If inst_mw = jal or jalr -> writing PC + 4. WBSEL = 2
        2. If inst_mw = lw | lh | lb -> writing Mem, WBSEL = 1
        3. Else -> writing ALU, WBSEL = 0
    */
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