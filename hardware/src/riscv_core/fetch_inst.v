module fetch_instruction(
    input [31:0] pc,
    input is_j_or_b,
    input inst_sel,
    input [31:0] bios_dout,
    input [31:0] imem_dout,
    output [11:0] bios_addr,
    output [13:0] imem_addr,
    output [31:0] inst
);
    reg [31:0] bios;
    assign bios_addr = bios;

    reg [31:0] imem;
    assign imem_addr = imem;

    // IMEM/BIOS Read
    always @(*) begin
      bios = pc[11:0]; // Set bios_addra
      imem = pc[13:0]; // Set imem_addrb
    end

    // Inst Sel + Jump logic
    assign inst = (is_j_or_b) ? 32'h13 : ((inst_sel) ? bios_dout : imem_dout);
endmodule