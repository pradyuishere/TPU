
`define DATA_SIZE 8
`define MAC_WIDTH 8

module mac_unit(
	clock,
	mac_matrix_counter,
	reset,
	win,		//Stored weight
	win_request, //Read next value of win
	instr,
	data_south1_in, //data flowing through south
	data_north1_in, //data flowing through north
	data_east1_in,  //data flowing through east
	data_west1_in,   //data flowing through west
	data_south2_in, //data flowing through south
	data_north2_in, //data flowing through north
	data_east2_in,  //data flowing through east
	data_west2_in,   //data flowing through west
	data_south1_out,
	data_south2_out,
	data_north1_out,
	data_north2_out,
	data_east1_out,
	data_east2_out,
	data_west1_out,
	data_west2_out
	);
//------------------Inputs-------------------
input clock;
input [31:0] mac_matrix_counter;
input reset;
input instr;
input [`DATA_SIZE-1:0] win;
input [2*`DATA_SIZE-1:0] data_south1_in;
input [2*`DATA_SIZE-1:0] data_south2_in;
input [2*`DATA_SIZE-1:0] data_north1_in;
input [2*`DATA_SIZE-1:0] data_north2_in;
input [2*`DATA_SIZE-1:0] data_west1_in;
input [2*`DATA_SIZE-1:0] data_west2_in;
input [2*`DATA_SIZE-1:0] data_east1_in;
input [2*`DATA_SIZE-1:0] data_east2_in;

//------------------Outputs-------------------
output win_request;
output [2*`DATA_SIZE-1:0] data_south1_out;
reg [2*`DATA_SIZE-1:0] data_south1_out_reg;
output [2*`DATA_SIZE-1:0] data_south2_out;
reg [2*`DATA_SIZE-1:0] data_south2_out_reg;
output [2*`DATA_SIZE-1:0] data_north1_out;
reg [2*`DATA_SIZE-1:0] data_north1_out_reg;
output [2*`DATA_SIZE-1:0] data_north2_out;
reg [2*`DATA_SIZE-1:0] data_north2_out_reg;
output [2*`DATA_SIZE-1:0] data_west1_out;
reg [2*`DATA_SIZE-1:0] data_west1_out_reg;
output [2*`DATA_SIZE-1:0] data_west2_out;
reg [2*`DATA_SIZE-1:0] data_west2_out_reg;
output [2*`DATA_SIZE-1:0] data_east1_out;
reg [2*`DATA_SIZE-1:0] data_east1_out_reg;
output [2*`DATA_SIZE-1:0] data_east2_out;
reg [2*`DATA_SIZE-1:0] data_east2_out_reg;

assign data_south1_out=data_south1_out_reg;
assign data_south2_out=data_south2_out_reg;
assign data_north1_out=data_north1_out_reg;
assign data_north2_out=data_north2_out_reg;
assign data_east1_out=data_east1_out_reg;
assign data_east2_out=data_east2_out_reg;
assign data_west1_out=data_west1_out_reg;
assign data_west2_out=data_west2_out_reg;

//------------------Variables-----------------
integer counter;
reg [(`DATA_SIZE-1):0] next_win;

always @ (posedge clock) begin
	$display("value_in : %d, win : %d, data_north1_in : %d", data_west1_in, win, data_north1_in);

	if (instr==0) begin
		data_south1_out_reg <= data_west1_in*win+data_north1_in;
		data_east1_out_reg <=data_west1_in;
	end // if (instr==1)
end // always @ (posedge clock)

endmodule // mac_unit