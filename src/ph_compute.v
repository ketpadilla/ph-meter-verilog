`timescale 1ns/1ps

module ph_compute(
    // Inputs
    input  wire               clk,
    input  wire               reset,
    input  wire               store_en,

    // Inputs from calibration/storage
    input  wire signed [31:0] slope_call,
    input  wire signed [31:0] intercept_call,
    input  wire signed [15:0] y_now,

    // Output
    output wire signed [31:0] ph_value
);

    wire signed [63:0] numerator;
    wire signed [63:0] denominator;
    wire signed [63:0] ph_temp;

    assign numerator   = ($signed(y_now) - $signed(intercept_call)) * 64'sd100;
    assign denominator = $signed(slope_call);

    assign ph_temp  = (denominator != 0) ? ($signed(numerator) / $signed(denominator)) : 64'sd0;
    assign ph_value = ph_temp[31:0];

endmodule