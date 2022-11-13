module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input reset,

    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    output serial_out
);
    // See diagram in the lab guide
    localparam  SYMBOL_EDGE_TIME    =   CLOCK_FREQ / BAUD_RATE;
    localparam  CLOCK_COUNTER_WIDTH =   $clog2(SYMBOL_EDGE_TIME);
    localparam INIT_YIELD_NUM = 9;


    reg [9:0] data_out_sender;
    reg [3:0] bit_counter;
    reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter;

    wire tx_running;
    assign tx_running = bit_counter != 4'd0;

    wire start;
    assign start = !tx_running && data_in_valid;

    assign data_in_ready = !tx_running;

    reg serial_out_reg;
    assign serial_out = serial_out_reg;

    wire symbol_edge;
    assign symbol_edge = clock_counter == (SYMBOL_EDGE_TIME - 1);

    always @ (posedge clk) begin
        clock_counter <= (start || reset || symbol_edge) ? 0 : clock_counter + 1;
    end

    always @ (posedge clk) begin
        if (reset) begin
            bit_counter <= 0;
        end else if (start) begin
            bit_counter <= 10;
        end else if (symbol_edge && tx_running) begin
            bit_counter <= bit_counter - 1;
        end
    end

    always @ (posedge clk) begin
        if (reset) begin
            data_out_sender <= 0;
        end else if (start) begin
            data_out_sender <= {1'b1, data_in, 1'b0};
        end else if (symbol_edge && tx_running) begin
            data_out_sender <= data_out_sender >> 1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            serial_out_reg <= 1;
        end else if (tx_running) begin
            serial_out_reg <= data_out_sender[0];
        end else begin
            serial_out_reg <= 1;
        end
    end

endmodule