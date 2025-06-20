// inspired by:
// Weste and Harris: CMOS VLSI Design: A Circuits and Systems Perspective, Addison Wesley, 2011

module jtag_tap_controller (
    input TCK, TMS, TRSTn,
    output reg Resetn,
    output wire ClockIR,
    output reg ShiftIR,
    output wire UpdateIR,
    output wire ClockDR,
    output reg ShiftDR,
    output wire UpdateDR,
    output wire Select,
    output reg Enable
);

    // follow example in IEEE-Std-1149.1-2001 Table 6-3
    localparam EXIT2_DR         = 4'h0;
    localparam EXIT1_DR         = 4'h1;
    localparam SHIFT_DR         = 4'h2;
    localparam PAUSE_DR         = 4'h3;
    localparam SELECT_IR_SCAN   = 4'h4;
    localparam UPDATE_DR        = 4'h5;
    localparam CAPTURE_DR       = 4'h6;
    localparam SELECT_DR_SCAN   = 4'h7;
    localparam EXIT2_IR         = 4'h8;
    localparam EXIT1_IR         = 4'h9;
    localparam SHIFT_IR         = 4'hA;
    localparam PAUSE_IR         = 4'hB;
    localparam RUN_TEST_IDLE    = 4'hC;
    localparam UPDATE_IR        = 4'hD;
    localparam CAPTURE_IR       = 4'hE;
    localparam TEST_LOGIC_RESET = 4'hF;

    reg [3:0] state;

    // next state logic
    // state transition only on rising TCK (or falling TRSTn, omitted for synthesizability)
    always @(posedge TCK)
        if (~TRSTn) state = TEST_LOGIC_RESET;
        else case (state)
            TEST_LOGIC_RESET: state = (TMS) ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE:    state = (TMS) ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            SELECT_DR_SCAN:   state = (TMS) ? SELECT_IR_SCAN   : CAPTURE_DR;
            CAPTURE_DR:       state = (TMS) ? EXIT1_DR         : SHIFT_DR;
            SHIFT_DR:         state = (TMS) ? EXIT1_DR         : SHIFT_DR;
            EXIT1_DR:         state = (TMS) ? UPDATE_DR        : PAUSE_DR;
            PAUSE_DR:         state = (TMS) ? EXIT2_DR         : PAUSE_DR;
            EXIT2_DR:         state = (TMS) ? UPDATE_DR        : SHIFT_DR;
            UPDATE_DR:        state = (TMS) ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            SELECT_IR_SCAN:   state = (TMS) ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR:       state = (TMS) ? EXIT1_IR         : SHIFT_IR;
            SHIFT_IR:         state = (TMS) ? EXIT1_IR         : SHIFT_IR;
            EXIT1_IR:         state = (TMS) ? UPDATE_IR        : PAUSE_IR;
            PAUSE_IR:         state = (TMS) ? EXIT2_IR         : PAUSE_IR;
            EXIT2_IR:         state = (TMS) ? UPDATE_IR        : SHIFT_IR;
            UPDATE_IR:        state = (TMS) ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            default:          state = TEST_LOGIC_RESET;
        endcase

    // Combinational outputs
    assign ClockIR = TCK | ~((state == CAPTURE_IR) | (state == SHIFT_IR));
    assign ClockDR = TCK | ~((state == CAPTURE_DR) | (state == SHIFT_DR));
    assign UpdateIR = ~TCK & ((state == UPDATE_IR) | (state == TEST_LOGIC_RESET));  // UpdateIR at reset to load IDCODE
    assign UpdateDR = ~TCK & (state == UPDATE_DR);
    assign Select = (state & 8) ? 1 : 0;

    // Outputs synchonized on falling edge of TCK
    always @(negedge TCK) begin
        if (~TRSTn) begin
            ShiftIR <= 0;
            ShiftDR <= 0;
            Resetn  <= 0;
            Enable  <= 0;
        end else begin
            ShiftIR <= (state == SHIFT_IR);
            ShiftDR <= (state == SHIFT_DR);
            Resetn <= ~(state == TEST_LOGIC_RESET);
            Enable <= (state == SHIFT_IR) | (state == SHIFT_DR);
        end
    end
endmodule
