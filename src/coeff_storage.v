'`timescale 1ns/1ps
module coeff_storage(
    //Input
    input wire clk,
    input wire reset,
    input wire store_en,
    input wire signed [15:0] y1_in,
    input wire signed [15:0] y2_in,
    input wire signed [15:0] y3_in,
    input wire signed [15:0] y_stable,
    input wire signed [31:0] slope_in,
    input wire signed [31:0] intercept_in,
    //Output
    output reg signed [15:0] y1_stored,
    output reg signed [15:0] y2_stored,
    output reg signed [15:0] y3_stored,
    output reg signed [15:0] y_stable_stored,
    output reg signed [31:0] slope_stored,
    output reg signed [31:0] intercept_stored
    

);
    //clock logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            slope_stored <= 32'd0;
            intercept_stored <=32'd0;
            y1_stored <= 16'd0;
            y2_stored <= 16'd0;
            y3_stored <= 16'd0;
            y_stable_stored <= 16'd0;
        end
        else if (store_en) begin
            slope_stored <= slope_in;
            intercept_stored <= intercept_in;
            y1_stored <= y1_in;
            y2_stored <= y2_in;
            y3_stored <= y3_in;
            y_stable_stored <= y_stable;
        end
    end
endmodule