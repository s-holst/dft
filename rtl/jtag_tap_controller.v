module jtag_tap_controller (
    input wire tck,
    input wire tms,
    input wire trstn,
    output reg [3:0] state,
    output wire capture_dr,
    output wire shift_dr,
    output wire update_dr,
    output wire capture_ir,
    output wire shift_ir,
    output wire update_ir
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

    reg [3:0] next_state;

    // state transition only on rising TCK or falling TRSTN
    always @(posedge tck or negedge trstn) begin
        if (!trstn)
            state <= TEST_LOGIC_RESET;
        else
            state <= next_state;
    end

    // combinational next_state logic
    always @(*) begin
        case (state)
            TEST_LOGIC_RESET: next_state = (tms) ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE:    next_state = (tms) ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            SELECT_DR_SCAN:   next_state = (tms) ? SELECT_IR_SCAN   : CAPTURE_DR;
            CAPTURE_DR:       next_state = (tms) ? EXIT1_DR         : SHIFT_DR;
            SHIFT_DR:         next_state = (tms) ? EXIT1_DR         : SHIFT_DR;
            EXIT1_DR:         next_state = (tms) ? UPDATE_DR        : PAUSE_DR;
            PAUSE_DR:         next_state = (tms) ? EXIT2_DR         : PAUSE_DR;
            EXIT2_DR:         next_state = (tms) ? UPDATE_DR        : SHIFT_DR;
            UPDATE_DR:        next_state = (tms) ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            SELECT_IR_SCAN:   next_state = (tms) ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR:       next_state = (tms) ? EXIT1_IR         : SHIFT_IR;
            SHIFT_IR:         next_state = (tms) ? EXIT1_IR         : SHIFT_IR;
            EXIT1_IR:         next_state = (tms) ? UPDATE_IR        : PAUSE_IR;
            PAUSE_IR:         next_state = (tms) ? EXIT2_IR         : PAUSE_IR;
            EXIT2_IR:         next_state = (tms) ? UPDATE_IR        : SHIFT_IR;
            UPDATE_IR:        next_state = (tms) ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            default:          next_state = TEST_LOGIC_RESET;
        endcase
    end

    // combinational output logic
    assign capture_dr = (state == CAPTURE_DR);
    assign shift_dr   = (state == SHIFT_DR);
    assign update_dr  = (state == UPDATE_DR);
    assign capture_ir = (state == CAPTURE_IR);
    assign shift_ir   = (state == SHIFT_IR);
    assign update_ir  = (state == UPDATE_IR);

endmodule
