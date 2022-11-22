module wb_selector(
    input [31:0] mem_bios_dout,
    input [31:0] dmem_lex,
    input [31:0] pc,
    input [31:0] alu,
    input [1:0] wb_sel,
    input bios_dmem,
    output reg [31:0] wb_val
);
    always @(*) begin
        if (wb_sel == 2) begin
            wb_val = pc + 4;
        end else if (wb_sel == 1) begin
            wb_val = dmem_lex;
        end else begin
            wb_val = alu;
        end
    end
endmodule