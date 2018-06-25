`include "mac.v"
`include "fifo.v"

`define MAC_WIDTH 256
`define DATA_SIZE 8

`define PACK_ARRAY( PK_WIDTH, PK_LEN, PK_SRC, PK_DEST) \
genvar pk_idx; \
generate \
	for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) \
		begin \
			assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; \
		end \
endgenerate

`define UNPACK_ARRAY( PK_WIDTH, PK_LEN, PK_SRC, PK_DEST) \
genvar unpk_idx;\
	for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1)\
		begin \
			assign PK_DEST[unpk_idx][(PK_WIDTH-1):0]= PK_SRC[((unpk_idx+1)*PK_WIDTH-1):((unpk_idx)*PK_WIDTH)]; \
		end \
endgenerate


module systolic_matrix(
	clk, //clock input
	weights_in, //Weights input from the weights FIFO
	values_in, //Input the weights
	data_out, //Outputs to the FIFO registers
	instr, //Specify the size of the input matrix, type of operations to be performed
	reset, //reset flag to clear the data
	en, //enable
	values_in_en, //Enable to wrinte the incoming weights into the fifo buffer
	);
//----------------Input Ports--------------------------------
input clk;
input [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] weights_in;
input instr;
input [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] values_in;
input reset;
input en;
input values_in_en;
//---------------Output Ports-------------------------------
output [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] data_out;
//---------------Variables----------------------------------
//Flags in systolic array
reg reset_flag;
wire reset_flag_wire = reset_flag;
//----------------------------------------------------------
//Input and Output of the entire systolic unit in matrix form
reg [(`MAC_WIDTH*`DATA_SIZE-1):0] data_out_matrix [0:(`MAC_WIDTH-1)];
wire [(`MAC_WIDTH*`DATA_SIZE-1):0] weights_in_matrix [0:(`MAC_WIDTH-1)];
wire [(`MAC_WIDTH*`DATA_SIZE-1):0] values_in_matrix [0:(`MAC_WIDTH-1)];
//----------------------------------------------------------

wire instr_mac;

integer count1;
integer count2;

//----------------------------------------------------------
//All the interconnect wires between the seperate mac units are 
//initialised here. Each direction has 2 rows of input for 
//either data communication in a single direction or multi-
//direction.

//Horizontal interconnects have 2 extra rows for data input
wire [(`DATA_SIZE-1):0] mac_horizontal1 [(`MAC_WIDTH-1):0][(`MAC_WIDTH):0]; 
wire [(`DATA_SIZE-1):0] mac_horizontal2 [(`MAC_WIDTH-1):0][(`MAC_WIDTH):0];
//Vertical interconnects have 2 extra columns for data input
wire [(`DATA_SIZE-1):0] mac_vertical1 [(`MAC_WIDTH):0][(`MAC_WIDTH-1):0];
wire [(`DATA_SIZE-1):0] mac_vertical2 [(`MAC_WIDTH):0][(`MAC_WIDTH-1):0];

//----------------------------------------------------------
//Each systolic unit needs to be updated at a different instance.
// This request to update will be sent through the win_request wire.
wire win_request_wire [(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
//The request from the above win_wire_request wire is evaluated in
// the later section of the code and the weight in the matrix is 
// updated through the win_mac wire.
wire win_mac [(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];

//-----------------------------------------------------------
//The inputs to the systolic array during the multiplication is 
// not just a standard row or column of the input matrix but it
// involves a pyramidal input to the MAC units. Similarly during
// convolution, the output of the layer below is pumped
// to the layer above. Hence, a fifo buffer is needed here.

//Variables required for the fifo_west
reg [(`DATA_SIZE-1):0] data_in_fifo_west[(`MAC_WIDTH-1):0];
wire [(`DATA_SIZE-1):0] data_out_fifo_west[(`MAC_WIDTH-1):0];
reg wr_en_fifo_west[(`MAC_WIDTH-1):0];
reg rd_en_fifo_west[(`MAC_WIDTH-1):0];
wire empty_fifo_west[(`MAC_WIDTH-1):0];
wire full_fifo_west[(`MAC_WIDTH-1):0];

//Synchronous fifo for inserting and reading the results from the systolic array
//Variables required for the fifo_east
reg [(`DATA_SIZE-1):0] data_in_fifo_east[(`MAC_WIDTH-1):0];
wire [(`DATA_SIZE-1):0] data_out_fifo_east[(`MAC_WIDTH-1):0];
reg wr_en_fifo_east[(`MAC_WIDTH-1):0];
reg rd_en_fifo_east[(`MAC_WIDTH-1):0];
wire empty_fifo_east[(`MAC_WIDTH-1):0];
wire full_fifo_east[(`MAC_WIDTH-1):0];

//Synchronous fifo for inserting and reading the results from the systolic array
//Variables required for the fifo_north
reg [(`DATA_SIZE-1):0] data_in_fifo_north[(`MAC_WIDTH-1):0];
wire [(`DATA_SIZE-1):0] data_out_fifo_north[(`MAC_WIDTH-1):0];
reg wr_en_fifo_north[(`MAC_WIDTH-1):0];
reg rd_en_fifo_north[(`MAC_WIDTH-1):0];
wire empty_fifo_north[(`MAC_WIDTH-1):0];
wire full_fifo_north[(`MAC_WIDTH-1):0];

//Synchronous fifo for inserting and reading the results from the systolic array
//Variables required for the fifo_south
reg [(`DATA_SIZE-1):0] data_in_fifo_south[(`MAC_WIDTH-1):0];
wire [(`DATA_SIZE-1):0] data_out_fifo_south[(`MAC_WIDTH-1):0];
reg wr_en_fifo_south[(`MAC_WIDTH-1):0];
reg rd_en_fifo_south[(`MAC_WIDTH-1):0];
wire empty_fifo_south[(`MAC_WIDTH-1):0];
wire full_fifo_south[(`MAC_WIDTH-1):0];

//--------------------------------------------------------
//Counters required
integer stop_counter; //Counter to reset all the fifo values
integer counter_west[(`MAC_WIDTH-1):0]; //Counters for initiating the West fifos

