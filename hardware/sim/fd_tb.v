`timescale 1ns/1ns

module fd_tb();
    reg clk;
    parameter CPU_CLOCK_PERIOD = 10;
    parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

    parameter DEPTH = 32;
    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

    reg rst;

    inst_fd (
        .clk(clk),
        .rst(rst)
    );

    initial begin

    end


endmodule