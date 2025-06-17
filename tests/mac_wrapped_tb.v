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
        .a(a),
        .b(b),
        .c(c),
        .z(z),
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
        $dumpfile("mac_wrapped.vcd");
        $dumpvars;
        $display("starting MAC Wrapper testbench");
        TDI = 0;
        TCK = 0;
        TRSTn = 1;

        // Reset TAP, check device ID
        TMS = 1;
        #50;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        TMS = 1;
        #10;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        TMS = 0;
        #10;  // ------- negedge TCK
        data_in = 32'h0000007F;
        for (i = 0; i < 32; i=i+1) begin
            TDI = data_in[i];
            #5;  // ------- posedge TCK
            data_out[i] = TDO;
            #5;  // ------- negedge TCK
        end
        `assert("data_out", data_out, 32'hF00ED093, "device ID")
        data_in = 0;
        for (i = 0; i < 32; i=i+1) begin
            TDI = data_in[i];
            #5;  // ------- posedge TCK
            data_out[i] = TDO;
            #5;  // ------- negedge TCK
        end
        `assert("data_out", data_out, 32'h0000007F, "dummy device ID")
        TMS = 1;
        #100;  // ------- negedge TCK

        // test normal function of core
        resetn = 1;
        a = 10;
        b = 7;
        c = 1;
        #10;
        `assert("z", z, a*b+c, "functional op of core")
        #10;

        // TODO: observe through boundary scan

        $display("PASS ^o^");
        $finish;
    end

endmodule