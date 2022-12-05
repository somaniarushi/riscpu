module wb_selector(
    input [31:0] mem_bios_dout,
    input [31:0] dmem_lex,
    input [31:0] uart_out,
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
            // If the top four bits of the address are 0100, we are reading from BIOS. Otherwise, DMEM.
            case (mem_sel)
                2'b10: wb_val = mem_bios_dout;
                2'b01: wb_val = uart_out;
                default: wb_val = dmem_lex;
            endcase
        end else begin
            wb_val = alu;
        end
    end
endmodule