# Run from the VerilogClock project root, e.g.:
# cd C:/Code/dev/PythonProject/verilog/VerilogClock
# do sim/01_divider.do

if {![info exists SCENE] || ![info exists SIM_HZ]} {
    error "Use a numbered launcher under sim/, not run_common.do directly"
}
if {![file isdirectory work]} {vlib work}
if {![file isdirectory sim/results]} {file mkdir sim/results}

# Keep the old self-checking testbench unchanged; compile this NEW demo TB.
vlog -sv rtl/clock_divider.v rtl/time_counter.v rtl/key_debounce.v rtl/seg_decoder.v rtl/alarm_controller.v rtl/clock_top.v tb/tb_clock_demo.sv

catch {quit -sim}
vsim -voptargs=+acc -gSIM_CLK_HZ=$SIM_HZ -wlf sim/results/$SCENE.wlf work.tb_clock_demo +SCENE=$SCENE
onfinish stop

# Wave configuration deliberately contains ONLY the signals for this scene.
view wave
catch {delete wave *}
do sim/wave_$SCENE.do
run -all
wave zoom full
puts "DEMO completed: $SCENE. Saved data to sim/results/$SCENE.wlf"
