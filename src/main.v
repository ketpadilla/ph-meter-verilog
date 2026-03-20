`timescale 1ns/1ps

module main #(
    parameter DISPLAY_HOLD_MAX = 32'd50_000_000,
    parameter integer REFRESH_DIV = 50_000
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               on_off,
    input  wire [11:0]        sense,

    // Calibration inputs
    input  wire signed [15:0] cal_y1,
    input  wire signed [15:0] cal_y2,
    input  wire signed [15:0] cal_y3,
    input  wire               calib_store_en,

    // 7-segment display outputs
    output wire [3:0]         an,
    output wire [6:0]         seg,
    output wire               dp,

    // Debug outputs
    output wire               ph_ready_dbg,
    output wire [11:0]        sense_latched_dbg,
    output wire [1:0]         state_dbg,
    output wire signed [31:0] slope_dbg,
    output wire signed [31:0] intercept_dbg,
    output wire signed [31:0] ph_value_dbg
);

    wire ph_ready;
    wire [11:0] sense_latched;
    wire [1:0] standby_state_dbg;

    wire signed [31:0] slope;
    wire signed [31:0] intercept;
    wire signed [31:0] ph_value;

    wire signed [15:0] sense_latched_signed;
    wire [13:0] ph_display_value;

    assign sense_latched_signed = {4'd0, sense_latched};
    assign ph_display_value = ph_value[13:0];

    standby #(
        .DISPLAY_HOLD_MAX(DISPLAY_HOLD_MAX)
    ) u_standby (
        .clk(clk),
        .rst(rst),
        .on_off(on_off),
        .sense(sense),
        .ph_ready(ph_ready),
        .sense_latched(sense_latched),
        .state_dbg(standby_state_dbg)
    );

    calibration_engine u_calibration_engine (
        .y1_call(cal_y1),
        .y2_call(cal_y2),
        .y3_call(cal_y3),
        .y_stable(sense_latched_signed),
        .clk(clk),
        .reset(rst),
        .store_en(calib_store_en),
        .slope(slope),
        .intercept(intercept)
    );

    ph_compute u_ph_compute (
        .clk(clk),
        .reset(rst),
        .store_en(calib_store_en),
        .slope_call(slope),
        .intercept_call(intercept),
        .y_now(sense_latched_signed),
        .ph_value(ph_value)
    );

    display_module #(
        .REFRESH_DIV(REFRESH_DIV)
    ) u_display_module (
        .clk(clk),
        .rst(rst),
        .enable_display(ph_ready),
        .ph_value(ph_display_value),
        .an(an),
        .seg(seg),
        .dp(dp)
    );

    assign ph_ready_dbg = ph_ready;
    assign sense_latched_dbg = sense_latched;
    assign state_dbg = standby_state_dbg;
    assign slope_dbg = slope;
    assign intercept_dbg = intercept;
    assign ph_value_dbg = ph_value;

endmodule