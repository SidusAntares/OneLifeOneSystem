add wave -divider "Daytime carry: test setup, then tick-driven counting"
add wave sim:/tb_clock_demo/dut/tick_1hz
add wave -radix unsigned sim:/tb_clock_demo/dut/hour
add wave -radix unsigned sim:/tb_clock_demo/dut/minute
add wave -radix unsigned sim:/tb_clock_demo/dut/second
