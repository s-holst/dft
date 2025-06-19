`timescale 1ns / 1ps
`include "assert.v"

module mac_wrapped_tb;

    reg resetn;
    reg [7:0] a, b;
    reg [23:0] c;
    wire [23:0] z;

    reg TCK, TMS, TRSTn, TDI;
    wire TDO;

    mac_wrapped dut(
        .resetn(resetn),
        .a     (a),
        .b     (b),
        .c     (c),
        .z     (z),
        .TCK   (TCK),
        .TMS   (TMS),
        .TRSTn (TRSTn),
        .TDI   (TDI),
        .TDO   (TDO)
    );

    always #5 TCK = ~TCK;

    reg [127:0] data_in, data_out;

    integer i;

    initial begin
        $dumpfile("mac_wrapped.vcd");
        $dumpvars;
        $display("starting MAC Wrapper testbench");
        TDI = 0;
        TCK = 0;
        TRSTn = 1;
        TMS = 1;

        // Reset TAP, check device ID
        #50;

        // Shift DR
        @(negedge TCK); TMS = 0;
        @(negedge TCK); TMS = 1;
        @(negedge TCK); TMS = 0;
        @(negedge TCK); TMS = 0;
        data_in = 127'h7F;
        data_out = 127'h0;
        for (i = 0; i < 32; i=i+1) begin
            @(negedge TCK); TDI = data_in[i];
            @(posedge TCK); data_out[i] = TDO;
        end
        `assert("data_out", data_out, 'hF00ED093, "device ID")
        data_in = 0;
        for (i = 0; i < 32; i=i+1) begin
            @(negedge TCK); TDI = data_in[i];
            if (i == 31) TMS = 1;  // go to exit state on last iteration
            @(posedge TCK); data_out[i] = TDO;
        end
        `assert("data_out", data_out, 'h7F, "dummy device ID")

        // test normal function of core
        resetn = 1;
        a = 10;
        b = 7;
        c = 1;
        #10;
        `assert("z", z, a*b+c, "functional op of core")
        #10;

        // Reset TAP
        TMS = 1; #50; @(negedge TCK);

        // load SAMPLE_PRELOAD into IR_outreg
        @(negedge TCK); TMS = 0;
        @(negedge TCK); TMS = 1;
        @(negedge TCK); TMS = 1;
        @(negedge TCK); TMS = 0;
        @(negedge TCK); TMS = 0;
        data_in = dut.tap.SAMPLE_PRELOAD;
        for (i = 0; i < 4; i=i+1) begin
            @(negedge TCK); TDI = data_in[i];
            if (i == 3) TMS = 1;  // go to exit state on last iteration
            @(posedge TCK); data_out[i] = TDO;
        end
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.EXIT1_IR, "EXIT1_IR")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.UPDATE_IR, "UPDATE_IR")
        // Shift DR
        @(negedge TCK); TMS = 0; `assert("state", dut.tap.controller.state, dut.tap.controller.SELECT_DR_SCAN, "SELECT_DR_SCAN")
        `assert("IR_outreg", dut.tap.IR_outreg, dut.tap.SAMPLE_PRELOAD, "SAMPLE_PRELOAD")
        @(negedge TCK); TMS = 0; `assert("state", dut.tap.controller.state, dut.tap.controller.CAPTURE_DR, "CAPTURE_DR")
        data_in[64:0] = {1'b1, 8'd12, 8'd54, 24'd1000, 24'd4321};  // data for INTEST
        for (i = 0; i < (dut.tap.NUM_INPUTS+dut.tap.NUM_OUTPUTS); i=i+1) begin
            @(negedge TCK); TDI = data_in[i];
            if (i == (dut.tap.NUM_INPUTS+dut.tap.NUM_OUTPUTS-1)) TMS = 1;  // go to exit state on last iteration
            @(posedge TCK); data_out[i] = TDO;
        end
        `assert("data_out", data_out, {resetn, a, b, c, z}, "BS scan out")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.EXIT1_DR, "EXIT1_DR")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.UPDATE_DR, "UPDATE_DR")

        // INTEST
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.SELECT_DR_SCAN, "SELECT_DR_SCAN")
        @(negedge TCK); TMS = 0; `assert("state", dut.tap.controller.state, dut.tap.controller.SELECT_IR_SCAN, "SELECT_IR_SCAN")
        @(negedge TCK); TMS = 0; `assert("state", dut.tap.controller.state, dut.tap.controller.CAPTURE_IR, "CAPTURE_IR")
        data_in = dut.tap.INTEST;
        for (i = 0; i < 4; i=i+1) begin
            @(negedge TCK); TDI = data_in[i];
            if (i == 3) TMS = 1;  // go to exit state on last iteration
            @(posedge TCK); data_out[i] = TDO;
        end
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.EXIT1_IR, "EXIT1_IR")
        `assert("z", z, a*b+c, "functional op of core 2")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.UPDATE_IR, "UPDATE_IR")
        `assert("z", z, a*b+c, "functional op of core 3")
        @(negedge TCK); TMS = 0; `assert("state", dut.tap.controller.state, dut.tap.controller.SELECT_DR_SCAN, "SELECT_DR_SCAN")
        `assert("IR_outreg", dut.tap.IR_outreg, dut.tap.INTEST, "INTEST")
        `assert("z", z, 24'd4321, "BS data should be output")
        @(negedge TCK); TMS = 0; `assert("state", dut.tap.controller.state, dut.tap.controller.CAPTURE_DR, "CAPTURE_DR")
        data_in[64:0] = {1'b1, 8'd1, 8'd2, 24'd3, 24'd4};  // other data for EXTEST
        for (i = 0; i < (dut.tap.NUM_INPUTS+dut.tap.NUM_OUTPUTS); i=i+1) begin
            @(negedge TCK); TDI = data_in[i];
            if (i == (dut.tap.NUM_INPUTS+dut.tap.NUM_OUTPUTS-1)) TMS = 1;  // go to exit state on last iteration
            @(posedge TCK); data_out[i] = TDO;
        end
        `assert("data_out", data_out, {resetn, a, b, c, 24'd1648}, "INTEST scan out")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.EXIT1_DR, "EXIT1_DR")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.UPDATE_DR, "UPDATE_DR")

        // EXTEST
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.SELECT_DR_SCAN, "SELECT_DR_SCAN")
        @(negedge TCK); TMS = 0; `assert("state", dut.tap.controller.state, dut.tap.controller.SELECT_IR_SCAN, "SELECT_IR_SCAN")
        @(negedge TCK); TMS = 0; `assert("state", dut.tap.controller.state, dut.tap.controller.CAPTURE_IR, "CAPTURE_IR")
        data_in = dut.tap.EXTEST;
        for (i = 0; i < 4; i=i+1) begin
            @(negedge TCK); TDI = data_in[i];
            if (i == 3) TMS = 1;  // go to exit state on last iteration
            @(posedge TCK); data_out[i] = TDO;
        end
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.EXIT1_IR, "EXIT1_IR")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.UPDATE_IR, "UPDATE_IR")
        @(negedge TCK); TMS = 0; `assert("state", dut.tap.controller.state, dut.tap.controller.SELECT_DR_SCAN, "SELECT_DR_SCAN")
        `assert("IR_outreg", dut.tap.IR_outreg, dut.tap.EXTEST, "EXTEST")
        `assert("z", z, 24'd4, "BS EXTEST data should be output")
        @(negedge TCK); TMS = 0; `assert("state", dut.tap.controller.state, dut.tap.controller.CAPTURE_DR, "CAPTURE_DR")
        data_in[64:0] = {1'b1, 8'd0, 8'd0, 24'd0, 24'd0};
        for (i = 0; i < (dut.tap.NUM_INPUTS+dut.tap.NUM_OUTPUTS); i=i+1) begin
            @(negedge TCK); TDI = data_in[i];
            if (i == (dut.tap.NUM_INPUTS+dut.tap.NUM_OUTPUTS-1)) TMS = 1;  // go to exit state on last iteration
            @(posedge TCK); data_out[i] = TDO;
        end
        `assert("data_out", data_out, {resetn, a, b, c, 24'd71}, "EXTEST scan out should contain applied inputs and core response")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.EXIT1_DR, "EXIT1_DR")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.UPDATE_DR, "UPDATE_DR")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.SELECT_DR_SCAN, "SELECT_DR_SCAN")
        @(negedge TCK); TMS = 1; `assert("state", dut.tap.controller.state, dut.tap.controller.SELECT_IR_SCAN, "SELECT_IR_SCAN")
        @(negedge TCK); `assert("state", dut.tap.controller.state, dut.tap.controller.TEST_LOGIC_RESET, "TEST_LOGIC_RESET")

        $display("PASS ^o^");
        $finish;
    end

endmodule