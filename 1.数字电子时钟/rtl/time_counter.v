// 输入包括 clk、复位和 tick_1hz，输出 hour、minute、second
module time_counter (
    input wire clk,
    input wire rst_n,
    input wire tick_1hz,

    input wire key_hour,
    input wire key_min,
    input wire key_sec,

    output reg [5:0] hour,
    output reg [5:0] minute,
    output reg [5:0] second
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hour <= 0;
            minute <= 0;
            second <= 0;
        end

        else if(key_sec) begin
            if (second == 59) begin
                second <= 0;
            end else begin
                second <= second + 1;
            end
        end

        else if (key_min) begin
            if (minute == 59) begin
                minute <= 0;
            end else begin
                minute <= minute + 1;
            end
        end

        else if (key_hour) begin
            if (hour == 23) begin
                hour <= 0;
            end else begin
                hour <= hour + 1;
            end
        end

        else if (tick_1hz) begin
            if (second == 59) begin
                second <= 0;
                if (minute == 59) begin
                    minute <= 0;
                    if (hour == 23) begin
                        hour <= 0;
                    end else begin
                        hour <= hour + 1;
                    end
                end else begin
                    minute <= minute + 1;
                end
            end else begin
                second <= second + 1;
            end
        end
    end

endmodule