`timescale 1ps/1ps

module mac (
    input wire resetn,
    input wire signed [7:0] a, b,
    input wire signed [23:0] c,
    output wire signed [23:0] z
    );

    assign z = (resetn) ? a * b + c : 0;

endmodule