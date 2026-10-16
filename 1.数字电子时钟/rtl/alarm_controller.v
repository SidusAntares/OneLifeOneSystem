module alarm_controller #(
    parameter integer DEBOUNCE_TIME = 1000
)(
    input wire clk,
    input wire rst_n,
    input wire tick_1hz,

    input wire set_hour,
    input wire set_minute,
    input wire [5:0] hour,
    input wire [5:0] minute,

    input wire alarm_en,
    output wire alarm_out
);
    reg [5:0] alarm_hour;
    reg [5:0] alarm_minute;

    wire set_hour_debounced;
    wire set_minute_debounced;
    wire set_alarm_debounced;

    reg alarm_enabled;

    key #(
        .DEBOUNCE_TIME(DEBOUNCE_TIME)
    ) u_key_set_hour (
        .clk(clk),
        .rst_n(rst_n),
        .pulse_in(set_hour),
        .pulse_out(set_hour_debounced)
    );

    key #(
        .DEBOUNCE_TIME(DEBOUNCE_TIME)
    ) u_key_set_minute (
        .clk(clk),
        .rst_n(rst_n),
        .pulse_in(set_minute),
        .pulse_out(set_minute_debounced)
    );

    key #(
        .DEBOUNCE_TIME(DEBOUNCE_TIME)
    ) u_key_alarm_en (
        .clk(clk),
        .rst_n(rst_n),
        .pulse_in(alarm_en),
        .pulse_out(set_alarm_debounced)
    );

    assign alarm_out = alarm_enabled &&
        (hour == alarm_hour) && (minute == alarm_minute);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alarm_hour <= 0;
            alarm_minute <= 0;
            alarm_enabled <= 0;
        end

        else if (set_hour_debounced) begin
            if (alarm_hour == 23) begin
                alarm_hour <= 0;
            end else begin
                alarm_hour <= alarm_hour + 1;
            end
        end

        else if (set_minute_debounced) begin
            if (alarm_minute == 59) begin
                alarm_minute <= 0;
            end else begin
                alarm_minute <= alarm_minute + 1;
            end
        end

        else if (set_alarm_debounced) begin
            alarm_enabled <= ~alarm_enabled;
        end

    end
endmodule