`include "systolic_setup.v"

`define DATA_SIZE 8
`define MAC_WIDTH 8

module systolic_setup_left_in_tb();

//Inputs
reg clock=0;
wire clock_wire = clock;
reg reset;
wire reset_wire = reset;
reg instr;
wire instr_wire=instr;
reg [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] matrix_in;
wire [(`DATA_SIZE*`MAC_WIDTH*`MAC_WIDTH-1):0] matrix_in_wire = matrix_in;
//###############################################################
//Outputs
wire [(`DATA_SIZE*`MAC_WIDTH-1):0] matrix_out;
wire [`MAC_WIDTH*`MAC_WIDTH-1:0] matrix_in_request;
//###############################################################

systolic_setup_left_in unit1 (
	.clock(clock_wire),
	.reset(reset_wire),
	.matrix_in(matrix_in_wire),
	.matrix_in_request(matrix_in_request),
	.matrix_out(matrix_out),
	.instr(instr_wire)
	);

//###############################################################

//Variables
integer iter;
integer iter2;
integer clock_count=0;

initial begin


	for(iter=0; iter<`MAC_WIDTH; iter=iter+1) begin
		for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1) begin
			matrix_in[(iter2*`MAC_WIDTH+iter)*`DATA_SIZE+:`DATA_SIZE]= $urandom_range(255,0);
		end // for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1)
	end // for(iter=0; iter<`MAC_WIDTH; iter=iter+1)

	reset=1;
	#5 reset=0;
	
	for(iter=0; iter<`MAC_WIDTH; iter=iter+1) begin
		for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1) begin
			$write("%d ",matrix_in[(iter2*`MAC_WIDTH+iter)*`DATA_SIZE+:`DATA_SIZE]);
		end // for (iter2=0; iter2<`MAC_WIDTH; iter2=iter2+1)
		$display(" ");
	end
	$display(" ");
	$display(" ");

end

always @ (posedge clock) begin
	if (clock_count<20) begin
		//$display("clock_count : %d, reset : %d",clock_count, reset);
		for (iter=0; iter<`MAC_WIDTH; iter=iter+1) begin 
			$write("%d ", matrix_out[iter*`DATA_SIZE+:`DATA_SIZE]);
		end
		$display(" ");
	end
	clock_count=clock_count+1;
end // always @ (posedge clock)

always begin
	#0.5 clock=~clock;
end // always

//###############################################################

endmodule // systolic_setup_ins