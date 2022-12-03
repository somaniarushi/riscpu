/*
A cache module for storing branch prediction data.

Inputs: 2 asynchronous read ports and 1 synchronous write port.
Outputs: data and cache hit (for each read port)
*/

module bp_cache #(
    parameter AWIDTH=32,  // Address bit width
    parameter DWIDTH=32,  // Data bit width
    parameter LINES=128   // Number of cache lines
) (
    input clk,
    input reset,

    // IO for 1st read port
    input [AWIDTH-1:0] ra0,
    output [DWIDTH-1:0] dout0,
    output hit0,

    // IO for 2nd read port
    input [AWIDTH-1:0] ra1,
    output [DWIDTH-1:0] dout1,
    output hit1,

    // IO for write port
    input [AWIDTH-1:0] wa,
    input [DWIDTH-1:0] din,
    input we

);
    // Size of data = tag bits + data + valid bit
    localparam LINES_BIT_SIZE = $clog2(LINES);
    localparam TAG_SIZE = AWIDTH - LINES_BIT_SIZE;
    localparam CACHE_SIZE = TAG_SIZE + 1 + DWIDTH;

    reg [CACHE_SIZE-1:0] cache [LINES-1:0];

    // Read port 1
    wire [LINES_BIT_SIZE-1:0] ra0_offset = ra0[LINES_BIT_SIZE-1:0];
    wire [CACHE_SIZE-1:0] cache_entry0 = cache[ra0_offset];
    wire cache_valid0 = (cache_entry0[DWIDTH] == 1'b1);

    wire [AWIDTH-LINES_BIT_SIZE-1:0] ra0_tag = ra0[AWIDTH-1:LINES_BIT_SIZE];
    wire [AWIDTH-LINES_BIT_SIZE-1:0] cache_tag0 = cache_entry0[CACHE_SIZE-1:DWIDTH+1];
    wire cache_tag_match0 = (ra0_tag == cache_tag0);

    assign hit0 = cache_valid0 && cache_tag_match0;
    assign dout0 = cache_entry0[DWIDTH-1:0];

    // Read port 2
    wire [LINES_BIT_SIZE-1:0] ra1_offset = ra1[LINES_BIT_SIZE-1:0];
    wire [CACHE_SIZE-1:0] cache_entry1 = cache[ra1_offset];
    wire cache_valid1 = (cache_entry1[DWIDTH] == 1'b1);

    wire [AWIDTH-LINES_BIT_SIZE-1:0] ra1_tag = ra1[AWIDTH-1:LINES_BIT_SIZE];
    wire [AWIDTH-LINES_BIT_SIZE-1:0] cache_tag1 = cache_entry1[CACHE_SIZE-1:DWIDTH+1];
    wire cache_tag_match1 = (ra1_tag == cache_tag1);

    assign hit1 = cache_valid1 && cache_tag_match1;
    assign dout1 = cache_entry1[DWIDTH-1:0];

    // Write port
    wire [LINES_BIT_SIZE-1:0] wa_offset = wa[LINES_BIT_SIZE-1:0];
    wire [AWIDTH-LINES_BIT_SIZE-1:0] wa_tag = wa[AWIDTH-1:LINES_BIT_SIZE];
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < LINES; i = i + 1) begin
                cache[i] <= 0;
            end
        end
        else begin
            if (we) begin
                cache[wa_offset][DWIDTH-1:0] <= din;
                cache[wa_offset][DWIDTH] <= 1;
                cache[wa_offset][CACHE_SIZE-1:DWIDTH+1] <= wa_tag;
            end
        end
    end

endmodule
