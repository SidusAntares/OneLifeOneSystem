module clock_top #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer DEBOUNCE_TIME = 1000,
    parameter integer SCAN_CYCLE = 100_000
)(
    input wire clk,
    input wire rst_n,

    input wire key_hour,
    input wire key_min,
    input wire key_sec,

    input wire set_hour,
    input wire set_minute,
    input wire alarm_en,

    output wire [6:0] seg,
    output wire [5:0] an,

    output wire alarm_out
);
    wire tick_1hz;
    wire [5:0] hour, minute, second;
    wire key_hour_debounced, key_min_debounced, key_sec_debounced;

    clock_divider #(
        .CLK_HZ(CLK_HZ)
    ) u_clock_divider (
        .clk(clk),
        .rst_n(rst_n),
        .tick_1hz(tick_1hz)
    );

    time_counter u_time_counter (
        .clk(clk),
        .rst_n(rst_n),
        .tick_1hz(tick_1hz),
        .key_hour(key_hour_debounced),
        .key_min(key_min_debounced),
        .key_sec(key_sec_debounced),
        .hour(hour),
        .minute(minute),
        .second(second)
    );

    key #(
        .DEBOUNCE_TIME(DEBOUNCE_TIME)
    ) u_key_hour (
        .clk(clk),
        .rst_n(rst_n),
        .pulse_in(key_hour),
        .pulse_out(key_hour_debounced)
    );

    key #(
        .DEBOUNCE_TIME(DEBOUNCE_TIME)
    ) u_key_min (
        .clk(clk),
        .rst_n(rst_n),
        .pulse_in(key_min),
        .pulse_out(key_min_debounced)
    );

    key #(
        .DEBOUNCE_TIME(DEBOUNCE_TIME)
    ) u_key_sec (
        .clk(clk),
        .rst_n(rst_n),
        .pulse_in(key_sec),
        .pulse_out(key_sec_debounced)
    );

    seg_decoder #(
        .SCAN_CYCLE(SCAN_CYCLE)
    ) u_seg_decoder (
        .clk(clk),
        .rst_n(rst_n),
        .hour(hour),
        .minute(minute),
        .second(second),
        .seg(seg),
        .an(an)
    );

    alarm_controller #(
        .DEBOUNCE_TIME(DEBOUNCE_TIME)
    ) u_alarm_controller (
        .clk(clk),
        .rst_n(rst_n),
        .tick_1hz(tick_1hz),
        .set_hour(set_hour),
        .set_minute(set_minute),
        .hour(hour),
        .minute(minute),
        .alarm_en(alarm_en),
        .alarm_out(alarm_out)
    );
endmodule