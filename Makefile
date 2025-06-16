all:
	iverilog -I tests rtl/jtag_tap_controller.v tests/jtag_tap_controller_tb.v && vvp a.out
	iverilog -I tests rtl/jtag_tap_controller.v rtl/jtag_tap.v tests/jtag_tap_tb.v && vvp a.out