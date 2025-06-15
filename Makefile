all:
	iverilog -I tests rtl/jtag_tap_controller.v tests/jtag_tap_controller_tb.v && vvp a.out