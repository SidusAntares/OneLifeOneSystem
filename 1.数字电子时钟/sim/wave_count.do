add wave -divider "Time carry and midnight rollover"
add wave sim:/tb_clock_demo/dut/tick_1hz
add wave -radix unsigned sim:/tb_clock_demo/dut/hour
add wave -radix unsigned sim:/tb_clock_demo/dut/minute
add wave -radix unsigned sim:/tb_clock_demo/dut/second
add wave -radix unsigned sim:/tb_clock_demo/phase
