`timescale 1ns/1ps

// Demonstration TB for the CURRENT VerilogClock RTL (October 2026).
// Same real input clock period (10 ns, 100 MHz), shortened divider COUNT
// for quick functional demonstration. It does NOT claim the accelerated
// output tick is physically 1 Hz.
module tb_clock_demo #(
    parameter integer SIM_CLK_HZ = 10_000,
    parameter integer SIM_DEBOUNCE = 4,
    parameter integer SIM_SCAN_CYCLE = 3
);
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg key_hour = 1'b0, key_min = 1'b0, key_sec = 1'b0;
    reg set_hour = 1'b0, set_minute = 1'b0, alarm_en = 1'b0;
    wire [6:0] seg;
    wire [5:0] an;
    wire alarm_out;
    integer phase = 0;

    // Exactly 100 MHz stimulus: 10 ns per clock period.
    always #5 clk = ~clk;

    clock_top #(
        .CLK_HZ(SIM_CLK_HZ),
        .DEBOUNCE_TIME(SIM_DEBOUNCE),
        .SCAN_CYCLE(SIM_SCAN_CYCLE)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .key_hour(key_hour), .key_min(key_min), .key_sec(key_sec),
        .set_hour(set_hour), .set_minute(set_minute), .alarm_en(alarm_en),
        .seg(seg), .an(an), .alarm_out(alarm_out)
    );

    task automatic reset_all;
        begin
            @(negedge clk);
            rst_n = 0;
            key_hour = 0; key_min = 0; key_sec = 0;
            set_hour = 0; set_minute = 0; alarm_en = 0;
            repeat (4) @(negedge clk);
            rst_n = 1;
            repeat (5) @(negedge clk);
        end
    endtask

    task automatic set_key(input integer id, input reg state);
        begin
            case (id)
                0: key_hour = state;
                1: key_min = state;
                2: key_sec = state;
                3: set_hour = state;
                4: set_minute = state;
                5: alarm_en = state;
                default: $fatal(1,"Unsupported key ID %0d",id);
            endcase
        end
    endtask

    // DEBOUNCE=4, including the two-stage synchronizer.
    task automatic press(input integer id);
        begin
            @(negedge clk);
            set_key(id,1'b1);
            repeat (12) @(negedge clk);
            set_key(id,1'b0);
            repeat (12) @(negedge clk);
        end
    endtask

    task automatic assert_time(input integer h,input integer m,input integer s);
        begin
            if (dut.hour !== h[5:0] || dut.minute !== m[5:0] || dut.second !== s[5:0])
                $fatal(1,"Time mismatch: got %0d:%0d:%0d; expected %0d:%0d:%0d",
                          dut.hour,dut.minute,dut.second,h,m,s);
        end
    endtask

    task automatic consume_one_tick;
        begin
            @(posedge dut.tick_1hz);
            repeat (2) @(negedge clk);
        end
    endtask

    function automatic [6:0] seg_code(input integer d);
        case (d)
            0:seg_code=7'b1000000; 1:seg_code=7'b1111001;
            2:seg_code=7'b0100100; 3:seg_code=7'b0110000;
            4:seg_code=7'b0011001; 5:seg_code=7'b0010010;
            6:seg_code=7'b0000010; 7:seg_code=7'b1111000;
            8:seg_code=7'b0000000; 9:seg_code=7'b0010000;
            default:seg_code=7'b1111111;
        endcase
    endfunction

    task automatic demo_divider;
        integer i;
        begin
            phase=1;
            $display("[DEMO divider] 10 ns input clock; tick every %0d input cycles (SIMULATION ACCELERATION)",SIM_CLK_HZ);
            for (i=1;i<=3;i=i+1) begin
                consume_one_tick();
                assert_time(0,0,i);
                $display("  tick %0d: clock counter has advanced to 00:00:%0d at %0t",i,i,$time);
            end
            $display("PASS DEMO divider");
        end
    endtask

    task automatic demo_count;
        begin
            // Test-only state injection to keep the carry-boundary waveform short.
            // This is NOT a normal end-user operation; the normal key path is
            // demonstrated separately in the keys scene.
            phase=1;
            @(negedge clk);
            dut.u_time_counter.hour=6'd12;
            dut.u_time_counter.minute=6'd59;
            dut.u_time_counter.second=6'd58;
            // Give the module output-port nets one simulation delta to settle.
            // The check reads dut.hour/minute/second, not the child registers.
            #1;
            assert_time(12,59,58);
            $display("[DEMO count] TEST SETUP: inject 12:59:58 for carry demonstration");
            consume_one_tick();
            assert_time(12,59,59);
            consume_one_tick();
            assert_time(13,0,0);
            $display("PASS DEMO count: 12:59:58 -> 12:59:59 -> 13:00:00");
        end
    endtask

    task automatic demo_midnight;
        begin
            // Test-only state injection keeps this independent rollover
            // waveform short and separate from the daytime carry scene.
            phase=1;
            @(negedge clk);
            dut.u_time_counter.hour=6'd23;
            dut.u_time_counter.minute=6'd59;
            dut.u_time_counter.second=6'd59;
            // Allow output-port nets to reflect the injected child registers.
            #1;
            assert_time(23,59,59);
            $display("[DEMO midnight] TEST SETUP: inject 23:59:59; observed transition begins at the next tick");
            consume_one_tick();
            assert_time(0,0,0);
            $display("PASS DEMO midnight: 23:59:59 -> 00:00:00");
        end
    endtask

    task automatic demo_keys;
        begin
            phase=1;
            $display("[DEMO keys] reject bounce shorter than threshold");
            @(negedge clk); key_sec=1;
            repeat (2) @(negedge clk);
            key_sec=0;
            repeat (12) @(negedge clk);
            assert_time(0,0,0);
            phase=2;
            press(0); press(1); press(2);
            assert_time(1,1,1);
            $display("[DEMO keys] single presses set 01:01:01");
            phase=3;
            @(negedge clk); key_hour=1;
            repeat (50) @(negedge clk);
            assert_time(2,1,1);
            key_hour=0;
            repeat (12) @(negedge clk);
            assert_time(2,1,1);
            $display("PASS DEMO keys: bounce ignored, hour/min/sec adjusted, long press only once");
        end
    endtask

    task automatic demo_display;
        integer k, digit, idx;
        reg [5:0] observed, expected_an;
        begin
            // Test-only state injection isolates display from key presses.
            phase=1;
            @(negedge clk);
            dut.u_time_counter.hour=6'd12;
            dut.u_time_counter.minute=6'd34;
            dut.u_time_counter.second=6'd56;
            observed=6'b0;
            for(k=0;k<6*SIM_SCAN_CYCLE+10;k=k+1) begin
                @(negedge clk);
                idx=dut.u_seg_decoder.scan_index;
                case(idx)
                    0:digit=1; 1:digit=2; 2:digit=3;
                    3:digit=4; 4:digit=5; 5:digit=6;
                    default:$fatal(1,"Bad scan index %0d",idx);
                endcase
                expected_an=~(6'b000001 << idx);
                if(an !== expected_an || seg !== seg_code(digit))
                    $fatal(1,"Display scan=%0d seg=%b an=%b",idx,seg,an);
                observed[idx]=1'b1;
            end
            if(observed!==6'b111111)
                $fatal(1,"Not all six display positions scanned: %b",observed);
            $display("PASS DEMO display: 12:34:56 on six positions, active-low {g,f,e,d,c,b,a}");
        end
    endtask

    task automatic demo_alarm;
        begin
            phase=1;
            press(3);        // alarm hour = 1
            press(4); press(4); // alarm minute = 2
            press(5);        // enable
            if(dut.u_alarm_controller.alarm_hour !== 6'd1 ||
               dut.u_alarm_controller.alarm_minute !== 6'd2 ||
               dut.u_alarm_controller.alarm_enabled !== 1'b1)
                $fatal(1,"Alarm setting failed");
            if(alarm_out !== 1'b0) $fatal(1,"Alarm should be silent before match");
            $display("[DEMO alarm] set alarm to 01:02 and enabled it via buttons");

            // Test-only state injection makes a natural minute carry visible.
            phase=2;
            @(negedge clk);
            dut.u_time_counter.hour=6'd1;
            dut.u_time_counter.minute=6'd1;
            dut.u_time_counter.second=6'd59;
            consume_one_tick();
            assert_time(1,2,0);
            if(alarm_out !== 1'b1) $fatal(1,"Alarm failed to start at 01:02");
            repeat (30) @(negedge clk);
            if(alarm_out !== 1'b1) $fatal(1,"Alarm should remain on during matching minute");
            $display("[DEMO alarm] 01:01:59 -> 01:02:00, alarm_out=1");

            phase=3;
            press(5); // disable while within matching minute
            if(alarm_out !== 1'b0) $fatal(1,"Alarm failed to cancel");
            $display("PASS DEMO alarm: set, enable, minute match, persistent alarm, cancel");
        end
    endtask

    string scene;
    initial begin
        if(!$value$plusargs("SCENE=%s",scene)) scene="divider";
        reset_all();
        if      (scene=="divider") demo_divider();
        else if (scene=="count")   demo_count();
        else if (scene=="midnight") demo_midnight();
        else if (scene=="keys")    demo_keys();
        else if (scene=="display") demo_display();
        else if (scene=="alarm")   demo_alarm();
        else $fatal(1,"Unknown demo SCENE '%s'",scene);
        $display("ALL DEMO CHECKS PASSED: %s",scene);
        $finish;
    end

    // Guard against accidental hangs.
    initial begin
        #10_000_000;
        $fatal(1,"Demo timeout");
    end
endmodule
