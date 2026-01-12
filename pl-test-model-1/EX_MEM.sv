module EX_MEM(
    input  logic        i_clk,
    input  logic        i_reset,
	 
    // Data from EX stage
    input  logic [31:0] i_pc,
    input  logic [31:0] i_alu_data,   // Kết quả ALU
    input  logic [31:0] i_rs2_data,   // Data để store (SW, SH, SB)
    input  logic [4:0]  i_rd_addr,
    input  logic [31:0] i_instr,      // Instruction (chứa funct3 ở bit [14:12])
    
    // Control signals
    input  logic        i_rd_wren,
	 input  logic 			i_mem_ren,
    input  logic        i_mem_wren,
    input  logic [1:0]  i_wb_sel,
    input  logic        i_ctrl,       // Control transfer instruction
    input  logic        i_insn_vld,
	 input  logic 			i_mispred,
    
    // Outputs to MEM stage
    output logic [31:0] o_pc,
    output logic [31:0] o_alu_data,
    output logic [31:0] o_rs2_data,
    output logic [4:0]  o_rd_addr,
    output logic [31:0] o_instr,
    output logic        o_rd_wren,
	 output logic 			o_mem_ren,
    output logic        o_mem_wren,
    output logic [1:0]  o_wb_sel,
    output logic        o_ctrl,
    output logic        o_insn_vld,
	 output logic 			o_mispred
);

    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_pc        <= 32'h0;
            o_alu_data  <= 32'h0;
            o_rs2_data  <= 32'h0;
            o_rd_addr   <= 5'h0;
            o_instr     <= 32'h0;
            o_rd_wren   <= 1'b0;
				o_mem_ren	<= 1'b0;
            o_mem_wren  <= 1'b0;
            o_wb_sel    <= 2'h0;
            o_ctrl      <= 1'b0;
            o_insn_vld  <= 1'b0;
				o_mispred	<= 1'b0;
        end else begin
            // Normal
            o_pc        <= i_pc;
            o_alu_data  <= i_alu_data;
            o_rs2_data  <= i_rs2_data;
            o_rd_addr   <= i_rd_addr;
            o_instr     <= i_instr;
            o_rd_wren   <= i_rd_wren;
				o_mem_ren	<= i_mem_ren;
            o_mem_wren  <= i_mem_wren;
            o_wb_sel    <= i_wb_sel;
            o_ctrl      <= i_ctrl;
            o_insn_vld  <= i_insn_vld;
				o_mispred	<= i_mispred;			
        end
    end

endmodule