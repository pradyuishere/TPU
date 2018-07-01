`include "fifo.v"

`define DATA_SIZE 8
`define MAC_WIDTH 256

module systolic_setup_in(
	clock,
	reset,
	matrix_in,
	matrix_in_request,
	matrix_out,
	instr
	);

//###############################################################
//Inputs
input clock;
input reset;
input instr;
input [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] matrix_in;
//###############################################################
//Outputs
output [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] matrix_out;
output reg matrix_in_request;
//###############################################################
//Part one: Inititalising the FIFO buffers which transport the 
// input matrix sequentially.
//###############################################################
//Variables
reg [(`DATA_SIZE-1):0] data_in_fifo [(`MAC_WIDTH-1):0];
wire [(`DATA_SIZE-1):0] data_out_fifo [(`MAC_WIDTH-1):0];
reg wr_en_fifo[(`MAC_WIDTH-1):0];
reg rd_en_fifo[(`MAC_WIDTH-1):0];
wire empty_fifo[(`MAC_WIDTH-1):0];
wire full_fifo[(`MAC_WIDTH-1):0];
//###############################################################
//FIFO buffers
genvar i;
genvar j;

generate
	for (i=0; i<`MAC_WIDTH;i=i+1) begin
		syn_fifo fifo_left(
			.data_in(data_in_fifo[i]),
			.data_out(data_out_fifo[i]),
			.rd_en(rd_en_fifo[i]),
			.wr_en(wr_en_fifo[i]),
			.full(full_fifo[i]),
			.empty(empty_fifo[i]),
			.clk(clk),
			.reset(reset)
		);
	end // for (i=0; i<`MAC_WIDTH;i=i+1)
endgenerate

//###############################################################
//End of part 1
//###############################################################
//###############################################################
//Part 2: Initialising the FIFO buffers which borrow the input 
// weights and sequentially distributing them back to the fifo
// buffers initialised in part 1.
//###############################################################
//Variables
wire [(`DATA_SIZE-1):0] data_in_fifo_values [(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
wire [(`DATA_SIZE-1):0] data_out_fifo_values [(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
reg wr_en_fifo_values[(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
reg rd_en_fifo_values[(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
wire empty_fifo_values[(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
wire full_fifo_values[(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
//###############################################################

generate
	for (i=0; i< `MAC_WIDTH; i=i+1) begin
		for (j=0; j< `MAC_WIDTH; j=j+1) begin
			syn_fifo #(8,4)fifo_win(
			.data_in(data_in_fifo_values[i][j]),
			.data_out(data_out_fifo_values[i][j]),
			.rd_en(rd_en_fifo_values[i][j]),
			.wr_en(wr_en_fifo_values[i][j]),
			.full(full_fifo_values[i][j]),
			.empty(empty_fifo_values[i][j]),
			.clk(clk),
			.reset(reset)
				);
		end // for (j=0; j< `MAC_WIDTH; j=j+1)
	end // for (i=0; i< `MAC_WIDTH; i=i+1)
endgenerate
//###############################################################
//End of part 2
//###############################################################
//Part 3: Logic for systolic setup
//###############################################################
//Variables
integer iter;// iters are used for the "for loops"
integer iter1;// iters are used for the "for loops"
integer iter2;// iters are used for the "for loops"
integer count1;//counts are the counters in the system
integer fifo_left_counter [(`MAC_WIDTH-1):0];
//###############################################################
//Startup routine
//_______________________________________________________________
always @(posedge clock or negedge reset) begin
	//Upon reset, all the counters are reset to zero. And only the
	// write to FIFO left buffer is put on High. Everytime a value
	// is read from the FIFO values buffer, put a read eneable 
	// once so that the latest value is refreshed.
	if(~reset) begin
		count1 <= 0;
		for (iter=0; iter< `MAC_WIDTH; iter=iter+1) begin

			for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1) begin
				rd_en_fifo_values[iter][iter2] <= 0;
				wr_en_fifo_values[iter][iter2] <= 0;
			end // for (iter=0; iter< `MAC_WIDTH; iter=iter+1)
			
			rd_en_fifo[iter] <= 0;
			wr_en_fifo[iter] <=1;
		end // for (iter=0; iter< `MAC_WIDTH; iter=iter+1)
	end
	else if (count1<`MAC_WIDTH) begin
		count1 <= count1 + 1;
		for (iter=0; iter< `MAC_WIDTH; iter=iter+1) begin
			//The FIFO buffers are activated in a sequential order
			// giving rise to a pyramidal setup.
			if (iter <=count1) begin 
				//Each FIFO has its own counter and once it
				// owerflows, it is reset back to zero.
				if (fifo_left_counter[iter] <255) begin
					fifo_left_counter[iter] <= fifo_left_counter[iter] + 1;
				end // if (fifo_left_counter[iter] <255)
				else begin
					fifo_left_counter[iter]<=0;
				end // else

				data_in_fifo[iter] <= data_out_fifo_values[fifo_left_counter[iter]][iter];
				//_______________________________________________
				//Once the FIFO buffers are read, they should to be
				// updated with new values. This requires setting
				// rd_en_fifo_values flag to one for a single clock
				// interval.
				for (iter2=0; iter2< `MAC_WIDTH; iter2=iter2+1) begin
					if (iter2==fifo_left_counter[iter]) begin
						rd_en_fifo_values[iter2][iter] <= 1;
					end // if (iter2==fifo_left_counter[iter])
					else begin
						rd_en_fifo_values[iter2][iter] <= 0;
					end // else
				end // for (iter2=0; iter2< `MAC_WIDTH; iter2=iter2+1)
				//_______________________________________________
			end // if (fifo_left_counter[iter] <=count1)
			else begin
				data_in_fifo[iter] <=0;
			end // else
		end // for (iter=0; iter< `MAC_WIDTH; iter=iter+1)
	end
end // always @(posedge clock or negedge reset)
//_______________________________________________________________
//FIFO behaviour during the normal runtime
//_______________________________________________________________
always @(posedge clock or negedge reset) begin 
	if(~reset) begin
		count1 <= 0;
	end // if(~reset)
	else if (count1 >= `MAC_WIDTH) begin
		for (iter=0; iter<`MAC_WIDTH; iter=iter+1) begin
			//Each FIFO has its own counter and once it
			// owerflows, it is reset back to zero.
			//___________________________________________________
			if (fifo_left_counter[iter] <255) begin
				fifo_left_counter[iter] <= fifo_left_counter[iter] + 1;
			end // if (fifo_left_counter[iter] <255)
			else begin
				fifo_left_counter[iter]<=0;
			end // else
			//___________________________________________________
			//Add a value to the FIFO left buffer
			data_in_fifo[iter] <= data_out_fifo_values[fifo_left_counter[iter]][iter];

			//Once a value is read from the FIFO values, send a
			// read request to update the data_out of it.
			//___________________________________________________
			for (iter2=0; iter2< `MAC_WIDTH; iter2=iter2+1) begin
				if (iter2==fifo_left_counter[iter]) begin
					rd_en_fifo_values[iter2][iter] <= 1;
				end // if (iter2==fifo_left_counter[iter])
				else begin
					rd_en_fifo_values[iter2][iter] <= 0;
				end // else
			end // for (iter2=0; iter2< `MAC_WIDTH; iter2=iter2+1)
			//___________________________________________________
		end // for (iter=0; iter<`MAC_WIDTH; iter=iter+1)
	end // end else
end // always @(posedge clock or negedge reset)
//_______________________________________________________________
//Sending a request for a new matrix_in
integer count2;
integer count3;
//_______________________________________________________________

always @(posedge clock or negedge reset) begin 
	if(~reset) begin
		count1 <= 0;
	end
	else begin

		if (matrix_in_request==1) begin
			count3<=count3+1;

			if (count3==2) begin
				for (iter=0; iter<`MAC_WIDTH; iter=iter+1) begin
					for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1) begin
						wr_en_fifo_values[iter][iter2]<=1;
					end // for (iter2=0; iter<`MAC_WIDTH; iter2=iter2+1)
				end // for (iter=0; iter<`MAC_WIDTH; iter=iter+1)
				matrix_in_request<=0;
			end // if (count3==2)

		end // if
		else begin
			count2<=0;
			count3<=0;

			for (iter=0; iter<`MAC_WIDTH; iter=iter+1) begin
				for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1) begin
					wr_en_fifo_values[iter][iter2] <=0;
					if (full_fifo_values[iter][iter2]==1) begin
						count2<=count2+1;
					end // if (full_fifo_values[iter][iter2]==1)
				end // for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1)
			end // for (iter=0; iter<`MAC_WIDTH; iter=iter+1)
			
			if (count2==0) begin
				matrix_in_request <=1;
			end // if (count2==0)

		end // else
	end // else
end

endmodule // systolic_setup_ins