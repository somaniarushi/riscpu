module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 32,
    parameter POINTER_WIDTH = $clog2(DEPTH)
) (
    input clk, rst,

    // Write side
    input wr_en,
    input [WIDTH-1:0] din,
    output full,

    // Read side
    input rd_en,
    output [WIDTH-1:0] dout,
    output empty
);

    reg [POINTER_WIDTH:0] cnt;
    reg [POINTER_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [WIDTH-1:0] store [DEPTH-1:0];
    reg [WIDTH-1:0] dout_reg;


    wire go_wr;
    wire go_rd;

    assign go_wr = wr_en & !full;
    assign go_rd = rd_en & !empty;
    assign dout = dout_reg;

    always @(posedge clk) begin
        if (rst) begin
            cnt <= 0;
        end
        else begin
            if (go_wr & !go_rd) begin
                cnt <= cnt + 1;
            end
            else if (go_rd & !go_wr) begin
                cnt <= cnt - 1;
            end
            else begin
                cnt <= cnt;
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            dout_reg <= 0;
        end
        else begin
            if (go_rd | go_wr) begin
                if (go_wr) begin
                    store[wr_ptr] <= din;
                    wr_ptr <= (wr_ptr == DEPTH - 1) ? 0: wr_ptr + 1;
                end
                if (go_rd) begin
                    dout_reg <= store[rd_ptr];
                    rd_ptr <= (rd_ptr == DEPTH - 1) ? 0 : rd_ptr + 1;
                end
            end
        end
    end

    assign full = cnt == DEPTH;
    assign empty = cnt == 0;
endmodule
