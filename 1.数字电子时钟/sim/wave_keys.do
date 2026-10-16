add wave -divider "Button inputs"
add wave sim:/tb_clock_demo/key_hour
add wave sim:/tb_clock_demo/key_min
add wave sim:/tb_clock_demo/key_sec
add wave -divider "Debounced 1-cycle events"
add wave sim:/tb_clock_demo/dut/key_hour_debounced
add wave sim:/tb_clock_demo/dut/key_min_debounced
add wave sim:/tb_clock_demo/dut/key_sec_debounced
add wave -divider "Clock values"
add wave -radix unsigned sim:/tb_clock_demo/dut/hour
add wave -radix unsigned sim:/tb_clock_demo/dut/minute
add wave -radix unsigned sim:/tb_clock_demo/dut/second
add wave -radix unsigned sim:/tb_clock_demo/phase
