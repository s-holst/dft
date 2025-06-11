all:
	iverilog -I tb rtl/jtag_tap_controller.v tb/jtag_tap_controller_tb.v && vvp a.out