module fetch_instruction(
    input [31:0] pc,
    input is_j,
    input inst_sel,
    input [31:0] bios_dout,
    input [31:0] imem_dout,
    output reg [11:0] bios_addr,
    output reg [13:0] imem_addr,
    output [31:0] inst
);
    // For every +4 to the PC, there should only be a +1 to IMEM indices.
    // IMEM/BIOS Read
    always @(*) begin
      bios_addr = pc[13:2]; // Set bios_addra
      imem_addr = pc[15:2]; // Set imem_addrb
    end

    // Inst Sel + Jump logic
    assign inst = (is_j) ? 32'h13 : ((inst_sel) ? bios_dout : imem_dout);
endmodule