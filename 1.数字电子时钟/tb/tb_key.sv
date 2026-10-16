
`timescale 1ns/1ps

module tb_key;

    reg clk = 0;
    reg rst_n = 0;
    reg pulse_in = 0;
    wire pulse_out;

    integer pulse_count = 0;

    always #5 clk = ~clk;

    key #(
        .DEBOUNCE_TIME(4)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pulse_in(pulse_in),
        .pulse_out(pulse_out)
    );

    // 统计产生的脉冲
    always @(posedge clk) begin
        if (rst_n && pulse_out)
            pulse_count <= pulse_count + 1;
    end

    initial begin
        #12 rst_n = 1;

        // 测试1：短暂抖动，不应触发
        @(negedge clk);
        pulse_in = 1;
        repeat (2) @(negedge clk);
        pulse_in = 0;
        repeat (8) @(negedge clk);

        if (pulse_count != 0)
            $fatal(1, "Bounce test failed");

        // 测试2：稳定按下，应产生一次脉冲
        pulse_in = 1;
        repeat (20) @(negedge clk);

        if (pulse_count != 1)
            $fatal(1, "Press test failed");

        // 测试3：持续按住，不应重复触发
        repeat (20) @(negedge clk);

        if (pulse_count != 1)
            $fatal(1, "Long press test failed");

        // 测试4：松开后再次按下
        pulse_in = 0;
        repeat (10) @(negedge clk);

        pulse_in = 1;
        repeat (20) @(negedge clk);

        if (pulse_count != 2)
            $fatal(1, "Second press test failed");

        $display("All key tests passed");
        $finish;
    end

endmodule
