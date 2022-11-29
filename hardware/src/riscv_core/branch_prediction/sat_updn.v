/*
A saturating incrementer/decrementer.
Adds +/-1 to the input with saturation to prevent overflow.
*/

module sat_updn #(
    parameter WIDTH=2
) (
    input [WIDTH-1:0] in,
    input up,
    input dn,

    output [WIDTH-1:0] out
);

    reg [WIDTH-1:0] out_reg;
    assign out = out_reg;
    always @(*) begin
        // Branch taken, zero strikes.
        if (in == 'b10) begin
            if (dn)           // Guessed taken, was not taken.
                out_reg = 'b11;     // Add strike.
            else if (up)        // Guessed taken, was taken.
                out_reg = 'b10;     // Stay in same state.
            else                // Should be unreachable.
                out_reg = 'b10;
        end

        // Branch taken, one strike.
        else if (in == 'b11) begin
            if (dn)           // Guessed taken, was not taken.
                out_reg = 'b01;     // Toggle to guessing not taken.
            else if (up)        // Guessed taken, was taken.
                out_reg = 'b10;     // Remove strike.
            else                // Should be unreachable.
                out_reg = 'b11;
        end

        // Branch not taken, zero strikes.
        else if (in == 'b01) begin
            if (dn)           // Guessed not taken, was not taken.
                out_reg = 'b01;     // Stay in state.
            else if (up)        // Guessed not taken, was taken.
                out_reg = 'b00;     // Add strike.
            else                // Should be unreachable.
                out_reg = 'b00;
        end

        // Branch not taken, one strike.
        else if (in == 'b00) begin
            if (dn)           // Guessed not taken, was not taken.
                out_reg = 'b01;     // Remove strike.
            else if (up)        // Guessed not taken, was taken.
                out_reg = 'b10;     // Toggle to guessing taken.
            else                // Should be unreachable.
                out_reg = 'b00;
        end

        // Unreachable
        else begin
            out_reg = 'b10;
        end
    end

endmodule
