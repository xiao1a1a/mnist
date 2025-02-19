`timescale 1ns/1ps

module conv1
(
    input           clk,
    input           rst_n,
    input           upstream_busy,
    input [7:0]     data_in,

    output reg [9:0] raddr,
    output reg       ren,
    output reg [10:0]   waddr,
    output reg         wen,
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

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            upstream_busy_d1 <= 1;
        end else begin
            upstream_busy_d1 <= upstream_busy;
        end
    end
    
    

    always @(*) begin
        case (state)
            IDLE: next_state = (~upstream_busy && upstream_busy_d1)? FILL: IDLE;
            FILL: next_state = (raddr == 140)? CALC: FILL;
            CALC: next_state = (index_x==27 && index_y==23 && channel_cnt == 3)? IDLE: CALC;  
            default: next_state = IDLE;
        endcase
    end

    reg [7:0] buffer [0:139];
    reg [7:0] buffer_addr;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            index_x <= 0;
            index_y <= 0;
            channel_cnt <= 0;
        end else begin
            if (state != CALC) begin
                index_x <= 0;
                index_y <= 0;
                channel_cnt <= 0;
            end else begin
                if(index_x == 27) begin
                    if(channel_cnt == 2) begin
                        if(index_y != 23) begin
                            index_y <= index_y + 1;
                            channel_cnt <= 0;
                            index_x <= 0;
                        end else begin
                            //保持原值
                        end
                    end else begin
                        channel_cnt <= channel_cnt + 1;
                        index_x <= 0;
                    end
                end else begin
                    index_x <= index_x + 1;
                end
            end
        end
    end

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
                    if(raddr != 140) begin
                        ren <= 1;
                        raddr <= ren? raddr + 1: raddr;
                        buffer_addr <= raddr[7:0];
                        buffer[buffer_addr] <= data_in;
                    end else begin
                        ren <= 0;
                        buffer[buffer_addr] <= data_in;
                    end

                end
                CALC: begin
                    if(channel_cnt == 2'b01 && index_x == 27)begin
                        ren <= 1;
                        raddr <= raddr + 1;
                    end
                    if(channel_cnt == 2 ) begin
                        if(index_x != 27)begin
                            raddr <= raddr + 1;
                            buffer[index_x] <= buffer[index_x + 28];
                            buffer[index_x + 28] <= buffer[index_x + 56];
                            buffer[index_x + 56] <= buffer[index_x + 84];
                            buffer[index_x + 84] <= buffer[index_x + 112];
                            buffer[index_x + 112] <= data_in;
                        end else begin
                            ren <= 0;
                            buffer[index_x] <= buffer[index_x + 28];
                            buffer[index_x + 28] <= buffer[index_x + 56];
                            buffer[index_x + 56] <= buffer[index_x + 84];
                            buffer[index_x + 84] <= buffer[index_x + 112];
                            buffer[index_x + 112] <= data_in;

                        end
                    end 

                end
                default: begin
                    raddr <= 0;
                    ren <= 0;
                end
            endcase
        end
    end

    reg signed [7:0] w_1[0:24], w_2[0:24], w_3 [0:24];
    reg signed [7:0] bias [0:2];
    reg signed [7:0] w_sel[0:24];
    reg signed [7:0] bias_sel;
    
    initial begin
        $readmemh("C:/Users/VeriMake_C1/Desktop/lyj/mnisty/sources/rtl/weights/conv1_weight_1.txt", w_1);
        $readmemh("C:/Users/VeriMake_C1/Desktop/lyj/mnisty/sources/rtl/weights/conv1_weight_2.txt", w_2);
        $readmemh("C:/Users/VeriMake_C1/Desktop/lyj/mnisty/sources/rtl/weights/conv1_weight_3.txt", w_3);
        $readmemh("C:/Users/VeriMake_C1/Desktop/lyj/mnisty/sources/rtl/weights/conv1_bias.txt", bias);
    end

    integer i;
    always @(*) begin
        case(channel_cnt)
            2'b00: begin 
                for(i=0; i<25; i=i+1) begin
                    w_sel[i] <= w_1[i];
                end
                bias_sel = bias[0];
            end
            2'b01: begin 
                for(i=0; i<25; i=i+1) begin
                    w_sel[i] <= w_2[i];
                end
                bias_sel = bias[1];
            end
            2'b10: begin 
                for(i=0; i<25; i=i+1) begin
                    w_sel[i] <= w_3[i];
                end
                bias_sel = bias[2];
            end
        endcase
    end 

    reg[19:0] conv_out;

    always @(*) begin
        conv_out <= buffer[index_x] * w_sel[0] + buffer[index_x+1] * w_sel[1] + buffer[index_x+2] * w_sel[2] + buffer[index_x+3] * w_sel[3] + buffer[index_x+4] * w_sel[4] +
                    buffer[index_x+28] * w_sel[5] + buffer[index_x+29] * w_sel[6] + buffer[index_x+30] * w_sel[7] + buffer[index_x+31] * w_sel[8] + buffer[index_x+32] * w_sel[9] + 
                    buffer[index_x+56] * w_sel[10] + buffer[index_x+57] * w_sel[11] + buffer[index_x+58] * w_sel[12] + buffer[index_x+59] * w_sel[13] + buffer[index_x+60] * w_sel[14] +
                    buffer[index_x+84] * w_sel[15] + buffer[index_x+85] * w_sel[16] + buffer[index_x+86] * w_sel[17] + buffer[index_x+87] * w_sel[18] + buffer[index_x+88] * w_sel[19] + 
                    buffer[index_x+112] * w_sel[20] + buffer[index_x+113] * w_sel[21] + buffer[index_x+114] * w_sel[22] + buffer[index_x+115] * w_sel[23] + buffer[index_x+116] * w_sel[24] + 
                    bias_sel;
        
    end



    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            wen <= 0;
        end else begin
            if(state == FILL && raddr == 140) begin
                wen <= 1;
            end
            if(state == CALC && index_x == 27) begin
                wen <= 1;
            end
            if(state == CALC && index_x == 24) begin
                wen <= 0;
            end
        end
    end

    always @(*) begin
        waddr = index_x + index_y * 24 + channel_cnt * 575;
    end

    assign data_out = conv_out[11:0];

endmodule