all: mac_wrapped.v
	iverilog -I tests rtl/jtag_tap_controller.v tests/jtag_tap_controller_tb.v && vvp a.out
	iverilog -I tests rtl/jtag_tap_controller.v rtl/jtag_tap.v tests/jtag_tap_tb.v && vvp a.out
	iverilog -I tests rtl/jtag_tap_controller.v rtl/jtag_tap.v tests/mac.v mac_wrapped.v tests/mac_wrapped_tb.v && vvp a.out

mac_wrapped.v: tests/mac.v generate_wrapper.py
	python3 generate_wrapper.py tests/mac.v