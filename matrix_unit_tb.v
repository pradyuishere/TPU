`include "mac_matrix.v"

`define DATA_SIZE 8
`define MAC_WIDTH 8

module mac_unit_tb ();

reg clock=0;
wire clock_wire = clock;
reg reset;
wire reset_wire = reset;
reg instr;
wire instr_wire=instr;
wire [(`MAC_WIDTH*`MAC_WIDTH*`DATA_SIZE-1):0] weights_data_in;
wire [2*(`MAC_WIDTH*`DATA_SIZE-1):0] values_in1;
wire [2*(`MAC_WIDTH*`DATA_SIZE-1):0] values_in2;
wire [2*(`MAC_WIDTH*`DATA_SIZE-1):0] values_out1;
wire [2*(`MAC_WIDTH*`DATA_SIZE-1):0] values_out2;
wire [(`MAC_WIDTH*`MAC_WIDTH-1):0]weights_request;

integer iter;
integer iter2;

mac_matrix unit1(
	.clock(clock_wire),
	.reset(reset_wire),
	.instr(instr_wire),
	.weights_request(weights_request),
	.weights_data_in(weights_data_in),
	.values_in1(values_in1),
	.values_in2(values_in2),
	.values_out1(values_out1),
	.values_out2(values_out2)
	);
initial begin
	for (iter=0;iter<`MAC_WIDTH;iter=iter+1) begin
		for(iter2=0; iter2<`MAC_WIDTH;iter2=iter2+1) begin
			weights_data_in[(iter*`MAC_WIDTH+iter2)*`DATA_SIZE+:`DATA_SIZE-1]= $urandom_range(255,0);
		end // for(iter2=0; iter2<`MAC_WIDTH;iter2=iter2+1)
		values_in1[iter*`DATA_SIZE+:`DATA_SIZE-1]= $urandom_range(255,0);
	end // for (iter=0;iter<`MAC_WIDTH;iter=iter+1)
end // initial

always @ (posedge clock) begin
	for (iter=0; iter<`MAC_WIDTH;iter=iter+1) begin
		$write("%d ", values_out[iter*`DATA_SIZE: `DATA_SIZE-1]);
	end // for (iter=0; iter<`MAC_WIDTH;iter=iter+1)
	$display(" ");
end // always @ (posedge clock)

always begin
	#0.5 clock=~clock;
end // always


endmodule // mac_unit_tb