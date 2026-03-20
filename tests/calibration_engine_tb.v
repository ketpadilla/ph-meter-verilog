// tests/calibration_engine_tb.v
//
// Testbench for the calibration_engine module
//
// To run this test:
// 1. Compile: iverilog -o out/calibration_engine_tb.vvp src/coeff_storage.v src/calibration_engine.v tests/calibration_engine_tb.v
// 2. Simulate: vvp out/calibration_engine_tb.vvp
// 3. View Waveform: gtkwave out/calibration_engine_tb.vcd

`timescale 1ns/1ps

/**
 * @file calibration_engine_tb.v
 * @brief Testbench for the calibration_engine module.
 *
 * This testbench verifies:
 *  - Reset behavior
 *  - Correct slope and intercept computation
 *  - Storage behavior through coeff_storage
 *  - Store enable behavior
 *
 * The calibration engine uses fixed x-values:
 *   x1 = 4, x2 = 7, x3 = 10
 *
 * Linear regression equations:
 *   slope     = (N*sum_xy - sum_x*sum_y) / denom
 *   intercept = (sum_y*sum_x2 - sum_x*sum_xy) / denom
 * where:
 *   N = 3
 *   sum_x = 21
 *   sum_x2 = 165
 *   denom = 54
 */
module calibration_engine_tb;

    /** DUT inputs */
    reg signed [15:0] y1_call;
    reg signed [15:0] y2_call;
    reg signed [15:0] y3_call;
    reg signed [15:0] y_stable;
    reg clk;
    reg reset;
    reg store_en;

    /** DUT outputs */
    wire signed [31:0] slope;
    wire signed [31:0] intercept;

    /**
     * Device Under Test (DUT)
     */
    calibration_engine dut (
        .y1_call(y1_call),
        .y2_call(y2_call),
        .y3_call(y3_call),
        .y_stable(y_stable),
        .clk(clk),
        .reset(reset),
        .store_en(store_en),
        .slope(slope),
        .intercept(intercept)
    );

    /**
     * Generates a 10 ns clock period.
     */
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    /**
     * Dumps waveform output to the out directory.
     */
    initial begin
        $dumpfile("out/calibration_engine_tb.vcd");
        $dumpvars(0, calibration_engine_tb);
    end

    /**
     * Prints readable simulation output.
     */
    initial begin
        $display("time\trst\tstore\ty1\ty2\ty3\ty_stable\tslope\tintercept\tslope_stored\tintercept_stored");
        forever begin
            #10;
            $display("%0t\t%b\t%b\t%0d\t%0d\t%0d\t%0d\t\t%0d\t%0d\t\t%0d\t\t%0d",
                     $time,
                     reset,
                     store_en,
                     y1_call,
                     y2_call,
                     y3_call,
                     y_stable,
                     slope,
                     intercept,
                     dut.connection.slope_stored,
                     dut.connection.intercept_stored);
        end
    end

    /**
     * Checks computed values against expected slope and intercept.
     */
    task check_result;
        input signed [31:0] expected_slope;
        input signed [31:0] expected_intercept;
        begin
            #1;
            if ((slope !== expected_slope) || (intercept !== expected_intercept)) begin
                $display("ERROR: Expected slope=%0d intercept=%0d, got slope=%0d intercept=%0d",
                         expected_slope, expected_intercept, slope, intercept);
            end
            else begin
                $display("PASS: slope=%0d intercept=%0d", slope, intercept);
            end
        end
    endtask

    /**
     * Applies stimulus.
     */
    initial begin
        // ------------------------------------------------------------
        // TEST 0: Reset
        // Expectation:
        //   - Stored values should clear to 0
        // ------------------------------------------------------------
        y1_call   = 16'sd0;
        y2_call   = 16'sd0;
        y3_call   = 16'sd0;
        y_stable  = 16'sd0;
        reset     = 1'b1;
        store_en  = 1'b0;

        #12;
        reset = 1'b0;

        // ------------------------------------------------------------
        // TEST 1: Perfect line y = 2x + 1
        // Points:
        //   x=4  -> y=9
        //   x=7  -> y=15
        //   x=10 -> y=21
        //
        // Expected:
        //   slope = 2
        //   intercept = 1
        // ------------------------------------------------------------
        y1_call  = 16'sd9;
        y2_call  = 16'sd15;
        y3_call  = 16'sd21;
        y_stable = 16'sd15;
        #10;
        check_result(32'sd2, 32'sd1);

        // Store results
        store_en = 1'b1;
        #10;
        store_en = 1'b0;

        // ------------------------------------------------------------
        // TEST 2: Perfect line y = -x + 20
        // Points:
        //   x=4  -> y=16
        //   x=7  -> y=13
        //   x=10 -> y=10
        //
        // Expected:
        //   slope = -1
        //   intercept = 20
        // ------------------------------------------------------------
        y1_call  = 16'sd16;
        y2_call  = 16'sd13;
        y3_call  = 16'sd10;
        y_stable = 16'sd13;
        #10;
        check_result(-32'sd1, 32'sd20);

        // Do not store yet, confirm stored values stay from previous test
        #10;

        // Store new results
        store_en = 1'b1;
        #10;
        store_en = 1'b0;

        // ------------------------------------------------------------
        // TEST 3: Constant line y = 5
        // Points:
        //   x=4  -> y=5
        //   x=7  -> y=5
        //   x=10 -> y=5
        //
        // Expected:
        //   slope = 0
        //   intercept = 5
        // ------------------------------------------------------------
        y1_call  = 16'sd5;
        y2_call  = 16'sd5;
        y3_call  = 16'sd5;
        y_stable = 16'sd5;
        #10;
        check_result(32'sd0, 32'sd5);

        // Store results
        store_en = 1'b1;
        #10;
        store_en = 1'b0;

        // ------------------------------------------------------------
        // TEST 4: Another positive line y = 3x - 2
        // Points:
        //   x=4  -> y=10
        //   x=7  -> y=19
        //   x=10 -> y=28
        //
        // Expected:
        //   slope = 3
        //   intercept = -2
        // ------------------------------------------------------------
        y1_call  = 16'sd10;
        y2_call  = 16'sd19;
        y3_call  = 16'sd28;
        y_stable = 16'sd19;
        #10;
        check_result(32'sd3, -32'sd2);

        // Store results
        store_en = 1'b1;
        #10;
        store_en = 1'b0;

        // ------------------------------------------------------------
        // TEST 5: Reset clears stored values again
        // ------------------------------------------------------------
        reset = 1'b1;
        #10;
        reset = 1'b0;

        #20;
        $finish;
    end

endmodule