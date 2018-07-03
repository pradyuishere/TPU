`include "fifo.v"

`define DATA_SIZE 8
`define MAC_WIDTH 4

module systolic_setup_left_in(
	clock,
	reset,
	matrix_in,
	matrix_in_request,
	matrix_out,
	instr
	);
//Inputs
input clock;
input reset;
input instr;
input [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] matrix_in;

//Outputs
output reg [(`DATA_SIZE*`MAC_WIDTH-1):0] matrix_out;
output reg [`MAC_WIDTH*`MAC_WIDTH-1:0] matrix_in_request;
//###############################################################
//Synfifo connects
reg [`DATA_SIZE-1:0] fifo_in_left [`MAC_WIDTH-1:0];
wire [`DATA_SIZE-1:0] fifo_out_left [`MAC_WIDTH-1:0];
reg rd_en_left [`MAC_WIDTH-1:0];
reg wr_en_left [`MAC_WIDTH-1:0];
wire full_fifo_left [`MAC_WIDTH-1:0];
wire empty_fifo_left [`MAC_WIDTH-1:0];
integer clock_count=0;

genvar i;

generate
	for(i=0;i<`MAC_WIDTH;i=i+1)begin
		syn_fifo fifo_left(
			.data_in(fifo_in_left[i]),
			.wr_en(wr_en_left[i]),
			.rd_en(rd_en_left[i]),
			.data_out(fifo_out_left[i]),
			.full(full_fifo_left[i]),
			.empty(empty_fifo_left[i]),
			.clk(clock),
			.reset(reset)
			);
	end // for(i=0;i<`MAC_WIDTH;i=i+1)
endgenerate
//###############################################################
//Variables
reg reset_flag;
reg ready_flag_left=0;
integer iter;
integer iter2;
integer count;
integer fifo_values_count [`MAC_WIDTH-1:0];

always @(posedge clock or posedge reset) begin
	if (clock_count<15) begin
		//$display("count : %d",count);
		//$display("Value into fifo_in_left : %d, full_fifo_left: %d, reset : %d", fifo_in_left[0], full_fifo_left[0], reset);
		//$display("The current clock is: %d, fifo_out_left: %d",clock_count, fifo_out_left[0]);
	end
	clock_count=clock_count+1;
	if(reset) begin
		reset_flag <= 0;
		count=0;
		$display("I have been reset");
		for (iter=0; iter<`MAC_WIDTH; iter=iter+1) begin
			fifo_values_count[iter]=0;
		end // for (iter=0; iter<`MAC_WIDTH; iter=iter+1)
	end 
	
	else begin
		if (full_fifo_left[0]==1) begin
			ready_flag_left=1;
		end // if (full_fifo_left==1)
		

		if (ready_flag_left==0)begin
			for (iter=0;iter<`MAC_WIDTH;iter=iter+1) begin
				if (iter>count-1) begin
					fifo_in_left[iter]=0;
					//$display("I am assigning zero at iter : %d, count : %d",iter, count);
				end
				else begin
					fifo_in_left[iter] = matrix_in[((fifo_values_count[iter])*`MAC_WIDTH+iter)*`DATA_SIZE+:`DATA_SIZE-1];
					//$display("matrix_in, iter: %d, fifo_values_count[iter] : %d", iter, fifo_values_count[iter]);

				
					for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1) begin
						if (iter2 ==fifo_values_count[iter]) begin
							matrix_in_request[iter2*`MAC_WIDTH+iter]=1;
						end // if (iter2 ==fifo_values_count[iter])
						else begin
							matrix_in_request[iter2*`MAC_WIDTH+iter]=0;
						end // else
					end // for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1)
					
				
					if (fifo_values_count[iter]<`MAC_WIDTH-1) begin
						fifo_values_count[iter]=fifo_values_count[iter]+1;
					end
					else begin
						fifo_values_count[iter]=0;
					end // else
				end
				rd_en_left[iter] =0;
				wr_en_left[iter]=1;
			end
		end // if (full_fifo_left==0)
		else begin
			for (iter=0;iter<`MAC_WIDTH; iter=iter+1) begin
				
				fifo_in_left[iter] = matrix_in[((fifo_values_count[iter])*`MAC_WIDTH+iter)*`DATA_SIZE+:`DATA_SIZE-1];
				// $display("matrix_in : %d", matrix_in[((fifo_values_count[iter])*`MAC_WIDTH+iter)*`DATA_SIZE+:`DATA_SIZE-1]);
				// $display("fifo_in_left : %d", fifo_in_left[iter]);
				
				
				for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1) begin
					if (iter2 ==fifo_values_count[iter]) begin
						matrix_in_request[iter2*`MAC_WIDTH+iter]=1;
					end // if (iter2 ==fifo_values_count[iter])
					else begin
						matrix_in_request[iter2*`MAC_WIDTH+iter]=0;
					end // else
				end // for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1)
				
				
				if (fifo_values_count[iter]<`MAC_WIDTH-1) begin
					fifo_values_count[iter]=fifo_values_count[iter]+1;
				end
				else begin
					fifo_values_count[iter]=0;
				end // else
					rd_en_left[iter]=1;
					wr_en_left[iter]=1;
			
			end // for (iter=0;iter<`MAC_WIDTH; iter=iter+1)

		end // else
	end // else
	count=count+1;
end // always @(posedge clock or posedge reset)
//###############################################################

always @(posedge clock) begin
	for (iter=0; iter<`MAC_WIDTH; iter=iter+1) begin
		matrix_out[iter*`DATA_SIZE+:`DATA_SIZE-1]=fifo_out_left[iter];
		// $display("matrix_out always, fifo_out_left : %d", fifo_out_left[iter]);
	end // for (iter=0; iter<`MAC_WIDTH; iter=iter+1)
end

endmodule // systolic_setup_ins