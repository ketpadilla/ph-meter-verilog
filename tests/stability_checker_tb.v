// tests/stability_chekcer_tb.v
//
// Testbench for the stability_checker module
//
// To run this test:
// 1. Compile: iverilog -o out/stability_checker_tb.vvp src/stability_checker.v tests/stability_checker_tb.v
// 2. Simulate: vvp out/stability_checker_tb.vvp
// 3. View Waveform: gtkwave out/stability_checker_tb.vcd


`timescale 1ns/1ps

/**
 * @file stability_checker_tb.v
 * @brief Testbench for the checkStability module.
 *
 * This testbench verifies the behavior of the stability checker module
 * under different operating conditions, including:
 *  - Reset behavior
 *  - Disabled operation
 *  - Stable signal detection
 *  - Unstable signal rejection
 *  - Recovery after instability
 *  - Reset during operation
 *
 * Output:
 *  - VCD waveform file: out/stability_checker_tb.vcd
 */
module stability_checker_tb;

    /** Parameters matching DUT */
    parameter WIDTH = 12;
    parameter TOLERANCE = 12'd4;
    parameter STABLE_COUNT_MAX = 8;

    /** DUT inputs */
    reg clk;
    reg rst;
    reg en;
    reg [WIDTH-1:0] sense;

    /** DUT outputs */
    wire stable;
    wire [WIDTH-1:0] stable_sense;

    /**
     * Device Under Test (DUT)
     */
    checkStability #(
        .WIDTH(WIDTH),
        .TOLERANCE(TOLERANCE),
        .STABLE_COUNT_MAX(STABLE_COUNT_MAX)
    ) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .sense(sense),
        .stable(stable),
        .stable_sense(stable_sense)
    );

    /**
     * Clock generator
     * Generates a 10 ns period clock.
     */
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    /**
     * Waveform dump
     * Outputs VCD file to /out directory.
     */
    initial begin
        $dumpfile("out/stability_checker_tb.vcd");
        $dumpvars(0, stability_checker_tb);
    end

    /**
     * Monitor
     * Prints signal values for quick debugging.
     */
    initial begin
        $display("Time\tclk\trst\ten\tsense\tstable\tstable_sense");
        $monitor("%0t\t%b\t%b\t%b\t%0d\t%b\t%0d",
                 $time, clk, rst, en, sense, stable, stable_sense);
    end

    /**
     * Stimulus sequence
     * Applies different test scenarios to validate DUT behavior.
     */
    initial begin
        // ------------------------------------------------------------
        // INITIALIZATION
        // ------------------------------------------------------------
        rst   = 1'b1;
        en    = 1'b0;
        sense = 12'd0;

        #12;
        rst = 1'b0;

        // ------------------------------------------------------------
        // TEST 1: Disabled operation
        // Expectation:
        //   - stable remains 0
        //   - internal state does not accumulate stability
        // ------------------------------------------------------------
        #10; sense = 12'd100;
        #10; sense = 12'd101;
        #10; sense = 12'd102;

        // ------------------------------------------------------------
        // TEST 2: Stable sequence detection
        // Expectation:
        //   - diff <= TOLERANCE consistently
        //   - stable asserts after STABLE_COUNT_MAX cycles
        // ------------------------------------------------------------
        en = 1'b1;

        sense = 12'd200; #10;
        sense = 12'd202; #10;
        sense = 12'd201; #10;
        sense = 12'd203; #10;
        sense = 12'd204; #10;
        sense = 12'd202; #10;
        sense = 12'd205; #10;
        sense = 12'd204; #10;
        sense = 12'd203; #10;  // Expected: stable = 1 here

        // Continue stable region
        sense = 12'd204; #10;
        sense = 12'd202; #10;

        // ------------------------------------------------------------
        // TEST 3: Unstable jump
        // Expectation:
        //   - diff > TOLERANCE resets stability
        //   - stable returns to 0
        // ------------------------------------------------------------
        sense = 12'd260; #10;
        sense = 12'd261; #10;
        sense = 12'd262; #10;

        // ------------------------------------------------------------
        // TEST 4: Recovery after instability
        // Expectation:
        //   - stability must rebuild from zero
        // ------------------------------------------------------------
        sense = 12'd300; #10;
        sense = 12'd302; #10;
        sense = 12'd301; #10;
        sense = 12'd303; #10;
        sense = 12'd304; #10;
        sense = 12'd303; #10;
        sense = 12'd302; #10;
        sense = 12'd301; #10;
        sense = 12'd300; #10;

        // ------------------------------------------------------------
        // TEST 5: Disable during operation
        // Expectation:
        //   - stable forced to 0
        // ------------------------------------------------------------
        en = 1'b0;
        sense = 12'd301; #20;

        // ------------------------------------------------------------
        // TEST 6: Reset during operation
        // Expectation:
        //   - all states cleared immediately
        // ------------------------------------------------------------
        en = 1'b1;
        sense = 12'd400; #10;
        sense = 12'd401; #10;

        rst = 1'b1; #10;
        rst = 1'b0; #10;

        // Post-reset stability test
        sense = 12'd500; #10;
        sense = 12'd501; #10;
        sense = 12'd502; #10;
        sense = 12'd501; #10;
        sense = 12'd500; #10;
        sense = 12'd502; #10;
        sense = 12'd503; #10;
        sense = 12'd501; #10;
        sense = 12'd500; #10;

        #30;
        $finish;
    end

endmodule