module display_module #(
    parameter RESEARCH_DIV = 16'd50_000_000
)(
    input wire clk,
    input wire rst,
    input wire enable_display,
    input wire [13:0] ph_value,

    output reg [3:0] an,
    output reg [6:0] seg,
    output reg dp
);

    reg [15:0] refresh_count;
    reg [1:0] digit_sel;
    reg [3:0] digit_bcd;

    wire [3:0] thousands;
    wire [3:0] hundreds;
    wire [3:0] tens;
    wire [3:0] ones;

    assign thousands = (ph_value / 1000) % 10;
    assign hundreds = (ph_value / 100) % 10;
    assign tens = (ph_value / 10) % 10;
    assign ones = (ph_value / 10);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            refresh_count <= 16'd0;
            digit_sel <= 2'd0;
        end

        else begin
            if (refresh_count >= REFRESH_DIV) begin
                refresh_count <= 16'd0;
                digit_sel <= digit_sel +1'b1;
            end
            else begin
                refresh_count <= refresh_count + 1'b1;
            end
        end
    end

    always @(*) begin
        if (!enable_display) begin
            an = 4'b1111;
            digit_bcd = 4'd0;
            dp = 1'b1;
        end

        else begin
            case (digit_sel)
                2'd0: begin
                    an = 4'b1110;
                    digit_bcd = thousands;
                    dp = 1'b1;
                end

                2'd1: begin
                    an = 4'b1101;
                    digit_bcd = hundreds;
                    dp = 1'b0;
                end

                2'd2: begin
                    an = 4'b1011;
                    digit_bcd = tens;
                    dp = 1'b1
                end

                2'd3: begin
                    an = 4'b0111;
                    digit_bcd = ones;
                    dp = 1'b1;
                end

                default: begin
                    an = 4'b1111;
                    digit_bcd = 4'd0;
                    dp = 1'b1;
                end
            endcase
        end
    end



    # BCD to 7-segment decoder
    always @(*) begin
        case (digit_bcd)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

endmodule