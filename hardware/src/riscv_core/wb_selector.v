module wb_selector(
    input [31:0] out_lex,
    input [31:0] pc,
    input [31:0] alu,
    input [1:0] wb_sel,
    input [1:0] mem_sel,
    output reg [31:0] wb_val
);
    // TODO: If bios_dmem is equal to 1000, forward the value of the UART block.
    always @(*) begin
        if (wb_sel == 2) begin
            wb_val = pc + 4;
        end else if (wb_sel == 1) begin
            wb_val = out_lex;
        end else begin
            wb_val = alu;
        end
    end
endmodule