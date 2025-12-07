module wbsel(
	input  logic [31:0] i_data_to_wb,
	input  logic [31:0] i_ld_data,
	input  logic [1:0]  i_wb_sel_wb,
	output logic [31:0] o_wb_data
);

	assign o_wb_data = (i_wb_sel_wb[0]) ? i_ld_data : i_data_to_wb;

endmodule 