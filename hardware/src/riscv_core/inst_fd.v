module inst_fd(
    input clk,
    input rst,
    input [31:0] pc_in,
    output reg [31:0] pc_fd,
    output reg [31:0] pc_x,
    output reg [31:0] imm_x,
    output reg [31:0] imm_fd,
    output reg [31:0] inst_fd,
    output reg [31:0] inst_x,
    output reg [31:0] rs1_fd,
    output reg [31:0] rs1,
    output reg [31:0] rs2_fd,
    output reg [31:0] rs2
);
    reg [31:0] pc_mw;
    reg [31:0] inst_mw;
    reg [31:0] imm_mw;
    reg [31:0] wb_val;
    reg brlt, breq;


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
    reg [3:0] alu_sel;

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

    reg [31:0] next_inst;

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
      .inst(next_inst)
    );

    immediate_generator (
      // Inputs
      .inst(inst_fd),
      // Outputs
      .imm(imm_fd)
    );


    reg [31:0] rs1_fd, rs2_fd;

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
      .rs1(rs1_fd),
      .rs2(rs2_fd)
    );

    // TODO: Writeback TODO

    // FIXME: Jal forwarding???


    reg [31:0] rs1, rs2;
    // Clocking block
    always @(posedge clk) begin
      if (rst) begin
        // TODO: Make sure these are correct;
        pc_fd <= 0;
        inst_fd <= 0;
        pc_x <= 0;
        imm_x <= 0;
        inst_x <= 0;
        rs1 <= 0;
        rs2 <= 0;
      end else begin
        pc_fd <= (is_j_or_b) ? pc_fd : next_pc; // Is is j or b -> insert nop
        pc_x <= pc_fd;
        imm_x <= imm_fd;
        inst_fd <= next_inst;
        inst_x <= inst_fd;
        rs1 <= rs1_fd;
        rs2 <= rs2_fd;
      end
    end

endmodule