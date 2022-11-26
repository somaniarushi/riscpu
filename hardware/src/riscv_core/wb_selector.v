module wb_selector(
    input [31:0] mem_bios_dout,
    input [31:0] dmem_lex,
    input [31:0] uart_out,
    input [31:0] pc,
    input [31:0] alu,
    input [1:0] wb_sel,
    input [3:0] mem_out_sel,
    output reg [31:0] wb_val
);
    // TODO: If bios_dmem is equal to 1000, forward the value of the UART block.
    always @(*) begin
        if (wb_sel == 2) begin
            wb_val = pc + 4;
        end else if (wb_sel == 1) begin
            // If the top four bits of the address are 0100, we are reading from BIOS. Otherwise, DMEM.
            if (mem_out_sel == 4'b0100) begin
                wb_val = mem_bios_dout;
            end else if (mem_out_sel == 4'b1000) begin
                wb_val = uart_out;
            end
            else begin
                wb_val = dmem_lex;
            end
        end else begin
            wb_val = alu;
        end
    end
endmodule