`timescale 1ns/1ps

module calibration_engine (
    // Inputs
    input  wire signed [15:0] y1_call,
    input  wire signed [15:0] y2_call,
    input  wire signed [15:0] y3_call,
    input  wire signed [15:0] y_stable,   // added (needed by storage)
    input  wire               clk,
    input  wire               reset,
    input  wire               store_en,

    // Outputs
    output wire signed [31:0] slope,
    output wire signed [31:0] intercept
);

    // Fixed x-values: 4, 7, 10
    localparam signed [3:0]  N      = 3;
    localparam signed [7:0]  SUM_X  = 21;   // 4 + 7 + 10
    localparam signed [15:0] SUM_X2 = 165;  // 16 + 49 + 100
    localparam signed [15:0] DENOM  = 54;   // (3*165) - (21*21)

    // Internal signals
    wire signed [31:0] sum_y;
    wire signed [31:0] sum_xy;
    wire signed [31:0] slope_num;
    wire signed [31:0] intercept_num;

    // Stored outputs (optional use)
    wire signed [31:0] slope_stored;
    wire signed [31:0] intercept_stored;
    wire signed [15:0] y1_stored;
    wire signed [15:0] y2_stored;
    wire signed [15:0] y3_stored;
    wire signed [15:0] y_stable_stored;

    // Summations
    assign sum_y  = y1_call + y2_call + y3_call;
    assign sum_xy = (4 * y1_call) + (7 * y2_call) + (10 * y3_call);

    // Linear regression numerators
    assign slope_num     = (N * sum_xy) - (SUM_X * sum_y);
    assign intercept_num = (sum_y * SUM_X2) - (SUM_X * sum_xy);

    // Final coefficients
    assign slope     = slope_num / DENOM;
    assign intercept = intercept_num / DENOM;

    // Storage module
    coeff_storage connection (
        .clk(clk),
        .reset(reset),
        .store_en(store_en),
        .y1_in(y1_call),
        .y2_in(y2_call),
        .y3_in(y3_call),
        .y_stable(y_stable),
        .slope_in(slope),
        .intercept_in(intercept),
        .y1_stored(y1_stored),
        .y2_stored(y2_stored),
        .y3_stored(y3_stored),
        .y_stable_stored(y_stable_stored),
        .slope_stored(slope_stored),
        .intercept_stored(intercept_stored)
    );

endmodule