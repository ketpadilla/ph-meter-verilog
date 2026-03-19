'`timescale 1ns/1ps

module calibration_engine (
    //inputs 
    wire signed [15:0] y1_call,
    wire signed [15:0] y2_call,
    wire signed [15:0] y3_call,
    //subinputs for storing values
    input wire signed clk,
    input wire reset,
    input wire store_en
    //outputs
    output wire signed [31:0] slope,
    output wire signed [31:0] intercept
);
    //Linear Regression Parameters
    localparam signed [3:0] S = 3;
    localparam signed [7:0] Sum_X = 21;
    localparam signed [15:0] Sum_x2 = 165;

    //Internal Connections
    wire signed [31:0] Sum_y;
    wire signed [31:0] Sum_xy;

    //Assignment of Values (Computation)
    assign Sum_y = y1 + y2 +y3;
    assign Sum_xy = (4*y1) + (7*y2) + (10*y3);
    
    //Linear Regression values

    assign slope = (N*Sum_xy) - (Sum_x*Sum_y);
    assign intercept = (Sum_y*Sum_x2) - (Sum_x * Sum_xy);

    //Storing the slope and the intercept
    coeff_storage connection (
        .clk(clk),
        .reset(reset),
        .store_en(store_en),
        .slope_in(slope),
        .intercept_in(intercept),
        .slope_stored(slope_in),
        .intercept_stored(intercept_in),
        .y1_stored(y1_call),
        .y2_stored(y2_call),
        .y3_stored(y3_call)


    );

endmodule