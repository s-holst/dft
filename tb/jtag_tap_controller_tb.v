`timescale 1ns / 1ps
`include "assert.v"

module jtag_tap_controller_tb;

    reg tck, tms, trstn;
    wire [3:0] state;
    wire capture_dr, shift_dr, update_dr, capture_ir, shift_ir, update_ir;

    jtag_tap_controller dut(
        .tck       (tck),
        .tms       (tms),
        .trstn     (trstn),
        .state     (state),
        .capture_dr(capture_dr),
        .shift_dr  (shift_dr),
        .update_dr (update_dr),
        .capture_ir(capture_ir),
        .shift_ir  (shift_ir),
        .update_ir (update_ir)
    );

    always #5 tck = ~tck;

    initial begin
        $dumpfile("jtag_tap_controller_tb.vcd");
        $dumpvars;
        $display("starting JTAG TAP Controller testbench");
        tck = 0;
        tms = 1;
        trstn = 1;

        // (1.X) test TRSTN
        #10;  // ------- negedge tck
        `assert("state", state, dut.TEST_LOGIC_RESET, "TEST_LOGIC_RESET 1.1")
        tms = 0;
        #10;  // ------- negedge tck
        `assert("state", state, dut.RUN_TEST_IDLE, "RUN_TEST_IDLE 1.2")
        trstn = 0;
        #1;
        `assert("state", state, dut.TEST_LOGIC_RESET, "TEST_LOGIC_RESET 1.3")
        trstn = 1;
        tms = 1;
        #9;   // ------- negedge tck

        // (2.X) test upper loop
        #10;  // ------- negedge tck
        `assert("state", state, dut.TEST_LOGIC_RESET, "TEST_LOGIC_RESET 2.1")
        tms = 0;
        #10;  // ------- negedge tck
        `assert("state", state, dut.RUN_TEST_IDLE, "RUN_TEST_IDLE 2.2")
        #10;  // ------- negedge tck
        `assert("state", state, dut.RUN_TEST_IDLE, "RUN_TEST_IDLE 2.3")
        tms = 1;
        #10;  // ------- negedge tck
        `assert("state", state, dut.SELECT_DR_SCAN, "SELECT_DR_SCAN 2.4")
        #10;  // ------- negedge tck
        `assert("state", state, dut.SELECT_IR_SCAN, "SELECT_IR_SCAN 2.5")
        #10;  // ------- negedge tck
        `assert("state", state, dut.TEST_LOGIC_RESET, "TEST_LOGIC_RESET 2.6")
        #10;  // ------- negedge tck

        // TODO more tests

        $display("PASS ^o^");
        $finish;
    end


endmodule