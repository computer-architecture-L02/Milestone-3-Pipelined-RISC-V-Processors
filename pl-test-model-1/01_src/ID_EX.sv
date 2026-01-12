module ID_EX(
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic        i_flush,
    
    // Data từ ID stage
    input  logic [31:0] i_pc,
    input  logic [31:0] i_rs1_data,
    input  logic [31:0] i_rs2_data,
    input  logic [31:0] i_ImmExt,
    input  logic [4:0]  i_rs1_addr,
    input  logic [4:0]  i_rs2_addr,
    input  logic [4:0]  i_rd_addr,
	 input  logic [31:0] i_instr,
    
    // Control signals từ Control Unit
    input  logic        i_rd_wren,   // Ghi vào rd?   
    input  logic        i_mem_ren,    // Đọc memory? (cho load)
    input  logic        i_mem_wren,   // Ghi memory? (cho store)
    input  logic [3:0]  i_alu_op,      // ALU operation
    input  logic        i_opa_sel,     // ALU operand A 
	 input  logic        i_opb_sel,     // ALU operand B
	 input  logic 			i_br_un,       // 1: signed, 0: unsigned
    input  logic [1:0]  i_wb_sel,      // Write-back data: ALU, MEM, PC+4?
	 input  logic        i_insn_vld,
	 input  logic 			i_ctrl,
    
    // Output tới EX stage
    output logic [31:0] o_pc,
    output logic [31:0] o_rs1_data,
    output logic [31:0] o_rs2_data,
    output logic [31:0] o_ImmExt,
    output logic [4:0]  o_rs1_addr,
    output logic [4:0]  o_rs2_addr,
    output logic [4:0]  o_rd_addr,
    output logic        o_rd_wren,
    output logic        o_mem_ren,
    output logic        o_mem_wren,
    output logic [3:0]  o_alu_op,
    output logic        o_opa_sel,
	 output logic        o_opb_sel,
	 output logic 			o_br_un,
    output logic [1:0]  o_wb_sel,
	 output logic [31:0] o_instr,
	 output logic        o_insn_vld,
	 output logic 			o_ctrl
);

    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_pc        <= 32'h0;
            o_rs1_data  <= 32'h0;
            o_rs2_data  <= 32'h0;
            o_ImmExt    <= 32'h0;
            o_rs1_addr  <= 5'h0;
            o_rs2_addr  <= 5'h0;
            o_rd_addr   <= 5'h0;
            o_rd_wren   <= 1'b0;
            o_mem_ren   <= 1'b0;
            o_mem_wren  <= 1'b0;
            o_alu_op    <= 4'h0;
            o_opa_sel   <= 1'b0;
				o_opb_sel   <= 1'b0;
				o_br_un		<= 1'b1;
            o_wb_sel    <= 2'h0;
            o_insn_vld  <= 1'b0;
				o_instr		<= 32'b0;
				o_ctrl		<= 1'b0;
        end else if (i_flush) begin
            o_pc        <= 32'h0;
            o_rs1_data  <= 32'h0;
            o_rs2_data  <= 32'h0;
            o_ImmExt    <= 32'h0;
            o_rs1_addr  <= 5'h0;
            o_rs2_addr  <= 5'h0;
            o_rd_addr   <= 5'h0;
            o_rd_wren   <= 1'b0;
            o_mem_ren   <= 1'b0;
            o_mem_wren  <= 1'b0;
            o_alu_op    <= 4'h0;
            o_opa_sel   <= 1'b0;
				o_opb_sel   <= 1'b0;
				o_br_un		<= 1'b1;
            o_wb_sel    <= 2'h0;
            o_insn_vld  <= 1'b0;
				o_instr		<= 32'b0;
				o_ctrl		<= 1'b0;
        end else begin
            // Normal: Lưu tất cả tín hiệu
            o_pc        <= i_pc;
            o_rs1_data  <= i_rs1_data;
            o_rs2_data  <= i_rs2_data;
            o_ImmExt    <= i_ImmExt;
            o_rs1_addr  <= i_rs1_addr;
            o_rs2_addr  <= i_rs2_addr;
            o_rd_addr   <= i_rd_addr;
            o_rd_wren   <= i_rd_wren;
            o_mem_ren   <= i_mem_ren;
            o_mem_wren  <= i_mem_wren;
            o_alu_op    <= i_alu_op;
            o_opa_sel   <= i_opa_sel;
				o_opb_sel   <= i_opb_sel;
				o_br_un		<= i_br_un;
            o_wb_sel    <= i_wb_sel;
            o_insn_vld  <= i_insn_vld;
				o_instr		<= i_instr;
				o_ctrl		<= i_ctrl;
        end
    end

endmodule