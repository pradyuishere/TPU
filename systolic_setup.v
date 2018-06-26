
`define DATA_SIZE 8
`define MAC_WIDTH 256

module systolic_setup_in(
	clock,
	reset,
	matrix_in,
	matrix_in_request,
	matrix_out,
	instr
	)

//###############################################################
//Inputs
input clock;
input reset;
input instr;
input [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] matrix_in;
//###############################################################
//Outputs
output [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] matrix_out;
output matrix_in_request;
//###############################################################
//Part one: Inititalising the FIFO buffers which transport the 
// input matrix sequentially.
//###############################################################
//Variables
wire [(`DATA_SIZE-1):0] data_in_fifo [(`MAC_WIDTH-1):0];
wire [(`DATA_SIZE-1):0] data_out_fifo [(`MAC_WIDTH-1):0];
wire wr_en_fifo[(`MAC_WIDTH-1):0];
wire rd_en_fifo[(`MAC_WIDTH-1):0];
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
wire wr_en_fifo_values[(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
wire rd_en_fifo_values[(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
wire empty_fifo_values[(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
wire full_fifo_values[(`MAC_WIDTH-1):0][(`MAC_WIDTH-1):0];
//###############################################################

generate
	for (i=0; i< `MAC_WIDTH; i=i+1) begin
		for (j=0; j< `MAC_WIDTH; j=j+1) begin
			syn_fifo #(8,4)fifo_win(
			.data_in(data_in_fifo_values[i]),
			.data_out(data_out_fifo_values[i]),
			.rd_en(rd_en_fifo_values[i]),
			.wr_en(wr_en_fifo_values[i]),
			.full(full_fifo_values[i]),
			.empty(empty_fifo_values[i]),
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
integer iter2;// iters are used for the "for loops"
integer count1;//counts are the counters in the system
integer fifo_left_counter [(`MAC_WIDTH-1):0];
//###############################################################
//Begin the logic for the pyramidal input for matrix Multiplication
always @(posedge clock or negedge reset) begin
	//Upon reset, all the counters are reset to zero. And only the
	// write to FIFO left buffer is put on High. Everytime a value
	// is read from the FIFO values buffer, put a read eneable 
	// once so that the latest value is refreshed.
	if(~reset) begin
		count1 <= 0;
		for (iter=0; iter< `MAC_WIDTH; iter=iter+1) begin
			fifo_left_counter[iter][`MAC_WIDTH-1:0] <= 0;
			rd_en_fifo_values[iter][`MAC_WIDTH-1:0] <= 0;
			wr_en_fifo_values[iter][`MAC_WIDTH-1:0] <= 0;
			rd_en_fifo[iter] <= 0;
			wr_en_fifo[iter] <=1;
		end // for (iter=0; iter< `MAC_WIDTH; iter=iter+1)
	end
	else begin
		else if (count1<`MAC_WIDTH) begin
			count1 <= count1+1;
		end // else if (count1<`MAC_WIDTH)
		for (iter=0; iter < `MAC_WIDTH; iter=iter+1)begin
			for (iter2 = 0; iter2 < `MAC_WIDTH; iter=iter+1) begin
				if (iter==fifo_left_counter[iter])&&(iter2==iter) begin
					rd_en_fifo_values[iter][iter2] <=1;
				end // if (iter==fifo_left_counter[iter])&&(iter2==iter)
				else begin
					rd_en_fifo_values[iter][iter2] <=0;
				end // else
			end // for (iter2 = 0; iter2 < `MAC_WIDTH; iter=iter+1)
		end // for (iter=0; iter < `MAC_WIDTH; iter=iter+1)
	end
end // always @(posedge clock or negedge reset)
//################################################################

always @(posedge clock or negedge reset) begin
	if(~reset) begin
		count1 <= 0;
	end 
	else if (count1<`MAC_WIDTH) begin
		for (iter=0; iter< `MAC_WIDTH; iter=iter+1) begin
			if (iter <=count1) begin 
				if (fifo_left_counter[iter] <255) begin
					fifo_left_counter[iter] <= fifo_left_counter[iter] + 1;
				end // if (fifo_left_counter[iter] <255)
				else begin
					fifo_left_counter[iter]=0;
				end // else

				data_in_fifo[iter] <= data_out_fifo_values[fifo_left_counter[iter]][iter];
				rd_en_fifo_values[fifo_left_counter[iter]][iter]=1;
				
			end // if (fifo_left_counter[iter] <=count1)
			else begin
				data_in_fifo[iter] <=0;
			end // else
		end // for (iter=0; iter< `MAC_WIDTH; iter=iter+1)
	end
end // always @(posedge clock or negedge reset)

endmodule // systolic_setup_in