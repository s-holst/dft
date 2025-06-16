`timescale 1ns / 1ps
`include "assert.v"

module jtag_tap_tb;

    reg TCK, TMS, TRSTn, TDI;
    wire TDO;

    jtag_tap dut(
        .TCK       (TCK),
        .TMS       (TMS),
        .TRSTn     (TRSTn),
        .TDI       (TDI),
        .TDO       (TDO)
    );

    always #5 TCK = ~TCK;

    reg [31:0] data_in, data_out;

    integer i;

    initial begin
        $dumpfile("jtag_tap_tb.vcd");
        $dumpvars;
        $display("starting JTAG TAP Controller testbench");
        TDI = 0;
        TCK = 0;
        TRSTn = 1;

        // Reset
        TMS = 1;
        #50;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        `assert("state", dut.controller.state, dut.controller.RUN_TEST_IDLE, "RUN_TEST_IDLE")
        TMS = 1;
        #10;  // ------- negedge TCK
        `assert("state", dut.controller.state, dut.controller.SELECT_DR_SCAN, "SELECT_DR_SCAN")
        TMS = 0;
        #10;  // ------- negedge TCK
        `assert("state", dut.controller.state, dut.controller.CAPTURE_DR, "CAPTURE_DR")
        TMS = 0;
        #10;  // ------- negedge TCK
        `assert("state", dut.controller.state, dut.controller.SHIFT_DR, "SHIFT_DR")
        data_in = 32'h0000007F;
        for (i = 0; i < 32; i=i+1) begin
            TDI = data_in[i];
            #5;  // ------- posedge TCK
            data_out[i] = TDO;
            #5;  // ------- negedge TCK
        end
        `assert("state", data_out, 32'hF00ED093, "device ID")
        data_in = 0;
        for (i = 0; i < 32; i=i+1) begin
            TDI = data_in[i];
            #5;  // ------- posedge TCK
            data_out[i] = TDO;
            #5;  // ------- negedge TCK
        end
        `assert("state", data_out, 32'h0000007F, "device ID")
        TMS = 1;
        #100;  // ------- negedge TCK

        $display("PASS ^o^");
        $finish;
    end

endmodule