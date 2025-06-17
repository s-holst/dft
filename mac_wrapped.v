module mac_wrapped (resetn, a, b, c, z, TCK, TMS, TRSTn, TDI, TDO);
    input resetn;
    input wire [7:0] a;
    input wire [7:0] b;
    input [23:0] c;
    output wire [23:0] z;

    input wire TCK, TMS, TRSTn, TDI;
    output wire TDO;

    wire [40:0] inputs = {resetn, a, b, c};
    wire [23:0] outputs;
    wire [40:0] to_core;
    wire [23:0] from_core;

    assign z = outputs[23:0];

    mac core(
        to_core[40],
        to_core[39:32],
        to_core[31:24],
        to_core[23:0],
        from_core[23:0]
    );

    jtag_tap #(
        .NUM_INPUTS  (41),
        .NUM_OUTPUTS (24)
    ) tap (
        .TCK       (TCK),
        .TMS       (TMS),
        .TRSTn     (TRSTn),
        .TDI       (TDI),
        .TDO       (TDO),
        .inputs    (inputs),
        .to_core   (to_core),
        .outputs   (outputs),
        .from_core (from_core)
    );

endmodule