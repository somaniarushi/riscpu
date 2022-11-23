module debouncer #(
    parameter WIDTH              = 1,
    parameter SAMPLE_CNT_MAX     = 62500,
    parameter PULSE_CNT_MAX      = 200,
    parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX),
    parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
    input clk,
    input [WIDTH-1:0] glitchy_signal,
    output [WIDTH-1:0] debounced_signal
);
    // Declarations of variables used
    reg [WIDTH-1:0] debounced = 0;
    wire on;
    reg [WRAPPING_CNT_WIDTH-1:0] wrapping_counter = 0;
    reg [SAT_CNT_WIDTH-1:0] saturating_counter [WIDTH-1:0];
    reg counter_edge;
    integer i, j;

    assign debounced_signal = debounced;
    assign counter_edge = (wrapping_counter == (SAMPLE_CNT_MAX - 1));


    // All counters should start at 0
    initial begin
        for(j = 0; j < WIDTH; j = j + 1) saturating_counter[j] = 0;
    end

    always @(posedge clk) begin
        wrapping_counter <= (counter_edge) ? 0: wrapping_counter + 1;
    end

    // Clock conditions
    always @(posedge clk) begin
        for(i = 0; i < WIDTH; i=i+1) begin
            if (counter_edge) begin
                if (glitchy_signal[i]) begin
                    if (saturating_counter[i] < PULSE_CNT_MAX) begin
                        saturating_counter[i] <= saturating_counter[i] + 1;
                    end
                end
                else begin
                    saturating_counter[i] <= 0;
                end
            end

        end
    end

    always @(posedge clk) begin
         for(i = 0; i < WIDTH; i = i + 1) begin
            debounced[i] <= (saturating_counter[i] == PULSE_CNT_MAX);
         end
    end
endmodule