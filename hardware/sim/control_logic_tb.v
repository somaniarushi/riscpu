`timescale 1ns/1ns

module control_logic_tb();
    reg clk;
    parameter CPU_CLOCK_PERIOD = 10;
    parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

    parameter DEPTH = 32;
    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

    reg [31:0] inst_fd, inst_x, inst_mw;
    reg [1:0] pc_sel;
    reg is_j_or_b, wb2d_a, wb2d_b;

    control_logic cl (
      .inst_fd(inst_fd),
      .inst_x(inst_x),
      .inst_mw(inst_mw),
      .pc_sel(pc_sel),
      .is_j_or_b(is_j_or_b),
      .wb2d_a(wb2d_a),
      .wb2d_b(wb2d_b)
    );

    initial begin
        /* test pc-sel setting */

    end
endmodule