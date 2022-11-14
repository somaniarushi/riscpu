module reg_file (
    input clk,
    input we,
    input [4:0] ra1, ra2, wa,
    input [31:0] wd,
    output [31:0] rd1, rd2
);
    /*
    Mapping to schema:
    we = RegWEn, the control signal which determines whether DataD would be written at this clock tick.
    ra1, ra2 = AddrA, AddrB
    rd1, rd2 = rs1, rs2
    wa = AddrD, the address of the write back = rd
    wd = WB or DataD, the value being written back to
    */
    parameter DEPTH = 32;
    reg [31:0] mem [0:31];
    initial begin
        for(integer i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 0;
        end
    end

    reg [31:0] rd1_reg = 0;
    reg [31:0] rd2_reg = 0;

    always @(posedge clk) begin
        // Write value if write enable.
        if(we && wa != 0) begin
            mem[wa] <= wd;
        end
    end

    /*
    Brief: Why regfile reads are asynchronous
    In this structure, we've paired together F and D.
    As such, if both IMEM and RegFile were synchronous,
    there would be no way the stage could take 1 clock cycle.
    Thus, we need regfile reads to be async.
    */
    assign rd1 = mem[ra1];
    assign rd2 = mem[ra2];
endmodule