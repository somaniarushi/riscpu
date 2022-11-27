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


    // reg serial_out_reg;
    // assign serial_out = serial_out_reg;

    // always @(posedge clk) begin
    //     if (reset) begin
    //         clock_counter <= 0;
    //         bit_counter <= 0;
    //         data_out_sender <= data_in;
    //         serial_out_reg <= 1;
    //         data_in_ready_reg <= 1;
    //     end
    //     else begin
    //         clock_counter <= clock_counter + 1;
    //         if (data_in_ready && data_in_valid) begin
    //             clock_counter <= 0;
    //             data_in_ready_reg <= 0;
    //             bit_counter <= 0;
    //             serial_out_reg <= 1;
    //             data_out_sender <= {1'b1, data_in, 1'b0};
    //         end
    //         else if (bit_counter <= 9) begin
    //             serial_out_reg <= data_out_sender[0];
    //             clock_counter <= clock_counter + 1;
    //             if (clock_counter == (SYMBOL_EDGE_TIME - 1)) begin
    //                 bit_counter <= bit_counter + 1;
    //                 data_out_sender <= data_out_sender >> 1;
    //                 clock_counter <= 0;
    //             end
    //         end
    //         else begin
    //             bit_counter <= 0;
    //             data_in_ready_reg <= 1;
    //             serial_out_reg <= 1;
    //         end
    //     end
    // end
    // reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter;

    // reg [3:0] idx_yield;
    // reg [7:0] data_reg;

    // reg ready_reg;
    // assign data_in_ready = ready_reg;

    // reg out_reg;
    // assign serial_out = out_reg;

    // always @(posedge clk) begin
    //     if (reset) begin
    //         clock_counter = 0;
    //         out_reg = 1;
    //         data_reg = data_in;
    //         ready_reg = 1;
    //         idx_yield = INIT_YIELD_NUM;
    //     end
    //     // Time to send data MOFOs
    //     else if (data_in_valid && ready_reg) begin
    //         ready_reg = 0;
    //     end
    //     else if (ready_reg == 0 && idx_yield == INIT_YIELD_NUM) begin
    //         out_reg = 0;
    //         data_reg = data_in;
    //         $display("sending value %b", 3'b0);
    //         idx_yield = 0;
    //         clock_counter = 0;
    //     end
    //     // Yielding vals time
    //     else if (idx_yield < (INIT_YIELD_NUM - 1)) begin
    //         if (clock_counter == SYMBOL_EDGE_TIME) begin
    //             $display("sending value %b %b", data_reg[0], data_reg);
    //             out_reg = data_reg[0];
    //             data_reg = data_reg >> 1;
    //             clock_counter = 0;
    //             idx_yield = idx_yield + 1;
    //         end
    //         else begin
    //             clock_counter = clock_counter + 1;
    //         end
    //     end
    //     else if (idx_yield == (INIT_YIELD_NUM - 1)) begin
    //         if (clock_counter == SYMBOL_EDGE_TIME) begin
    //             out_reg = 1;
    //             $display("sending value %b", 3'b1);
    //             ready_reg = 1;
    //             idx_yield = INIT_YIELD_NUM;
    //         end
    //         else begin
    //             clock_counter = clock_counter + 1;
    //         end

    //     end
    //     else begin
    //         ready_reg = 1;
    //     end
    // end

/*
ALGORITHM

if RESET
    CLOCK_COUNTER = 0
    SERIAL_REG = 1
    DATA_IN_READY = 1
    NUM_VALS_TO_YIELD = -1

if NUM_VALS_TO_YIELD > 0
    SERIAL = DATA_IN[YIELD_POINT]
    DATA_IN_READY = 0
    DECREMENT NUM_VALS_TO_YIELD

if NUM_VALS_TO_YIELD == 0
    SERIAL = 1
    DATA_IN_READY = 1
    DECREMENT NUM_VALS_TO_YIELD

if NUM_VALS_TO_YIELD == -1:
    IF DATA_IN_READY && DATA_IN_VALID:
        SERIAL = 0
        DATA_IN_READY = 0
        NUM_VALS_TO_YIELD = 7

*/

    // reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter;
    // assign symbol_edge = clock_counter == (SYMBOL_EDGE_TIME - 1);

    // reg [3:0] bit_counter; // defines current bit being transferred

    // reg serial_out_reg;
    // assign serial_out = serial_out_reg;

    // reg [7:0] data_out_sender;

    // reg data_in_ready_reg;
    // assign data_in_ready = data_in_ready_reg;

    // assign tx_running = bit_counter != 4'd15;
    // assign start = !tx_running && data_in_valid;

    // always @ (posedge clk) begin
    //     clock_counter <= (start || reset || symbol_edge) ? 0 : clock_counter + 1;
    // end

    // // Counts down from 10 bits for every character
    // always @ (posedge clk) begin
    //     if (reset) begin
    //         bit_counter <= 4'd15;
    //     end else if (start && data_in_ready) begin
    //         bit_counter <= 7;
    //     end else if (symbol_edge && tx_running) begin
    //         bit_counter <= bit_counter - 1;
    //     end
    // end

    // always @(posedge clk) begin
    //     if (reset) begin
    //         data_out_sender = data_in;
    //         serial_out_reg = 1'b1;
    //     end
    //     else begin
    //         if (tx_running) begin
    //             if (symbol_edge) begin
    //                 serial_out_reg = data_out_sender[0];
    //                 data_out_sender = data_out_sender >> 1;
    //             end
    //         end
    //         else if (start && data_in_ready) begin
    //             serial_out_reg = 1'b0;
    //             data_out_sender = data_in;
    //         end
    //         else begin
    //             serial_out_reg = 1'b1;
    //             data_out_sender = 0;
    //         end
    //     end
    // end

    // always @(posedge clk) begin
    //     if (reset) data_in_ready_reg <= 1;
    //     else if (tx_running || start) begin
    //         data_in_ready_reg <= 0;
    //     end
    //     else begin
    //         data_in_ready_reg <= 1;
    //     end
    // end


// endmodule