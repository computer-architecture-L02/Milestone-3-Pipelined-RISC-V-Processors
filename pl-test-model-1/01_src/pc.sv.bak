module pc(
	input i_clk,
	input i_reset,
	input i_stall,
	
	input  [31:0] i_pc_next,
	output [31:0] o_pc
);

	always_ff @(posedge i_clk or negedge i_reset) begin 
		if (!i_reset) begin
			o_pc <= 32'b0;		
		end else if (!stall) begin 
			o_pc <= i_pc_next;
		end 
	end 


endmodule 