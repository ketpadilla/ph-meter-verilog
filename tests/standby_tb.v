// tests/standby_tb.v
//
// Testbench for the standby module
//
// To run this test:
// 1. Compile: iverilog -o out/standby_tb.vvp src/standby.v src/stability_checker.v tests/standby_tb.v
// 2. Simulate: vvp out/standby_tb.vvp
// 3. View Waveform: gtkwave out/standby_tb.vcd

`timescale 1ns/1ps

/**
 * @file standby_tb.v
 * @brief Testbench for standby FSM and stability-based latching.
 *
 * This testbench verifies:
 *  - Reset behavior
 *  - OFF -> STANDBY -> DISPLAY transitions
 *  - Unstable vs stable sensor readings
 *  - Latching of stable sensor values
 *  - Display hold timing
 *  - Power-off behavior
 *
 * Notes:
 *  - This testbench validates the standby/control block only.
 *  - It does not test pH computation or 7-segment display output.
 */
module standby_tb;

    /** Reduced hold time for faster simulation. */
    localparam DISPLAY_HOLD_MAX = 20;

    /** DUT inputs. */
    reg clk;
    reg rst;
    reg on_off;
    reg [11:0] sense;

    /** DUT outputs. */
    wire ph_ready;
    wire [11:0] sense_latched;
    wire [1:0] state_dbg;

    /**
     * Device Under Test (DUT).
     */
    standby #(
        .DISPLAY_HOLD_MAX(DISPLAY_HOLD_MAX)
    ) dut (
        .clk(clk),
        .rst(rst),
        .on_off(on_off),
        .sense(sense),
        .ph_ready(ph_ready),
        .sense_latched(sense_latched),
        .state_dbg(state_dbg)
    );

    /**
     * Generate a 10 ns clock.
     */
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    /**
     * Dump waveform output.
     */
    initial begin
        $dumpfile("out/standby_tb.vcd");
        $dumpvars(0, standby_tb);
    end

    /**
     * Convert state to readable text.
     */
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

    /**
     * Print readable monitor output.
     */
    initial begin
        $display("time\tstate\t\tsense\tlatched\tready");
        forever begin
            #10;
            $display("%0t\t%s\t%0d\t%0d\t%b",
                     $time,
                     state_name(state_dbg),
                     sense,
                     sense_latched,
                     ph_ready);
        end
    end

    /**
     * Apply unstable sensor input beyond tolerance.
     */
    task noisy_input;
        input [11:0] base;
        begin
            sense = base + 12'd6; #10;
            sense = base - 12'd7; #10;
            sense = base + 12'd5; #10;
            sense = base - 12'd6; #10;
        end
    endtask

    /**
     * Apply stable sensor input within tolerance.
     */
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

    /**
     * Check FSM state and ready flag.
     */
    task check_state_ready;
        input [1:0] expected_state;
        input expected_ready;
        begin
            #1;
            if ((state_dbg !== expected_state) || (ph_ready !== expected_ready)) begin
                $display("ERROR: Expected state=%0d ready=%0b, got state=%0d ready=%0b",
                         expected_state, expected_ready, state_dbg, ph_ready);
            end else begin
                $display("PASS: state=%0d ready=%0b", state_dbg, ph_ready);
            end
        end
    endtask

    /**
     * Check that the latched value is near the expected stable region.
     */
    task check_latched_near;
        input [11:0] expected_value;
        begin
            #1;
            if ((sense_latched == expected_value) ||
                (sense_latched == expected_value + 12'd1) ||
                (sense_latched == expected_value + 12'd2) ||
                (sense_latched == expected_value + 12'd4)) begin
                $display("PASS: latched sense=%0d", sense_latched);
            end else begin
                $display("ERROR: Expected latched near %0d, got %0d",
                         expected_value, sense_latched);
            end
        end
    endtask

    /**
     * Main stimulus sequence.
     */
    initial begin
        // ------------------------------------------------------------
        // TEST 0: Reset
        // ------------------------------------------------------------
        rst = 1'b1;
        on_off = 1'b0;
        sense = 12'd0;
        #20;
        rst = 1'b0;
        #20;
        check_state_ready(2'd0, 1'b0);

        // ------------------------------------------------------------
        // TEST 1: Turn ON -> STANDBY
        // ------------------------------------------------------------
        on_off = 1'b1;
        #20;
        check_state_ready(2'd1, 1'b0);

        // ------------------------------------------------------------
        // TEST 2: Unstable readings should remain in STANDBY
        // ------------------------------------------------------------
        noisy_input(12'd2048);
        #20;
        check_state_ready(2'd1, 1'b0);

        // ------------------------------------------------------------
        // TEST 3: Stable readings near neutral should latch and display
        // ------------------------------------------------------------
        stable_input(12'd2048);
        wait (state_dbg == 2'd2);
        #10;
        check_state_ready(2'd2, 1'b1);
        check_latched_near(12'd2048);

        wait (state_dbg == 2'd1);
        #10;
        check_state_ready(2'd1, 1'b0);

        // ------------------------------------------------------------
        // TEST 4: Stable readings near acidic region
        // ------------------------------------------------------------
        stable_input(12'd1170);
        wait (state_dbg == 2'd2);
        #10;
        check_state_ready(2'd2, 1'b1);
        check_latched_near(12'd1170);

        wait (state_dbg == 2'd1);
        #10;
        check_state_ready(2'd1, 1'b0);

        // ------------------------------------------------------------
        // TEST 5: Stable readings near basic region
        // ------------------------------------------------------------
        stable_input(12'd2925);
        wait (state_dbg == 2'd2);
        #10;
        check_state_ready(2'd2, 1'b1);
        check_latched_near(12'd2925);

        wait (state_dbg == 2'd1);
        #10;
        check_state_ready(2'd1, 1'b0);

        // ------------------------------------------------------------
        // TEST 6: Power OFF from STANDBY
        // ------------------------------------------------------------
        noisy_input(12'd2000);
        on_off = 1'b0;
        #20;
        check_state_ready(2'd0, 1'b0);

        // ------------------------------------------------------------
        // TEST 7: Turn ON again and relatch new stable value
        // ------------------------------------------------------------
        on_off = 1'b1;
        #20;
        check_state_ready(2'd1, 1'b0);

        stable_input(12'd1900);
        wait (state_dbg == 2'd2);
        #10;
        check_state_ready(2'd2, 1'b1);
        check_latched_near(12'd1900);

        // ------------------------------------------------------------
        // TEST 8: Power OFF during DISPLAY
        // ------------------------------------------------------------
        on_off = 1'b0;
        #20;
        check_state_ready(2'd0, 1'b0);

        // ------------------------------------------------------------
        // TEST 9: Reset during operation
        // ------------------------------------------------------------
        on_off = 1'b1;
        #20;
        stable_input(12'd2200);
        wait (state_dbg == 2'd2);
        #10;
        check_state_ready(2'd2, 1'b1);

        rst = 1'b1;
        #20;
        rst = 1'b0;
        on_off = 1'b0;
        #20;
        check_state_ready(2'd0, 1'b0);

        #50;
        $finish;
    end

endmodule