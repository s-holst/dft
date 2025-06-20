`timescale 1ns / 1ps
`include "assert.v"

module jtag_tap_controller_tb;

    reg TCK, TMS, TRSTn;
    wire ClockIR, ShiftIR, UpdateIR, ClockDR, ShiftDR, UpdateDR, Select, Enable;

    jtag_tap_controller dut(
        .TCK       (TCK),
        .TMS       (TMS),
        .TRSTn     (TRSTn),
        .Resetn    (Resetn),
        .ClockIR   (ClockIR),
        .ShiftIR   (ShiftIR),
        .UpdateIR  (UpdateIR),
        .ClockDR   (ClockDR),
        .ShiftDR   (ShiftDR),
        .UpdateDR  (UpdateDR),
        .Select    (Select),
        .Enable    (Enable)
    );

    always #5 TCK = ~TCK;

    initial begin
        $dumpfile("jtag_tap_controller_tb.vcd");
        $dumpvars;
        $display("starting JTAG TAP Controller testbench");
        TCK = 0;
        TMS = 1;
        TRSTn = 1;

        // (1.X) test TRSTn
        #10;  // ------- negedge TCK
        `assert("state", dut.state, dut.TEST_LOGIC_RESET, "TEST_LOGIC_RESET 1.1")
        TMS = 0;
        #10;  // ------- negedge TCK
        `assert("state", dut.state, dut.RUN_TEST_IDLE, "RUN_TEST_IDLE 1.2")
        TRSTn = 0;
        //#1;  // removed async reset for synthesizability
        @(negedge TCK)
        @(negedge TCK)
        `assert("state", dut.state, dut.TEST_LOGIC_RESET, "TEST_LOGIC_RESET 1.3")
        TRSTn = 1;
        TMS = 1;
        @(negedge TCK)

        // (2.X) test upper loop
        #10;  // ------- negedge TCK
        `assert("state", dut.state, dut.TEST_LOGIC_RESET, "TEST_LOGIC_RESET 2.1")
        TMS = 0;
        #10;  // ------- negedge TCK
        `assert("state", dut.state, dut.RUN_TEST_IDLE, "RUN_TEST_IDLE 2.2")
        #10;  // ------- negedge TCK
        `assert("state", dut.state, dut.RUN_TEST_IDLE, "RUN_TEST_IDLE 2.3")
        TMS = 1;
        #10;  // ------- negedge TCK
        `assert("state", dut.state, dut.SELECT_DR_SCAN, "SELECT_DR_SCAN 2.4")
        #10;  // ------- negedge TCK
        `assert("state", dut.state, dut.SELECT_IR_SCAN, "SELECT_IR_SCAN 2.5")
        #10;  // ------- negedge TCK
        `assert("state", dut.state, dut.TEST_LOGIC_RESET, "TEST_LOGIC_RESET 2.6")
        #10;  // ------- negedge TCK

        // (3.X) Recreate waveform of Figure 6-7 in in IEEE-Std-1149.1-2001

        #100; // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        TMS = 1;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 1;
        #10;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 1;
        #10;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 1;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 1;
        #10;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 1;
        #10;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 1;
        #10;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 1;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        TMS = 1;
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        #10;  // ------- negedge TCK
        

        $display("PASS ^o^");
        $finish;
    end


endmodule