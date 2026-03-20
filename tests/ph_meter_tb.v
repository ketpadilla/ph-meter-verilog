// tests/ph_meter_tb.v
//
// Testbench for the main module
//
// To run this test:
// 1. Compile: iverilog -o out/ph_meter_tb.vvp src/main.v src/standby.v src/stability_checker.v src/calibration_engine.v src/coeff_storage.v src/ph_compute.v src/display_driver.v tests/ph_meter_tb.v
// 2. Simulate: vvp out/ph_meter_tb.vvp
// 3. View Waveform: gtkwave out/ph_meter_tb.vcd

`timescale 1ns/1ps

/**
 * @file ph_meter_tb.v
 * @brief Comprehensive integration testbench for the full pH meter system.
 *
 * Integrated modules:
 *  - standby
 *  - checkStability
 *  - calibration_engine
 *  - coeff_storage
 *  - ph_compute
 *  - display_module
 *
 * This testbench verifies:
 *  - Calibration coefficient generation and storage
 *  - Stability-based sensing and latching
 *  - pH computation correctness
 *  - 7-segment display correctness
 *  - Display blanking when system is off
 *  - Resolution-oriented checks (7.00, 7.01, 7.02)
 *  - Low-end and high-end range checks
 *  - Recalibration behavior
 *
 * Print controls:
 *  - ENABLE_PRETTY_PRINT = 1 -> structured summaries
 *  - ENABLE_RAW_TRACE    = 1 -> original time-based trace
 */
module ph_meter_tb;

    localparam DISPLAY_HOLD_MAX = 20;
    localparam integer REFRESH_DIV = 2;

    localparam ENABLE_PRETTY_PRINT = 1;
    localparam ENABLE_RAW_TRACE    = 1;

    reg clk;
    reg rst;
    reg on_off;
    reg [11:0] sense;

    reg signed [15:0] cal_y1;
    reg signed [15:0] cal_y2;
    reg signed [15:0] cal_y3;
    reg calib_store_en;

    wire [3:0] an;
    wire [6:0] seg;
    wire dp;

    wire ph_ready_dbg;
    wire [11:0] sense_latched_dbg;
    wire [1:0] state_dbg;
    wire signed [31:0] slope_dbg;
    wire signed [31:0] intercept_dbg;
    wire signed [31:0] ph_value_dbg;

    main #(
        .DISPLAY_HOLD_MAX(DISPLAY_HOLD_MAX),
        .REFRESH_DIV(REFRESH_DIV)
    ) dut (
        .clk(clk),
        .rst(rst),
        .on_off(on_off),
        .sense(sense),
        .cal_y1(cal_y1),
        .cal_y2(cal_y2),
        .cal_y3(cal_y3),
        .calib_store_en(calib_store_en),
        .an(an),
        .seg(seg),
        .dp(dp),
        .ph_ready_dbg(ph_ready_dbg),
        .sense_latched_dbg(sense_latched_dbg),
        .state_dbg(state_dbg),
        .slope_dbg(slope_dbg),
        .intercept_dbg(intercept_dbg),
        .ph_value_dbg(ph_value_dbg)
    );

    reg [3:0] captured_thousands;
    reg [3:0] captured_hundreds;
    reg [3:0] captured_tens;
    reg [3:0] captured_ones;

    reg seen_thousands;
    reg seen_hundreds;
    reg seen_tens;
    reg seen_ones;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("out/ph_meter_tb.vcd");
        $dumpvars(0, ph_meter_tb);
    end

    function integer seg_to_digit;
        input [6:0] seg_value;
        begin
            case (seg_value)
                7'b1000000: seg_to_digit = 0;
                7'b1111001: seg_to_digit = 1;
                7'b0100100: seg_to_digit = 2;
                7'b0110000: seg_to_digit = 3;
                7'b0011001: seg_to_digit = 4;
                7'b0010010: seg_to_digit = 5;
                7'b0000010: seg_to_digit = 6;
                7'b1111000: seg_to_digit = 7;
                7'b0000000: seg_to_digit = 8;
                7'b0010000: seg_to_digit = 9;
                default:    seg_to_digit = -1;
            endcase
        end
    endfunction

    function [8*10:1] state_name;
        input [1:0] s;
        begin
            case (s)
                2'd0: state_name = "OFF";
                2'd1: state_name = "STANDBY";
                2'd2: state_name = "DISPLAY";
                default: state_name = "UNKNOWN";
            endcase
        end
    endfunction

    task print_test_header;
        input [8*64:1] title;
        begin
            if (ENABLE_PRETTY_PRINT) begin
                $display("");
                $display("================================================================");
                $display("%s", title);
                $display("================================================================");
            end
        end
    endtask

    task print_coeff_summary;
        input signed [31:0] expected_slope;
        input signed [31:0] expected_intercept;
        begin
            if (ENABLE_PRETTY_PRINT) begin
                $display("Calibration Summary");
                $display("  Slope (actual)        : %0d", slope_dbg);
                $display("  Intercept (actual)    : %0d", intercept_dbg);
                $display("  Slope (expected)      : %0d", expected_slope);
                $display("  Intercept (expected)  : %0d", expected_intercept);
            end
        end
    endtask

    task print_measurement_summary;
        input [11:0] adc_base;
        input signed [31:0] expected_ph;
        begin
            if (ENABLE_PRETTY_PRINT) begin
                $display("Measurement Summary");
                $display("  ADC Input Base        : %0d", adc_base);
                $display("  Latched ADC Value     : %0d", sense_latched_dbg);
                $display("  FSM State             : %s", state_name(state_dbg));
                $display("  ph_ready              : %0b", ph_ready_dbg);
                $display("  Slope                 : %0d", slope_dbg);
                $display("  Intercept             : %0d", intercept_dbg);
                $display("  Computed pH (x100)    : %0d", ph_value_dbg);
                $display("  Expected pH (x100)    : %0d", expected_ph);
                $display("  Display Digits        : %0d%0d%0d%0d",
                         captured_thousands, captured_hundreds, captured_tens, captured_ones);
                $display("  Decimal Point (dp)    : %0b", dp);
            end
        end
    endtask

    task stable_input;
        input [11:0] base;
        integer i;
        begin
            for (i = 0; i < 10; i = i + 1) begin
                case (i % 3)
                    0: sense = base;
                    1: sense = base + 12'd1;
                    2: sense = base + 12'd2;
                endcase
                #10;
            end
        end
    endtask

    task noisy_input;
        input [11:0] base;
        begin
            sense = base + 12'd6; #10;
            sense = base - 12'd7; #10;
            sense = base + 12'd5; #10;
            sense = base - 12'd6; #10;
        end
    endtask

    task capture_display_digits;
        integer cycles;
        integer digit_value;
        begin
            captured_thousands = 4'd15;
            captured_hundreds  = 4'd15;
            captured_tens      = 4'd15;
            captured_ones      = 4'd15;

            seen_thousands = 1'b0;
            seen_hundreds  = 1'b0;
            seen_tens      = 1'b0;
            seen_ones      = 1'b0;

            for (cycles = 0; cycles < 100; cycles = cycles + 1) begin
                #10;
                digit_value = seg_to_digit(seg);

                case (an)
                    4'b1110: begin
                        if (digit_value >= 0) begin
                            captured_thousands = digit_value[3:0];
                            seen_thousands = 1'b1;
                        end
                    end
                    4'b1101: begin
                        if (digit_value >= 0) begin
                            captured_hundreds = digit_value[3:0];
                            seen_hundreds = 1'b1;
                        end
                    end
                    4'b1011: begin
                        if (digit_value >= 0) begin
                            captured_tens = digit_value[3:0];
                            seen_tens = 1'b1;
                        end
                    end
                    4'b0111: begin
                        if (digit_value >= 0) begin
                            captured_ones = digit_value[3:0];
                            seen_ones = 1'b1;
                        end
                    end
                endcase

                if (seen_thousands && seen_hundreds && seen_tens && seen_ones)
                    disable capture_display_digits;
            end
        end
    endtask

    task check_coefficients;
        input signed [31:0] expected_slope;
        input signed [31:0] expected_intercept;
        begin
            print_coeff_summary(expected_slope, expected_intercept);
            if ((slope_dbg !== expected_slope) || (intercept_dbg !== expected_intercept)) begin
                $display("RESULT                 : FAIL (coefficient mismatch)");
            end else begin
                $display("RESULT                 : PASS");
            end
        end
    endtask

    task check_display_disabled;
        begin
            if (ENABLE_PRETTY_PRINT) begin
                $display("Display Off Check");
                $display("  an                   : %b", an);
                $display("  ph_ready             : %0b", ph_ready_dbg);
                $display("  FSM State            : %s", state_name(state_dbg));
            end
            if (an !== 4'b1111) begin
                $display("RESULT                 : FAIL (display not blanked)");
            end else begin
                $display("RESULT                 : PASS");
            end
        end
    endtask

    task measure_and_check;
        input [8*64:1] test_name;
        input [11:0] adc_value;
        input signed [31:0] expected_ph_x100;
        input [3:0] exp_thousands;
        input [3:0] exp_hundreds;
        input [3:0] exp_tens;
        input [3:0] exp_ones;
        reg ph_ok;
        reg disp_ok;
        begin
            print_test_header(test_name);

            stable_input(adc_value);
            wait (ph_ready_dbg == 1'b1);
            #10;

            capture_display_digits;
            print_measurement_summary(adc_value, expected_ph_x100);

            ph_ok = (ph_value_dbg === expected_ph_x100);
            disp_ok = (captured_thousands === exp_thousands) &&
                      (captured_hundreds  === exp_hundreds)  &&
                      (captured_tens      === exp_tens)      &&
                      (captured_ones      === exp_ones);

            if (ENABLE_PRETTY_PRINT) begin
                if (!ph_ok)
                    $display("  Check pH Value        : FAIL");
                else
                    $display("  Check pH Value        : PASS");

                if (!disp_ok)
                    $display("  Check Display Digits  : FAIL");
                else
                    $display("  Check Display Digits  : PASS");
            end

            if (ph_ok && disp_ok)
                $display("RESULT                 : PASS");
            else
                $display("RESULT                 : FAIL");

            wait (state_dbg == 2'd1);
            #20;
        end
    endtask

    // Original raw trace style
    initial begin
        if (ENABLE_RAW_TRACE) begin
            $display("time\tsense\tlatched\tslope\tintercept\tph\tready\tstate");
            forever begin
                #10;
                $display("%0t\t%0d\t%0d\t%0d\t%0d\t\t%0d\t%b\t%0d",
                         $time,
                         sense,
                         sense_latched_dbg,
                         slope_dbg,
                         intercept_dbg,
                         ph_value_dbg,
                         ph_ready_dbg,
                         state_dbg);
            end
        end
    end

    initial begin
        rst = 1'b1;
        on_off = 1'b0;
        sense = 12'd0;

        cal_y1 = 16'sd1168;
        cal_y2 = 16'sd2044;
        cal_y3 = 16'sd2920;
        calib_store_en = 1'b0;

        #20;
        rst = 1'b0;

        print_test_header("TEST 00 - Initial Calibration Store");
        calib_store_en = 1'b1;
        #10;
        calib_store_en = 1'b0;
        #20;
        check_coefficients(32'sd292, 32'sd0);

        print_test_header("TEST 01 - Power On Transition");
        on_off = 1'b1;
        #20;
        if (ENABLE_PRETTY_PRINT) begin
            $display("Power On Summary");
            $display("  FSM State            : %s", state_name(state_dbg));
            $display("  ph_ready             : %0b", ph_ready_dbg);
        end
        if ((state_dbg === 2'd1) && (ph_ready_dbg === 1'b0))
            $display("RESULT                 : PASS");
        else
            $display("RESULT                 : FAIL");

        print_test_header("TEST 02 - Noisy Input Rejection");
        noisy_input(12'd2044);
        #20;
        if (ENABLE_PRETTY_PRINT) begin
            $display("Noise Rejection Summary");
            $display("  FSM State            : %s", state_name(state_dbg));
            $display("  ph_ready             : %0b", ph_ready_dbg);
            $display("  Latched ADC Value    : %0d", sense_latched_dbg);
        end
        if (ph_ready_dbg !== 1'b0)
            $display("RESULT                 : FAIL");
        else
            $display("RESULT                 : PASS");

        measure_and_check("TEST 03 - Measure pH 7.00", 12'd2044, 32'sd700, 4'd0, 4'd7, 4'd0, 4'd0);
        measure_and_check("TEST 04 - Measure pH 4.00", 12'd1168, 32'sd400, 4'd0, 4'd4, 4'd0, 4'd0);
        measure_and_check("TEST 05 - Measure pH 10.00", 12'd2920, 32'sd1000, 4'd1, 4'd0, 4'd0, 4'd0);

        measure_and_check("TEST 06 - Resolution Check pH 7.01", 12'd2047, 32'sd701, 4'd0, 4'd7, 4'd0, 4'd1);
        measure_and_check("TEST 07 - Resolution Check pH 7.02", 12'd2050, 32'sd702, 4'd0, 4'd7, 4'd0, 4'd2);

        measure_and_check("TEST 08 - Low-End Range Check pH 0.00", 12'd0, 32'sd0, 4'd0, 4'd0, 4'd0, 4'd0);
        measure_and_check("TEST 09 - High-End Range Check pH 14.00", 12'd4088, 32'sd1400, 4'd1, 4'd4, 4'd0, 4'd0);

        print_test_header("TEST 10 - Display Disable When System Is Off");
        on_off = 1'b0;
        #30;
        check_display_disabled;

        print_test_header("TEST 11 - Recalibration Store");
        cal_y1 = 16'sd1200;
        cal_y2 = 16'sd2100;
        cal_y3 = 16'sd3000;
        calib_store_en = 1'b1;
        #10;
        calib_store_en = 1'b0;
        #20;
        check_coefficients(32'sd300, 32'sd0);

        print_test_header("TEST 12 - Power On After Recalibration");
        on_off = 1'b1;
        #20;
        if (ENABLE_PRETTY_PRINT) begin
            $display("Power On Summary");
            $display("  FSM State            : %s", state_name(state_dbg));
            $display("  ph_ready             : %0b", ph_ready_dbg);
        end
        if ((state_dbg === 2'd1) && (ph_ready_dbg === 1'b0))
            $display("RESULT                 : PASS");
        else
            $display("RESULT                 : FAIL");

        measure_and_check("TEST 13 - Recalibrated Measure pH 7.00", 12'd2100, 32'sd700, 4'd0, 4'd7, 4'd0, 4'd0);
        measure_and_check("TEST 14 - Recalibrated Measure pH 10.00", 12'd3000, 32'sd1000, 4'd1, 4'd0, 4'd0, 4'd0);

        print_test_header("FINAL SUMMARY");
        if (ENABLE_PRETTY_PRINT) begin
            $display("Comprehensive full-system integration test completed.");
            $display("Review PASS/FAIL markers above for each scenario.");
            $display("Waveform file generated: out/ph_meter_tb.vcd");
        end

        #50;
        $finish;
    end

endmodule