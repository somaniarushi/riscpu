module control_logic (
    input [31:0] inst_fd,
    input [31:0] inst_x,
    input [31:0] inst_mw,
    // TODO: branch comparator input
    output reg [1:0] pc_sel,
    output reg is_j_or_b,
    output reg wb2d_a,
    output reg wb2d_b
);

    // Setting PCSel
    /*
        1. If the instruction in inst-FD is a JAL instruction, it's time to jump -> PC + imm, PC Sel = 0
        2. If the branch of inst-X is taken or inst-X is JALR, then jump to ALU value -> ALU, PC Sel = 1
        3. If none of the above 2 are true, go to PC + 4, PC Sel = 2
    */
    wire fd_is_jal, x_is_jalr, x_branch_taken;
    assign fd_is_jal = inst_fd[6:0] == 7'h6F;
    assign x_is_jalr = inst_x[6:0] == 7'h67 && inst_x[14:12] == 3'h0;
    assign x_branch_taken = 0; // FIXME: DO BRANCHING

    always @(*) begin
        if (x_is_jalr || x_branch_taken) begin
            pc_sel = 1;
        end else if (fd_is_jal) begin
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
        if (x_is_jalr || x_is_branch) begin
            is_j_or_b = 1;
        end else begin
            is_j_or_b = 0;
        end
    end

    // Setting wb2d-a
    /* Conflict between rs1 when rd of inst-MW = rs1 of inst-FD. */
    wire rd_instmw, rs1_instfd;
    assign rd_instmw = inst_mw[11:7];
    assign rs1_instfd = inst_fd[19:15];
    always @(*) begin
        if (rd_instmw == rs1_instfd) begin // a conflict exists, forwarding required
            wb2d_a = 1;
        end else begin
            wb2d_a = 0;
        end
    end

    // Setting wb2d-b
    /* Conflict between rs2 when rd of inst-MW  = rs2 of inst-FD. */
    wire rs2_instfd;
    assign rs2_instfd = inst_fd[24:20];
    always @(*) begin
        if (rd_instmw == rs2_instfd) begin
            wb2d_b = 1;
        end else begin
            wb2d_b = 0;
        end
    end

endmodule