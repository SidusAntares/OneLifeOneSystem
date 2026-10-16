add wave -divider "Alarm setting & enable buttons"
add wave sim:/tb_clock_demo/set_hour
add wave sim:/tb_clock_demo/set_minute
add wave sim:/tb_clock_demo/alarm_en
add wave -divider "Stored alarm setting"
add wave -radix unsigned sim:/tb_clock_demo/dut/u_alarm_controller/alarm_hour
add wave -radix unsigned sim:/tb_clock_demo/dut/u_alarm_controller/alarm_minute
add wave sim:/tb_clock_demo/dut/u_alarm_controller/alarm_enabled
add wave -divider "Current time & alarm output"
add wave -radix unsigned sim:/tb_clock_demo/dut/hour
add wave -radix unsigned sim:/tb_clock_demo/dut/minute
add wave -radix unsigned sim:/tb_clock_demo/dut/second
add wave sim:/tb_clock_demo/alarm_out
add wave -radix unsigned sim:/tb_clock_demo/phase
