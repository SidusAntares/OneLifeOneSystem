// 输入是 100 MHz 的 clk，输出每秒一次的 tick_1hz。如果验收要求实际的 1 Hz 方波，也可以增加相应输出。
module clock_divider #(
    parameter integer CLK_HZ = 100_000_000 // 输入时钟频率
)(
    input wire clk,
    input wire rst_n,
    output reg tick_1hz
);
    reg[31:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            tick_1hz <= 0;
        end else begin
            if (counter == CLK_HZ - 1) begin
                counter <= 0;
                tick_1hz <= 1;
            end else begin
                counter <= counter + 1;
                tick_1hz <= 0;
            end
        end
    end
endmodule