module forward_a(
	input  logic [31:0] i_rs1_data_ex,
	input  logic [31:0] i_data_to_wb,
	input  logic [31:0] i_wb_data,
	input  logic [1:0]  i_forward_a,
	output logic [31:0] o_alu_op_a_fwd
);

	always_comb begin
		case (i_forward_a)
			2'b00: o_alu_op_a_fwd = i_rs1_data_ex;
			2'b01: o_alu_op_a_fwd = i_data_to_wb;
			2'b10: o_alu_op_a_fwd = i_wb_data;
			default: o_alu_op_a_fwd = 32'b0;
		endcase
	end
endmodule