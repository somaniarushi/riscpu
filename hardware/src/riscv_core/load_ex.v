module load_extender(
    input [31:0] in,
    input [31:0] inst,
    input [31:0] addr,
    output reg [31:0] out
);
    /* 
        1. If inst is not a load operation (I-Type), then do whatever.
        2. If the instruction is a load type instruction (opcode is always 7'h03).
            - If it's a load word -> func3 is 010 -> return the entire input
            - If it's a half word -> func3 is 001 / 101 -> if addr[1] == 0, then first half [31:16], otherwise second half [15:0]
            - If it's a byte -> func3 is 000 / 100 -> if addr[1:0] = 0 [31:25], 1 [24:16] 2 [15:7] 3 [7:0]
        Extension -> Check top byte, extend on basis of it.
    */
    wire [2:0] func3;
    assign func3 = inst[14:12];

    wire [6:0] opc;
    assign opc = inst[6:0];

    always @(*) begin
        if (opc == 7'h03) begin // Load instruction
            if (func3[1:0] == 2'b10) begin // Load word
                out = in;
            end 
            else if (func3[1:0] == 2'b01) begin // Load half-word
                if (addr[1] == 1) begin // Load first half
                    out[15:0] = in[31:16];
                    if (func3[2] == 0) begin // Not unsigned
                        out[31:16] = in[31] ? 20'hfffff : 20'h0;
                    end else begin // Unsigned
                        out[31:16] = 20'h0;
                    end
                end else begin // Load second half
                    out[15:0] = in[15:0];
                    if (func3[2] == 0) begin // Not unsigned
                        out[31:16] = in[15] ? 20'hfffff : 20'h0;
                    end else begin // Unsigned
                        out[31:16] = 20'h0;
                    end
                end
            end
            else if (func3[1:0] == 2'b00) begin
                if (addr[1:0] == 2'b11) begin // Load first half
                    out[7:0] = in[31:24];
                    if (func3[2] == 0) begin // Not unsigned
                        out[31:8] = in[31] ? 'hfffffff : 'h0;
                    end else begin // Unsigned
                        out[31:8] = 'h0;
                    end
                end
                else if (addr[1:0] == 2'b10) begin // Load second half
                    out[7:0] = in[23:16];
                    if (func3[2] == 0) begin // Not unsigned
                        out[31:8] = in[23] ? 'hffffff : 'h0;                        
                    end else begin
                        out[31:8] = 'h0;
                    end
                end
                else if (addr[1:0] == 2'b01) begin // Load third half
                    out[7:0] = in[15:8];
                    if (func3[2] == 0) begin // Not unsigned
                        out[31:8] = in[15] ? 'hffffff : 'h0;
                    end else begin
                        out[31:8] = 'h0;
                    end
                end
                else begin
                    out[7:0] = in[7:0];
                    if (func3[2] == 0) begin // Not unsigned
                        out[31:8] = in[7] ? 'hffffff : 'h0;
                    end else begin
                        out[31:8] = 'h0;
                    end
                end
            end
            else begin
                out = in;
            end
        end else begin
            out = in;
        end
    end
endmodule