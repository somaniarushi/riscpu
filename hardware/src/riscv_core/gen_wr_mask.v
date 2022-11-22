module gen_wr_mask(
    input [31:0] inst,
    input [31:0] addr,
    output reg [3:0] mask
);
    /* 
    1. If the instruction isn't a store type (7'h23), then set the mask to all zeros (write nothing).
    2. If it is a store type
        - If 
    */
    wire [6:0] opc;
    assign opc = inst[6:0];
    
    wire [2:0] func3;
    assign func3 = inst[14:12];

    always @(*) begin
        if (opc == 7'h23) begin
            if (func3 == 3'b010) begin // Store Word
                mask = 4'b1111;
            end 
            else if (func3 == 3'b001) begin // Store Half Word
                if (addr[1] == 1) begin
                    mask = 4'b1100;
                end else begin
                    mask = 4'b0011;
                end
            end
            else if (func3 == 3'b000) begin // Store byte
                case(addr[1:0])
                    'd3: mask = 4'b1000;
                    'd2: mask = 4'b0100;
                    'd1: mask = 4'b0010;
                    'd0: mask = 4'b0001;
                    default: mask = 4'b0000; 
                endcase
            end 
            else begin
                mask = 4'b0000;
            end
        end else begin
            mask = 4'b0000;
        end
    end
endmodule