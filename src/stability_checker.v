module checkStability #(
    parameter WIDTH = 12,
    parameter TOLERANCE = 12'd4,
    parameter STABLE_COUNT_MAX = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [WIDTH-1:0] sense,
    output reg stable,
    output reg [WIDTH-1:0] stable_sense
);

    reg [WIDTH-1:0] prev_sense;
    reg [7:0] stable count;
    wire [WIDTH-1:0] diff;
    assign diff = (sense >= prev_sense) ? (sense - prev_sense) : (prev_sense - sense);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_sense <= 0;
            stable_count <= 0;
            stable <= 0;
            stable_sense <= 0;
        end

        else if (en) begin
            if (diff <= TOLERANCE) begin
                if (stable_count < STABLE_COUNT_MAX)
                    stable_count <= stable_count +1'b1;

                if (stable_count >= STABLE_COUNT_MAX - 1) begin
                    stable <= 1'b1;
                    stable_sense <= sense;
                end

                else begin
                    stable <= 1'b0;
                end
            end

            else begin
                stable_count <= 0;
                stable <= 1'b0;
            end

            prev_sense <= sense;
        end

        else begin
            stable <= 1'b0;
            stable_count <= 0;
        end
    end

endmodule
