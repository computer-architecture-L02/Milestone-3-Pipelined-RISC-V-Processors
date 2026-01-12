module forward_b(
	input  logic [31:0] i_rs2_data_ex,
	input  logic [31:0] i_data_to_wb,
	input  logic [31:0] i_wb_data,
	input  logic [1:0]  i_forward_b,
	output logic [31:0] o_alu_op_b_fwd
);

	always_comb begin
		case (i_forward_b)
			2'b00: o_alu_op_b_fwd = i_rs2_data_ex;
			2'b01: o_alu_op_b_fwd = i_data_to_wb;
			2'b10: o_alu_op_b_fwd = i_wb_data;
			default: o_alu_op_b_fwd = 32'b0;
		endcase
	end
endmodule