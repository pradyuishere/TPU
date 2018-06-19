`include "fifo.v"
`include "mac.v"


`define MAC_WIDTH 256
`define DATA_SIZE 8
module test1(input clk, input reset);
syn_fifo fifo_north[(`MAC_WIDTH-1):0](.clk(clk), .reset(reset_flag_wire));
//Variables required for the fifo_north
wire [(`DATA_SIZE-1):0] data_in_fifo_north[(`MAC_WIDTH-1):0];
reg [(`DATA_SIZE-1):0] data_out_fifo_north[(`MAC_WIDTH-1):0];
wire wr_en_fifo_north[(`MAC_WIDTH-1):0];
wire rd_en_fifo_north[(`MAC_WIDTH-1):0];
reg empty_fifo_north[(`MAC_WIDTH-1):0];
reg full_fifo_north[(`MAC_WIDTH-1):0];
generate
	for (i=0; i<`MAC_WIDTH; i=i+1)begin
		syn_fifo fifo_north(
			.data_in(data_in_fifo_north[i]),
			.data_out(data_out_fifo_north[i]),
			.rd_en(rd_en_fifo_north[i]),
			.wr_en(wr_en_fifo_north[i]),
			.full(full_fifo_north[i]),
			.empty(empty_fifo_north[i]),
			.clk(clk),
			.reset(reset)
			);
	end // for (i=0; i<`MAC_WIDTH; i++)
endgenerate
endmodule // test