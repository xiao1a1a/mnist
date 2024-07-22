`timescale 1ns/1ps

module conv1
(
    input           clk,
    input           rst_n,
    input           upstream_busy,
    input [7:0]     data_in,

    output reg [9:0] raddr,
    output reg       ren,
    output [10:0]   waddr,
    output          wen,
    output [11:0]   data_out
);

    reg upstream_busy_d1;
    reg [4:0] index_x, index_y;
    reg [1:0] channel_cnt;
    localparam IDLE = 3'b001, FILL = 3'b010, CALC = 3'b100;
    reg [3:0] state, next_state;
    

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: next_state = (upstream_busy && ~upstream_busy_d1)? FILL: IDLE;
            FILL: next_state = (raddr == 139)? CALC: FILL;
            CALC: next_state = (index_x==27 && index_y==23 && channel_cnt == 3)? IDLE: CALC;  
            default: next_state = IDLE;
        endcase
    end

    reg [7:0] buffer [0:139];
    reg [7:0] buffer_addr;


    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            raddr <= 0;
            ren <= 0;
        end else begin
            case (state)
                IDLE: begin
                    raddr <= 0;
                    ren <= 0;
                end
                FILL: begin
                    raddr <= raddr + 1;
                    buff
                end
                default: 
            endcase
        end
    end

endmodule