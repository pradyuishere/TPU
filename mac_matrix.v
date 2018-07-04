`include "mac_unit.v"

`define DATA_SIZE 8
`define MAC_WIDTH 8

module mac_matrix(
	clock,
	reset,
	instr,
	weights_request,
	weights_data_in,
	values_in1,
	values_in2,
	values_out1,
	values_out2
	);
//Inputs##################################################################
input clock;
input reset;
input instr;
input [(`MAC_WIDTH*`MAC_WIDTH*`DATA_SIZE-1):0] weights_data_in;
input [(`MAC_WIDTH*`DATA_SIZE-1):0] values_in1;
input [(`MAC_WIDTH*`DATA_SIZE-1):0] values_in2;
//Outputs#################################################################
output [(`MAC_WIDTH*`MAC_WIDTH-1):0] weights_request;
output [(`MAC_WIDTH*`DATA_SIZE-1):0] values_out1;
output [(`MAC_WIDTH*`DATA_SIZE-1):0] values_out2;
//Variables###############################################################
integer count1;
integer count2;
//Horizontal interconnects have 2 extra rows for data input
wire [(`DATA_SIZE-1):0] mac_horizontal1 [(`MAC_WIDTH-1):0][(`MAC_WIDTH):0]; 
wire [(`DATA_SIZE-1):0] mac_horizontal2 [(`MAC_WIDTH-1):0][(`MAC_WIDTH):0];
//Vertical interconnects have 2 extra columns for data input
wire [(`DATA_SIZE-1):0] mac_vertical1 [(`MAC_WIDTH):0][(`MAC_WIDTH-1):0];
wire [(`DATA_SIZE-1):0] mac_vertical2 [(`MAC_WIDTH):0][(`MAC_WIDTH-1):0];
//Generate a matrix of interconnected MACs
//##########################################################################
genvar i;
genvar j;

generate
	for (i=0; i<`MAC_WIDTH; i=i+1)begin
		for (j=0; j<`MAC_WIDTH;j=j+1)begin
			mac_unit unit1(
				.clock(clock),
				.reset(reset),
				.win_request(weights_request[i*`DATA_SIZE + j]),
				.win(weights_data_in[((i*`DATA_SIZE + j +1)*`DATA_SIZE-1):((i*`DATA_SIZE + j)*`DATA_SIZE)]),
				.instr(instr),
				.data_south1(mac_vertical1[i+1][j]),
				.data_north1(mac_vertical1[i][j]),
				.data_east1(mac_horizontal1[i][j]),
				.data_west1(mac_horizontal1[i][j+1]),
				.data_south2(mac_vertical2[i+1][j]),
				.data_north2(mac_vertical2[i][j]),
				.data_east2(mac_horizontal2[i][j]),
				.data_west2(mac_horizontal2[i][j+1])
			);
		end
	end
endgenerate
//##########################################################################
//Connect the left and the bottom edges of MACs with the values_in and 
// values_out respectedly.

always @ (posedge clock) begin
	for (count1=0; count1<`MAC_WIDTH; count1=count1+1) begin
		mac_vertical1[count1][0] =0;
		mac_vertical2[count1][0] =0;
	end // for (count1=0; count1<`MAC_WIDTH; count1=count1+1)
end // always @ (posedge clock)

generate
	for (i=0; i<`MAC_WIDTH; i= i+1) begin
		assign values_out1[((i+1)*`DATA_SIZE-1):((i)*`DATA_SIZE)] = mac_vertical1[`MAC_WIDTH][i];
		assign values_out2[((i+1)*`DATA_SIZE-1):((i)*`DATA_SIZE)] = mac_vertical2[`MAC_WIDTH][i];
		assign mac_horizontal1[i][0] = values_in1[((i+1)*`DATA_SIZE-1):((i)*`DATA_SIZE)];
		assign mac_horizontal2[i][0] = values_in2[((i+1)*`DATA_SIZE-1):((i)*`DATA_SIZE)];
	end // for (i=0; i<`MAC_WIDTH; i= i+1)1
endgenerate
//##########################################################################
endmodule // mac_matrix