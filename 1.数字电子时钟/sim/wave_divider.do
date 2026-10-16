add wave -divider "100 MHz clock & division"
add wave sim:/tb_clock_demo/clk
add wave -radix unsigned sim:/tb_clock_demo/dut/u_clock_divider/counter
add wave sim:/tb_clock_demo/dut/tick_1hz
add wave -divider "Counter consumes tick"
add wave -radix unsigned sim:/tb_clock_demo/dut/second
