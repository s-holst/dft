all:
	iverilog -I tests rtl/jtag_tap_controller.v tests/jtag_tap_controller_tb.v && vvp a.out
	iverilog -I tests rtl/jtag_tap_controller.v rtl/jtag_tap.v tests/jtag_tap_tb.v && vvp a.out
	iverilog -I tests rtl/jtag_tap_controller.v rtl/jtag_tap.v tests/mac.v mac_wrapped.v tests/mac_wrapped_tb.v && vvp a.out