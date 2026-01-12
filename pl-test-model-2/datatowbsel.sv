module datatowbsel(
	input  logic [31:0] i_pc_four_mem,
	input  logic [31:0] i_alu_data_mem,
	input  logic [1:0] i_wb_sel_mem,
	output logic [31:0] o_data_to_wb
);

	assign o_data_to_wb = (i_wb_sel_mem[1]) ? i_pc_four_mem : i_alu_data_mem;
	
endmodule