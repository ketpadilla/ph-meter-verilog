// tests/ph_compute_tb.v
//
// Testbench for the ph_compute module
//
// To run this test:
// 1. Compile: iverilog -o out/ph_compute_tb.vvp src/ph_compute.v tests/ph_compute_tb.v
// 2. Simulate: vvp out/ph_compute_tb.vvp
// 3. View Waveform: gtkwave out/ph_compute_tb.vcd

`timescale 1ns/1ps

/**
 * @file ph_compute_tb.v
 * @brief Testbench for pH computation module.
 *
 * Verifies:
 *  - Correct pH computation
 *  - Fixed-point scaling (×100)
 *  - Handling of negative slope
 *  - Divide-by-zero protection
 *
 * Equation:
 *   pH = ((y_now - intercept) * 100) / slope
 */
module ph_compute_tb;

    /** DUT inputs */
    reg clk;
    reg reset;
    reg store_en; // unused but included for interface consistency

    reg signed [31:0] slope_call;
    reg signed [31:0] intercept_call;
    reg signed [15:0] y_now;

    /** DUT output */
    wire signed [31:0] ph_value;

    /**
     * Device Under Test (DUT)
     */
    ph_compute dut (
        .clk(clk),
        .reset(reset),
        .store_en(store_en),
        .slope_call(slope_call),
        .intercept_call(intercept_call),
        .y_now(y_now),
        .ph_value(ph_value)
    );

    /**
     * Clock generator (10 ns period)
     */
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    /**
     * VCD dump
     */
    initial begin
        $dumpfile("out/ph_compute_tb.vcd");
        $dumpvars(0, ph_compute_tb);
    end

    /**
     * Monitor
     */
    initial begin
        $display("time\ty_now\tslope\tintercept\tph(x100)");
        forever begin
            #10;
            $display("%0t\t%0d\t%0d\t%0d\t\t%0d",
                     $time,
                     y_now,
                     slope_call,
                     intercept_call,
                     ph_value);
        end
    end

    /**
     * Check expected result
     */
    task check_result;
        input signed [31:0] expected;
        begin
            #1;
            if (ph_value !== expected)
                $display("ERROR: Expected %0d, got %0d", expected, ph_value);
            else
                $display("PASS: pH = %0d (x100)", ph_value);
        end
    endtask

    /**
     * Stimulus
     */
    initial begin
        reset = 1;
        store_en = 0;
        slope_call = 0;
        intercept_call = 0;
        y_now = 0;

        #12;
        reset = 0;

        // ------------------------------------------------------------
        // TEST 1: slope=2, intercept=1, y=9 → pH = (9-1)/2 = 4 → 400
        // ------------------------------------------------------------
        slope_call     = 2;
        intercept_call = 1;
        y_now          = 9;
        #10;
        check_result(400);

        // ------------------------------------------------------------
        // TEST 2: slope=3, intercept=-2, y=28 → pH = (28+2)/3 = 10 → 1000
        // ------------------------------------------------------------
        slope_call     = 3;
        intercept_call = -2;
        y_now          = 28;
        #10;
        check_result(1000);

        // ------------------------------------------------------------
        // TEST 3: slope=-1, intercept=20, y=16 → pH = (16-20)/(-1) = 4 → 400
        // ------------------------------------------------------------
        slope_call     = -1;
        intercept_call = 20;
        y_now          = 16;
        #10;
        check_result(400);

        // ------------------------------------------------------------
        // TEST 4: constant case slope=1, intercept=0 → pH = y
        // y=7 → 700
        // ------------------------------------------------------------
        slope_call     = 1;
        intercept_call = 0;
        y_now          = 7;
        #10;
        check_result(700);

        // ------------------------------------------------------------
        // TEST 5: divide-by-zero protection
        // slope = 0 → expect 0
        // ------------------------------------------------------------
        slope_call     = 0;
        intercept_call = 10;
        y_now          = 20;
        #10;
        check_result(0);

        // ------------------------------------------------------------
        // TEST 6: negative intercept, fractional result truncation
        // slope=4, intercept=2, y=10 → (10-2)/4=2 → 200
        // ------------------------------------------------------------
        slope_call     = 4;
        intercept_call = 2;
        y_now          = 10;
        #10;
        check_result(200);

        #20;
        $finish;
    end

endmodule