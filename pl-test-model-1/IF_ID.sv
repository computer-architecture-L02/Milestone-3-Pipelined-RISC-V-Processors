module IF_ID(
	input  logic        i_clk,
   input  logic        i_reset,
   input  logic        i_stall,   // 1: Stall, 0: giữ nguyên giá trị
	input  logic        i_flush,   // 1: Xóa (chuyển thành NOP)


	// From IF stage
   input  logic [31:0] i_pc,
   input  logic [31:0] i_instr,

   // To ID stage
   output logic [31:0] o_pc,
   output logic [31:0] o_instr,
   output logic        o_insn_vld
);

	always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_pc       <= 32'h0;
            o_instr	  <= 32'h0;
            o_insn_vld <= 1'b0;
        end else if (i_flush) begin
            // Flush: Chuyển thành NOP = ADDI x0, x0, 0 = 0x00000013
            o_instr	  <= 32'h00000013;
				o_pc		  <= 32'b0;
				o_insn_vld <= 1'b0;  // Instruction không hợp lệ
        end else if (i_stall) begin 
				//Stall: Giữ nguyên giá trị cũ
				o_pc	  <= o_pc;
				o_instr <= o_instr;
				o_insn_vld <= o_insn_vld;
		  end else begin
				// Normal: Lưu tín hiệu từ IF stage
            o_pc          <= i_pc;
            o_instr		  <= i_instr;
            o_insn_vld    <= 1'b1;  // Instruction hợp lệ
		  end 
	end 

endmodule 