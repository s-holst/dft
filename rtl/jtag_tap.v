module jtag_tap (
    input TCK, TMS, TRSTn, TDI,
    output TDO
);

    // Instructions
    localparam BYPASS           = 4'b1111;  // Shall be all 1's
    localparam SAMPLE_PRELOAD   = 4'b0101;
    localparam EXTEST           = 4'b0110;
    localparam NOP              = 4'b0001;  // Shall end in ...01.
    localparam IDCODE           = 4'b1001;
    localparam INTEST           = 4'b0100;

    // Device ID has 32 bits and consists of {version, part, manufacturerID, 1}
    // 11-bit manufacturerID: EIA/JEP106, [10:7] #continuation characters mod16, [6:0] last byte without parity bit
    // older list: https://www.mikrocontroller.net/attachment/39268/jep106k.pdf
    // latest list: https://github.com/openocd-org/openocd/blob/master/src/helper/jep106.inc
    // manufacturerID 00001111111 is illegal. Shift this in to determine end of ID stream.
    // Constant 1 used to determine the presence of an ID. Bypass register contains 0 after reset.
    localparam DEVICE_ID = {4'hF, 16'hED, 11'b00001001001, 1'b1};  // Xilinx

    reg [3:0] IR_shiftreg, IR_outreg;
    reg [53:0] BS_shiftreg, BS_outreg;
    reg [31:0] ID_shiftreg;
    reg bypassreg, tdo_pre;

    wire ClockIR, ShiftIR, UpdateIR, ClockDR, ShiftDR, UpdateDR, Select, Enable;

    jtag_tap_controller controller(
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

    always @(posedge ClockIR) IR_shiftreg <= ShiftIR ? {TDI, IR_shiftreg[3:1]} : NOP;
    always @(posedge UpdateIR, negedge Resetn) IR_outreg <= Resetn ? IR_shiftreg : IDCODE; // BYPASS, if no IDCODE

    always @(posedge ClockDR) BS_shiftreg <= ShiftDR ? {TDI, BS_shiftreg[53:1]} : 0; // {all_inputs, core_outputs};
    always @(posedge UpdateDR) BS_outreg <= BS_shiftreg;
    // assign core_inputs = (IR_outreg == INTEST) ? BS_outreg[53:24] : all_inputs;
    // assign all_outputs = ((IR_outreg == INTEST) || (IR_outreg == EXTEST)) ? BS_outreg[23:0] : core_outputs;

    always @(posedge ClockDR) ID_shiftreg <= ShiftDR ? {TDI, ID_shiftreg[31:1]} : DEVICE_ID;
    always @(posedge ClockDR) bypassreg <= ShiftDR ? TDI : 0;  // shall load 0 in CAPTURE_DR state

    always @(negedge TCK) begin
        // Weste and Harris use "ShiftDR" instead of "Select" here, which results in a race condition.
        // We use "Select" from the example implementation in IEEE-Std-1149.1-2001.
        if (Select)
            tdo_pre <= IR_shiftreg[0];
        else
            case (IR_outreg)
                BYPASS: tdo_pre <= bypassreg;
                IDCODE: tdo_pre <= ID_shiftreg[0];
                default: tdo_pre <= BS_shiftreg[0];
            endcase
    end
    assign TDO = Enable ? tdo_pre : 1'bz;  // Tristate buffer

endmodule
