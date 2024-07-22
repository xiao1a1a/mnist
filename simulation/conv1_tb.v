`timescale  1ns / 1ps

module tb_conv1;

// conv1 Parameters
parameter PERIOD  = 10;


// conv1 Inputs
reg   clk                                  = 0 ;
reg   rst_n                                = 0 ;
reg   upstream_busy                        = 1 ;
wire   [7:0]  data_in                          ;

// conv1 Outputs
wire  [9:0]  raddr                         ;    
wire  ren                                  ;    
wire  [10:0]  waddr                        ;
wire  wen                                  ;
wire  [11:0]  data_out                     ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst_n  =  1;
end

rom_8x784 u_rom(
    .clk        (clk),
    .ren        (ren),
    .addr       (raddr),
    .data_out   (data_in)
);

out_ram u_out_ram(
	.clk     	( clk      ),
	.wen     	( wen      ),
	.addr    	( waddr     ),
	.data_in 	( data_out  )
);


conv1  u_conv1 (
    .clk                     ( clk                   ),
    .rst_n                   ( rst_n                 ),
    .upstream_busy           ( upstream_busy         ),
    .data_in                 ( data_in        [7:0]  ),

    .raddr                   ( raddr          [9:0]  ),
    .ren                     ( ren                   ),
    .waddr                   ( waddr          [10:0] ),
    .wen                     ( wen                   ),
    .data_out                ( data_out       [11:0] )
);

initial
begin
    #20 upstream_busy = 0;
end

endmodule
