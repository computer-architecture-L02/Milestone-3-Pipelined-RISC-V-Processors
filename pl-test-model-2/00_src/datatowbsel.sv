module datatowbsel(
	input  logic [31:0] i_pc_four_mem,
	input  logic [31:0] i_alu_data_mem,
	input  logic  		  i_wb_sel_mem1,
	output logic [31:0] o_data_to_wb
);

	assign o_data_to_wb = (i_wb_sel_mem1) ? i_alu_data_mem : i_pc_four_mem;
	
endmodule
