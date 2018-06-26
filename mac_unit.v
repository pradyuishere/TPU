
`define DATA_SIZE 8
`define MAC_WIDTH 256

module mac_unit(
	clock,
	reset,
	win,		//Stored weight
	win_request, //Read next value of win
	instr,
	data_south1, //data flowing through south
	data_north1, //data flowing through north
	data_east1,  //data flowing through east
	data_west1,   //data flowing through west
	data_south2, //data flowing through south
	data_north2, //data flowing through north
	data_east2,  //data flowing through east
	data_west2   //data flowing through west
	);
//------------------Inputs-------------------
input clock;
input reset;
input instr;
//------------------Outputs------------------
output win_request;
//------------------Inout--------------------
inout [(`DATA_SIZE-1):0] win;
inout [(`DATA_SIZE-1):0] data_south1;
inout [(`DATA_SIZE-1):0] data_north1;
inout [(`DATA_SIZE-1):0] data_west1;
inout [(`DATA_SIZE-1):0] data_east1;
inout [(`DATA_SIZE-1):0] data_south2;
inout [(`DATA_SIZE-1):0] data_north2;
inout [(`DATA_SIZE-1):0] data_west2;
inout [(`DATA_SIZE-1):0] data_east2;
//------------------Variables------------------
integer counter;
reg [(`DATA_SIZE-1):0] next_win;

endmodule // mac_unit