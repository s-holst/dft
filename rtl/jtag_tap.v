module jtag_tap #(
    parameter NUM_INPUTS = 1,
    parameter NUM_OUTPUTS = 1,

    // Device ID has 32 bits and consists of {version, part, manufacturerID, 1}
    // 11-bit manufacturerID: EIA/JEP106, [10:7] #continuation characters mod16, [6:0] last byte without parity bit
    // older list: https://www.mikrocontroller.net/attachment/39268/jep106k.pdf
    // latest list: https://github.com/openocd-org/openocd/blob/master/src/helper/jep106.inc
    // manufacturerID 00001111111 is illegal. Shift this in to determine end of ID stream.
    // Constant 1 used to determine the presence of an ID. Bypass register contains 0 after reset.
    parameter DEVICE_ID = {4'hF, 16'hED, 11'b00001001001, 1'b1}  // Xilinx
) (
    input TCK, TMS, TRSTn, TDI,
    output TDO,
    input [NUM_INPUTS-1:0] inputs,
    output [NUM_INPUTS-1:0] to_core,
    output [NUM_OUTPUTS-1:0] outputs,
    input [NUM_OUTPUTS-1:0] from_core
);

    // Instructions (all 1's reserved for BYPASS, 8.1.1.e: avoid all 0's for disrupting ops)
    localparam SAMPLE_PRELOAD   = 4'b0101;
    localparam IDCODE           = 4'b1001;
    localparam INTEST           = 4'b0100;
    localparam EXTEST           = 4'b0110;

    reg [3:0] IR_shiftreg, IR_outreg;
    reg [NUM_INPUTS+NUM_OUTPUTS-1:0] BS_shiftreg, BS_outreg;
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

    always @(posedge ClockIR) IR_shiftreg <= ShiftIR ? {TDI, IR_shiftreg[3:1]} : 1;  // 7.1.1.d: load '01' into LSB in CAPTURE_IR
    always @(posedge UpdateIR) IR_outreg <= Resetn ? IR_shiftreg : IDCODE; // set to ~0 (BYPASS), if no IDCODE

    always @(posedge ClockDR) BS_shiftreg <= ShiftDR ? {TDI, BS_shiftreg[NUM_INPUTS+NUM_OUTPUTS-1:1]} : {inputs, from_core};
    always @(posedge UpdateDR) BS_outreg <= BS_shiftreg;
    assign to_core = (IR_outreg == INTEST) ? BS_outreg[NUM_INPUTS+NUM_OUTPUTS-1:NUM_OUTPUTS] : inputs;
    assign outputs = ((IR_outreg == INTEST) || (IR_outreg == EXTEST)) ? BS_outreg[NUM_OUTPUTS-1:0] : from_core;

    always @(posedge ClockDR) ID_shiftreg <= ShiftDR ? {TDI, ID_shiftreg[31:1]} : DEVICE_ID;
    always @(posedge ClockDR) bypassreg <= ShiftDR ? TDI : 0;  // shall load 0 in CAPTURE_DR state

    always @(negedge TCK) begin
        // Weste and Harris use "ShiftDR" instead of "Select" here, which results in a race condition.
        // We use "Select" from the example implementation in IEEE-Std-1149.1-2001.
        if (Select)
            tdo_pre <= IR_shiftreg[0];
        else
            case (IR_outreg)
                SAMPLE_PRELOAD: tdo_pre <= BS_shiftreg[0];
                INTEST: tdo_pre <= BS_shiftreg[0];
                EXTEST: tdo_pre <= BS_shiftreg[0];
                IDCODE: tdo_pre <= ID_shiftreg[0];
                default: tdo_pre <= bypassreg;  // 8.1.1.d: unknown instructions are equivalent to bypass
            endcase
    end
    assign TDO = Enable ? tdo_pre : 1'bz;  // Tristate buffer

endmodule
