module key #(
    parameter integer DEBOUNCE_TIME = 1000
)(
    input wire clk,
    input wire rst_n,
    input wire pulse_in,
    output reg pulse_out
);

    localparam integer COUNTER_WIDTH = DEBOUNCE_TIME <= 1 ? 1 : $clog2(DEBOUNCE_TIME);

    reg key_state;
    reg [COUNTER_WIDTH-1:0] counter;
    reg sync1, sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_out <= 0;
            key_state <= 0;
            counter <= 0;
            sync1 <= 0;
            sync2 <= 0;
        end else begin
            pulse_out <= 0;
            sync1 <= pulse_in;
            sync2 <= sync1;

            if (sync2 != key_state) begin
                counter <= counter + 1;
                if (counter == DEBOUNCE_TIME - 1) begin
                    counter <= 0;
                    key_state <= sync2;
                    if (sync2) begin
                        pulse_out <= 1;
                    end
                end
            end else begin
                counter <= 0;
            end
        end
    end
endmodule