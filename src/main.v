module main_standby #(
    parameter DISPLAY_HOLD_MAX = 32'd50_000_000
)(
    input wire clk,
    input wire rst,
    input wire on_off,
    input wire [11:0] sense,

    output reg ph_ready,
    output reg [11:0] sense_latched,
    output reg [1:0] state_dbg
);
    
    localparam S_OFF = 2'd0;
    localparam S_STANDBY = 2'd1;
    localparam S_DISPLAY = 2'd2;

    reg [1:0] state, next_state;
    reg [31:0] display_counter;

    wire stable;
    wire [11:0] stable_sense;

    checkstability #(
        .WIDTH(12),
        .TOLERANCE(12'd4),
        .STABLE_COUNT_MAX(8)
    ) u_checkstability (
        .clk(clk),
        .rst(rst),
        en(state == S_STANDBY),
        .sense(sense),
        .stable(stable),
        .stable_sense(stable_sense)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_OFF;
            display_counter <= 0;
            sense_latched <= 0;
        end

        else begin
            state <= next_state;

            if (state == S_STANDBY && stable)
                sense_latched <= stable_sense;

            if (state == S_DISPLAY) begin
                if (display_counter < DISPLAY_HOLD_MAX)
                    display_counter <= display_counter + 1'b1;
                else
                    display_counter <= 0;
            end

            else begin
                display_counter <= 0;
            end
        end
    end

    always @(*) begin
        next_state = state;

        case (state)
            S_OFF: begin
                if (on_off)
                    next_state = S_STANDBY;
            end

            S_STANDBY: begin
                if (!on_off)
                    next_state = S_OFF;
                else if (stable)
                    next_state = S_DISPLAY;
            end

            S_DISPLAY: begin
                if (!on_off)
                    next_state = S_OFF;
                else if (display_counter >= DISPLAY_HOLD_MAX)
                    next_state = S_STANDBY;
            end

            default: next_state = S_OFF;
        endcase
    end

    always @(*) begin
        ph_ready = 1'b0;
        state_dbg = state;

        case(state)
            S_OFF: ph_ready = 1'b0;
            S_STANDBY: ph_ready = 1'b0;
            S_DISPLAY: ph_ready = 1'b1;
            default: ph_ready = 1'b0;
        endcase
    end

endmodule