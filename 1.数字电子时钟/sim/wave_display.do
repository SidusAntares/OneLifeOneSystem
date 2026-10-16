add wave -divider "Display 12:34:56"
add wave -radix unsigned sim:/tb_clock_demo/dut/hour
add wave -radix unsigned sim:/tb_clock_demo/dut/minute
add wave -radix unsigned sim:/tb_clock_demo/dut/second
add wave -divider "Multiplexed 7-segment lines (active low)"
add wave -radix unsigned sim:/tb_clock_demo/dut/u_seg_decoder/scan_index
add wave -radix binary sim:/tb_clock_demo/an
add wave -radix binary sim:/tb_clock_demo/seg
