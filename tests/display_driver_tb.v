// tests/display_driver_tb.v
//
// Testbench for the display_module module
//
// To run this test:
// 1. Compile: iverilog -o out/display_driver_tb.vvp src/display_driver.v tests/display_driver_tb.v
// 2. Simulate: vvp out/display_driver_tb.vvp
// 3. View Waveform: gtkwave out/display_driver_tb.vcd

`timescale 1ns/1ps

/**
 * @file display_driver_tb.v
 * @brief Testbench for the multiplexed 7-segment display module.
 *
 * This testbench verifies:
 *  - Reset behavior
 *  - Enable/disable display
 *  - Digit multiplexing sequence
 *  - BCD to 7-segment decoding
 *  - Decimal point placement
 *
 * NOTE:
 * REFRESH_DIV is reduced for faster simulation.
 */
module display_driver_tb;

    /** Small divider for faster simulation. */
    localparam integer REFRESH_DIV = 3;

    /** DUT inputs. */
    reg clk;
    reg rst;
    reg enable_display;
    reg [13:0] ph_value;

    /** DUT outputs. */
    wire [3:0] an;
    wire [6:0] seg;
    wire dp;

    /**
     * Device Under Test (DUT).
     */
    display_module #(
        .REFRESH_DIV(REFRESH_DIV)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable_display(enable_display),
        .ph_value(ph_value),
        .an(an),
        .seg(seg),
        .dp(dp)
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
        $dumpfile("out/display_driver_tb.vcd");
        $dumpvars(0, display_driver_tb);
    end

    /**
     * Converts an active-low 7-segment pattern into a decimal digit.
     *
     * @param seg_value Active-low segment pattern.
     * @return Decoded decimal digit, or -1 if invalid.
     */
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

    /**
     * Converts anode value to digit position.
     *
     * Positions:
     *   0 = thousands
     *   1 = hundreds
     *   2 = tens
     *   3 = ones
     *
     * @param an_value Active-low anode pattern.
     * @return Active digit position, or -1 if invalid/blank.
     */
    function integer an_to_pos;
        input [3:0] an_value;
        begin
            case (an_value)
                4'b1110: an_to_pos = 0;
                4'b1101: an_to_pos = 1;
                4'b1011: an_to_pos = 2;
                4'b0111: an_to_pos = 3;
                default: an_to_pos = -1;
            endcase
        end
    endfunction

    /**
     * Prints readable output showing the currently active digit.
     *
     * Example printed digits include values like 0, 1, 4, and 9.
     */
    initial begin
        $display("time\tph_value\tpos\tdigit\tdp\tan\tseg");
        forever begin
            #10;
            $display("%0t\t%0d\t\t%0d\t%0d\t%b\t%b\t%b",
                     $time,
                     ph_value,
                     an_to_pos(an),
                     seg_to_digit(seg),
                     dp,
                     an,
                     seg);
        end
    end

    /**
     * Applies test stimulus.
     */
    initial begin
        // Reset and disabled state.
        rst = 1'b1;
        enable_display = 1'b0;
        ph_value = 14'd0;

        #12;
        rst = 1'b0;

        // Keep disabled for a short time.
        #20;

        // Test 1: Display 1234.
        enable_display = 1'b1;
        ph_value = 14'd1234;
        #120;

        // Test 2: Display 7049.
        ph_value = 14'd7049;
        #120;

        // Test 3: Display 0987.
        ph_value = 14'd987;
        #120;

        // Test 4: Disable display.
        enable_display = 1'b0;
        #40;

        // Test 5: Display 0014.
        enable_display = 1'b1;
        ph_value = 14'd14;
        #120;

        $finish;
    end

endmodule