`timescale 1ns/1ns

module fetch_inst_tb();
    reg clk;
    parameter CPU_CLOCK_PERIOD = 10;
    parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

    parameter DEPTH = 32;
    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

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

    reg [31:0] pc;
    reg [31:0] inst;

    reg is_j_or_b;
    reg inst_sel;

    fetch_instruction dut (
        .pc(pc),
        .bios_addr(bios_addra),
        .imem_addr(imem_addrb),
        .bios_dout(bios_douta),
        .imem_dout(imem_doutb),
        .is_j_or_b(is_j_or_b),
        .inst_sel(inst_sel),
        .inst(inst)
    );

    initial begin
        // Test IMEM
        // IMEM Setup: Write value to IMEM address
        imem_wea = 4'b1111;
        imem_addra = 32'h100;
        imem_dina = 32'h25;
        repeat (1) @(negedge clk);

        // TODO: Check waveform in lab
        pc = 32'h100;
        imem_ena = 1;
        bios_ena = 1;
        is_j_or_b = 0;
        inst_sel = 0;
        repeat (2) @(negedge clk);
        assert(inst == 32'h25) else $display("instruction was not read: %h", inst);

        // Overwrite with isJorB
        is_j_or_b = 1;
        repeat (1) @(negedge clk);
        assert(inst == 32'h13) else $display("stall insertion failed %h", inst);

        $finish();

    end
endmodule