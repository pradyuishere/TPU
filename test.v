`include "fifo.v"

`define DATA_SIZE 8
`define MAC_WIDTH 2

module systolic_setup_in();

//###############################################################
//Inputs
reg clock=0;
reg reset;
reg instr;
reg [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] matrix_in;
//###############################################################
//Outputs
reg [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] matrix_out;
reg matrix_in_request;
//###############################################################
//Synfifo connects
reg [`DATA_SIZE-1:0] fifo_in [`MAC_WIDTH-1:0];
wire [`DATA_SIZE-1:0] fifo_out [`MAC_WIDTH-1:0];
reg rd_en [`MAC_WIDTH-1:0];
reg wr_en [`MAC_WIDTH-1:0];
wire full [`MAC_WIDTH-1:0];
wire empty [`MAC_WIDTH-1:0];
integer clock_count=0;

genvar i;

generate
	for(i=0;i<`MAC_WIDTH;i=i+1)begin
		syn_fifo fifo1(
			.data_in(fifo_in[i]),
			.wr_en(wr_en[i]),
			.rd_en(rd_en[i]),
			.data_out(fifo_out[i]),
			.full(full[i]),
			.empty(empty[i]),
			.clk(clock),
			.reset(reset)
			);
	end // for(i=0;i<`MAC_WIDTH;i=i+1)
endgenerate
//###############################################################
//Variables
reg reset_flag;
reg ready_flag=0;
integer iter;
integer iter2;

initial begin
	reset=1;
	#5 reset=0;
end

always @(posedge clock or posedge reset) begin
	$display("Value into fifo_in : %d, full: %d", fifo_in[1], full[1]);
	$display("The current clock is: %d, fifo_out: %d",clock_count, fifo_out[1]);
	clock_count=clock_count+1;
	if(reset) begin
		reset_flag <= 0;
	end else begin
		if (full[0]==1) begin
			ready_flag=1;
		end // if (full==1)
		if (ready_flag==0)begin
			for (iter=0;iter<`MAC_WIDTH;iter=iter+1) begin
				fifo_in[iter] = $urandom_range(255,0);
				rd_en[iter] =0;
				wr_en[iter]=1;
			end
		end // if (full==0)
		else begin
			for (iter=0;iter<`MAC_WIDTH; iter=iter+1) begin
				fifo_in[iter] = $urandom_range(255,0);
				rd_en[iter]=1;
				wr_en[iter]=1;
			end
		end
	end
end

always begin
	#0.5 clock=~clock;
end // always

endmodule // systolic_setup_ins