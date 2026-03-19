module ph_compute(
//Sub-Input
input wire clk,
input wire reset,
input wire store_en,
//Input assignments since it will come from coeff_storage
wire signed [13:0] slope_call,
wire signed [13:0] intercept_call,
wire signed [13:0] y_now,
//Output
output wire signed [31:0] ph_value,
//Internal Connection
input wire signed [63:0] numerator, //To prevent overflow
);
 //Computation
 assign numerator = (y_now - intercept_call)*100;
 assign ph_value = numerator/slope_call;

//connect to the coeff_storage
coeff_storage connection (
    .clk(clk),
    .reset(reset),
    .store_en(store_en),
    //coefficients
    .slope_stored(slope_call),
    .y_stable(y_now),
    .intercept_stored(intercept_call)

);


endmodule