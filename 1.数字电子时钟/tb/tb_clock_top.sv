`timescale 1ns/1ps

// Full-system functional test for rtl(2).zip.
// Required RTL precondition: alarm_controller has a DEBOUNCE_TIME parameter,
// forwarded to all three of its key instances; clock_top forwards it too.
module tb_clock_top;
    // 100 MHz input is still modelled by a 10 ns period.
    // CLK_HZ is reduced ONLY to accelerate the simulated one-second tick.
    localparam integer SIM_CLK_HZ       = 10_000;
    localparam integer SIM_DEBOUNCE     = 4;
    localparam integer SIM_SCAN_CYCLE   = 3;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg key_hour = 1'b0;
    reg key_min = 1'b0;
    reg key_sec = 1'b0;
    reg set_hour = 1'b0;
    reg set_minute = 1'b0;
    reg alarm_en = 1'b0;

    wire [6:0] seg;
    wire [5:0] an;
    wire alarm_out;

    always #5 clk = ~clk;

    clock_top #(
        .CLK_HZ(SIM_CLK_HZ),
        .DEBOUNCE_TIME(SIM_DEBOUNCE),
        .SCAN_CYCLE(SIM_SCAN_CYCLE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .key_hour(key_hour),
        .key_min(key_min),
        .key_sec(key_sec),
        .set_hour(set_hour),
        .set_minute(set_minute),
        .alarm_en(alarm_en),
        .seg(seg),
        .an(an),
        .alarm_out(alarm_out)
    );

    // Drive asynchronous keys on falling clock edges to avoid stimulus races.
    // Key IDs: 0 hour, 1 minute, 2 second,
    //          3 alarm hour, 4 alarm minute, 5 alarm enable/disable.
    task automatic drive_key(input integer id, input reg level);
    begin
        case (id)
            0: key_hour = level;
            1: key_min = level;
            2: key_sec = level;
            3: set_hour = level;
            4: set_minute = level;
            5: alarm_en = level;
            default: $fatal(1, "Invalid key ID %0d", id);
        endcase
    end
    endtask

    task automatic reset_dut;
    begin
        @(negedge clk);
        rst_n = 1'b0;
        key_hour = 0; key_min = 0; key_sec = 0;
        set_hour = 0; set_minute = 0; alarm_en = 0;
        repeat (4) @(negedge clk);
        rst_n = 1'b1;
        repeat (5) @(negedge clk);
    end
    endtask

    task automatic tap(input integer id);
    begin
        @(negedge clk);
        drive_key(id, 1'b1);
        repeat (12) @(negedge clk);
        drive_key(id, 1'b0);
        repeat (12) @(negedge clk);
    end
    endtask

    task automatic check_time(input integer h, input integer m, input integer s);
    begin
        if (dut.hour !== h[5:0] ||
            dut.minute !== m[5:0] ||
            dut.second !== s[5:0]) begin
            $fatal(1, "Time: got %0d:%0d:%0d, expected %0d:%0d:%0d at %0t",
                   dut.hour, dut.minute, dut.second, h, m, s, $time);
        end
    end
    endtask

    // Expected active-low 7-segment code with bit order {g,f,e,d,c,b,a}.
    function automatic [6:0] seg_code(input integer d);
        case (d)
            0: seg_code = 7'b1000000;
            1: seg_code = 7'b1111001;
            2: seg_code = 7'b0100100;
            3: seg_code = 7'b0110000;
            4: seg_code = 7'b0011001;
            5: seg_code = 7'b0010010;
            6: seg_code = 7'b0000010;
            7: seg_code = 7'b1111000;
            8: seg_code = 7'b0000000;
            9: seg_code = 7'b0010000;
            default: seg_code = 7'b1111111;
        endcase
    endfunction

    task automatic check_display(input integer h, input integer m, input integer s);
        integer i, digit;
        reg [5:0] expected_an;
    begin
        for (i = 0; i < 6; i = i + 1) begin
            case (i)
                0: digit = h / 10;
                1: digit = h % 10;
                2: digit = m / 10;
                3: digit = m % 10;
                4: digit = s / 10;
                5: digit = s % 10;
            endcase
            wait (dut.u_seg_decoder.scan_index == i);
            #1;  // allow combinational segment/position outputs to settle
            expected_an = ~(6'b000001 << i);
            if (an !== expected_an || seg !== seg_code(digit))
                $fatal(1, "Display pos=%0d: an=%b seg=%b, expected an=%b seg=%b",
                       i, an, seg, expected_an, seg_code(digit));
        end
    end
    endtask

    // Wait for a real registered divider pulse and let time_counter consume it.
    // The counter reacts at the NEXT posedge because tick is registered.
    task automatic wait_tick_consumed;
    begin
        @(negedge clk);
        while (dut.tick_1hz !== 1'b1)
            @(negedge clk);
        @(negedge clk);
        if (dut.tick_1hz !== 1'b0)
            $fatal(1, "Divider tick wider than one clock");
    end
    endtask

    integer i;
    initial begin
        // 1. Reset, leading zeros, six multiplexed digits.
        reset_dut();
        check_time(0, 0, 0);
        if (alarm_out !== 1'b0)
            $fatal(1, "Alarm active after reset");
        check_display(0, 0, 0);
        $display("PASS 1: reset and display 00:00:00");

        // 2. Short bounce must not adjust seconds.
        @(negedge clk); key_sec = 1;
        repeat (2) @(negedge clk);
        key_sec = 0;
        repeat (12) @(negedge clk);
        check_time(0, 0, 0);

        // 3. One long press must increment exactly once.
        @(negedge clk); key_sec = 1;
        repeat (50) @(negedge clk);
        check_time(0, 0, 1);
        key_sec = 0;
        repeat (12) @(negedge clk);
        check_time(0, 0, 1);
        tap(2);
        check_time(0, 0, 2);
        tap(1);
        tap(0);
        check_time(1, 1, 2);
        check_display(1, 1, 2);
        $display("PASS 2: bounce rejection, long press, and three adjustment keys");

        // 4. Clock divider pulse width and spacing; counter increments once/tick.
        reset_dut();
        wait_tick_consumed();
        check_time(0, 0, 1);
        // At first observed tick high the simulation had just passed its
        // rising edge. After consumption we are exactly 1 cycle past that tick.
        // The next tick must occur SIM_CLK_HZ-1 cycles later.
        for (i = 1; i < SIM_CLK_HZ - 1; i = i + 1) begin
            @(negedge clk);
            if (dut.tick_1hz !== 1'b0)
                $fatal(1, "Early divider tick at cycle %0d", i);
        end
        @(negedge clk);
        if (dut.tick_1hz !== 1'b1)
            $fatal(1, "Divider tick spacing is not CLK_HZ cycles");
        @(negedge clk);
        if (dut.tick_1hz !== 1'b0)
            $fatal(1, "Divider tick width is not one clock");
        check_time(0, 0, 2);
        $display("PASS 3: divider period, single-cycle tick, and counting");

        // 5. User input -> binary time -> all six seven-segment outputs.
        reset_dut();
        for (i = 0; i < 12; i = i + 1) tap(0);
        for (i = 0; i < 34; i = i + 1) tap(1);
        for (i = 0; i < 56; i = i + 1) tap(2);
        check_time(12, 34, 56);
        check_display(12, 34, 56);
        $display("PASS 4: 12:34:56 time setting and six-digit display");

        // 6. Natural carry across seconds, minutes, and midnight.
        reset_dut();
        for (i = 0; i < 23; i = i + 1) tap(0);
        for (i = 0; i < 59; i = i + 1) tap(1);
        for (i = 0; i < 59; i = i + 1) tap(2);
        check_time(23, 59, 59);
        wait_tick_consumed();
        check_time(0, 0, 0);
        check_display(0, 0, 0);
        $display("PASS 5: midnight rollover 23:59:59 -> 00:00:00");

        // 7. Alarm setup, arming, match, cancel, hour+minute comparison.
        reset_dut();
        tap(4); // alarm minute := 1
        tap(5); // enable alarm
        if (dut.u_alarm_controller.alarm_minute !== 6'd1 ||
            dut.u_alarm_controller.alarm_enabled !== 1'b1)
            $fatal(1, "Alarm setting/enable key did not work");
        if (alarm_out !== 1'b0)
            $fatal(1, "Alarm triggered before target minute");
        for (i = 0; i < 59; i = i + 1) tap(2);
        check_time(0, 0, 59);
        wait_tick_consumed();
        check_time(0, 1, 0);
        if (alarm_out !== 1'b1)
            $fatal(1, "Alarm did not trigger at 00:01");
        repeat (40) @(negedge clk);
        if (alarm_out !== 1'b1)
            $fatal(1, "Alarm should stay active during matching minute");
        tap(5); // disable, while still in matching minute
        if (alarm_out !== 1'b0)
            $fatal(1, "Alarm cancel failed");
        tap(3); // alarm hour := 1, now alarm is 01:01
        tap(5); // re-enable
        if (alarm_out !== 1'b0)
            $fatal(1, "Alarm ignored hour comparison");
        tap(0); // manually set time to 01:01 -> alarm goes high
        check_time(1, 1, 0);
        if (alarm_out !== 1'b1)
            $fatal(1, "Alarm does not respond to matching hour+minute");
        tap(1); // minute 01:02 -> alarm stops
        if (alarm_out !== 1'b0)
            $fatal(1, "Alarm did not stop after leaving target minute");
        $display("PASS 6: alarm setup, match, cancel, mismatch");

        $display("ALL TOP-LEVEL TESTS PASSED");
        $finish;
    end

    initial begin
        #10_000_000; // 10 ms simulation watchdog
        $fatal(1, "Top-level simulation timed out");
    end
endmodule