//This part seems to have a problem
// //---------------Unpack the inputs to matrices--------------
// `PACK_ARRAY( `DATA_SIZE*`MAC_WIDTH, `MAC_WIDTH, data_out_matrix, data_out);
// `UNPACK_ARRAY(`DATA_SIZE*`MAC_WIDTH, `MAC_WIDTH, values_in, values_in_matrix);
// `UNPACK_ARRAY(`DATA_SIZE*`MAC_WIDTH, `MAC_WIDTH, weights_in, weights_in_matrix);
//----------------Generate matrix of MACs--------------------
//Generate an array of MACs each interconnected with its
//adjacent neighbours 
genvar i;
genvar j;

generate
	for (i=0; i<`MAC_WIDTH; i=i+1)begin
		for (j=0; j<`MAC_WIDTH;j=j+1)begin
			mac_unit unit1(
				.clock(clk),
				.reset(reset_flag_wire),
				.win_request(win_request_wire[i][j]),
				.win(win_mac[i][j]),
				.instr(instr_mac),
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
//--------------------------------------------------------------
//Connections to the fifo buffers
generate
	for (i=0; i<`MAC_WIDTH; i=i+1)begin
		syn_fifo fifo_east(
			.data_in(data_in_fifo_east[i]),
			.data_out(data_out_fifo_east[i]),
			.rd_en(rd_en_fifo_east[i]),
			.wr_en(wr_en_fifo_east[i]),
			.full(full_fifo_east[i]),
			.empty(empty_fifo_east[i]),
			.clk(clk),
			.reset(reset)
			);
		syn_fifo fifo_south(
			.data_in(data_in_fifo_south[i]),
			.data_out(data_out_fifo_south[i]),
			.rd_en(rd_en_fifo_south[i]),
			.wr_en(wr_en_fifo_south[i]),
			.full(full_fifo_south[i]),
			.empty(empty_fifo_south[i]),
			.clk(clk),
			.reset(reset)
			);
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
		syn_fifo fifo_west(
			.data_in(data_in_fifo_west[i]),
			.data_out(data_out_fifo_west[i]),
			.rd_en(rd_en_fifo_west[i]),
			.wr_en(wr_en_fifo_west[i]),
			.full(full_fifo_west[i]),
			.empty(empty_fifo_west[i]),
			.clk(clk),
			.reset(reset)
			);
	end // for (i=0; i<`MAC_WIDTH; i++)
endgenerate

//-----------------------------------------------------
assign instr_mac=instr;

always @(posedge clk or posedge reset) begin : RESET_FLAG
	if(reset) begin
		reset_flag <= 1;
		for (count1=0; count1<`MAC_WIDTH; count1=count1+1)begin
			wr_en_fifo_east[count1]=0;
			wr_en_fifo_west[count1]=0;
			wr_en_fifo_north[count1]=0;
			wr_en_fifo_south[count1]=0;
		end // for (count1=0; count1<`MAC_WIDTH; count++)
	end // if(reset)
	else if (reset_flag==1)begin
		reset_flag<=0;
	end // end else if (reset_flag==1)
end // RESET_FLAG

always @(posedge clk ) begin : STOP_COUNTER 
	if (reset_flag==1) begin
		stop_counter<=0;
	end // if (reset_flag==1):
	else if (stop_counter<`MAC_WIDTH)begin
		stop_counter<=stop_counter+1;
	end // else if (stop_counter<`MAC_WIDTH)
end // STOP_COUNTER

//--------------------------------------------------------------
//Fill the initial fifo in a stepwise fashion
always @(posedge clk) begin : RESET_FIFO
	if ((stop_counter<`MAC_WIDTH) && (instr==1)) begin 
		for (count1=0; count1< `MAC_WIDTH; count1=count1+1) begin 
			if (count1<=stop_counter)begin
				wr_en_fifo_west[count1]<=1;
				data_in_fifo_west[count1]<=values_in_matrix[count1][counter_west[count1]];
			
				if (counter_west[count1]==(`MAC_WIDTH-1))begin
					counter_west[count1]<=0;
				end // if (counter_west[count1]==(`MAC_WIDTH-1))
				else begin
					counter_west[count1]<=counter_west[count1]+1;
				end // else
			end // if (count1<=stop_counter)

			else begin
				wr_en_fifo_west[count1]<=1;
				data_in_fifo_west[count1]<=values_in_matrix[count1][counter_west[count1]];
			end // else
		end // for (count1=1; count1< `MAC_WIDTH; count1++)
	end
end // RESET_FIFOend

//----------------------------------------------------------------
//Continuously update the Fifo values from the matrix
always @(posedge clk or posedge reset) begin 
	if(reset) begin
		reset_flag <= 0;
	end 
	else if((stop_counter==`MAC_WIDTH)&&(instr==1)) begin
		for (count1=0; count1< `MAC_WIDTH; count1=count1+1) begin
			wr_en_fifo_west[count1]<=1;
			data_in_fifo_west[count1]<=values_in_matrix[count1][counter_west[count1]];

			if (counter_west[count1]==(`MAC_WIDTH-1))begin
				counter_west[count1]<=0;
			end // if (counter_west[count1]==(`MAC_WIDTH-1))
			else begin
				counter_west[count1]<=counter_west[count1]+1;
			end // else
		end // for (count1=0; count1< `MAC_WIDTH; count1++)
	end
end // always @(posedge clk or posedge reset)
endmodule // systolic_matrix