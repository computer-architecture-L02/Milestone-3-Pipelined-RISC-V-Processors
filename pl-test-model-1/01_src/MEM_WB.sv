module MEM_WB(
    input  logic        i_clk,
    input  logic        i_reset,
    
    // Data from MEM stage
	 input  logic [31:0] i_pc,
    input  logic [31:0] i_pc_four,    // PC+4 (đã tính trong MEM stage)
    input  logic [31:0] i_alu_data,   // Kết quả ALU
    input  logic [4:0]  i_rd_addr,
	 
	 // Data từ ngoại vi 
	 input  logic [31:0] i_io_lcd,
	 output logic [31:0] o_io_lcd,
	 
	 input  logic [31:0] i_io_ledr,
	 output logic [31:0] o_io_ledr,
	 
	 input  logic [31:0] i_io_ledg,
	 output logic [31:0] o_io_ledg,
	 
	 input  logic [6:0] i_io_hex0,
	 input  logic [6:0] i_io_hex1,
	 input  logic [6:0] i_io_hex2,
	 input  logic [6:0] i_io_hex3,
	 input  logic [6:0] i_io_hex4,
	 input  logic [6:0] i_io_hex5,
	 input  logic [6:0] i_io_hex6,
	 input  logic [6:0] i_io_hex7,
	 
	 output logic [6:0] o_io_hex0,
	 output logic [6:0] o_io_hex1,
	 output logic [6:0] o_io_hex2,
	 output logic [6:0] o_io_hex3,
	 output logic [6:0] o_io_hex4,
	 output logic [6:0] o_io_hex5,
	 output logic [6:0] o_io_hex6,
	 output logic [6:0] o_io_hex7,
    
    // Control signals
    input  logic        i_rd_wren,
    input  logic [1:0]  i_wb_sel,
    input  logic        i_ctrl,       // Control transfer instruction
    input  logic        i_insn_vld,
    input  logic        i_mispred,    // Misprediction (từ MEM stage)
    
    // Outputs to WB stage
	 output logic [31:0]	o_pc,
    output logic [31:0] o_pc_four,
    output logic [31:0] o_alu_data,
    output logic [4:0]  o_rd_addr,
    output logic        o_rd_wren,
    output logic [1:0]  o_wb_sel,
    output logic        o_ctrl,
    output logic        o_insn_vld,
    output logic        o_mispred
);

    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
				o_pc			<= 32'b0;
            o_pc_four   <= 32'h0;
            o_alu_data  <= 32'h0;
            o_rd_addr   <= 5'h0;
            o_rd_wren   <= 1'b0;
            o_wb_sel    <= 2'h0;
            o_ctrl      <= 1'b0;
            o_insn_vld  <= 1'b0;
            o_mispred   <= 1'b0;
				
				o_io_ledr	<= 32'b0;
				o_io_ledg	<= 32'b0;
				o_io_lcd		<= 32'b0;
				o_io_hex0	<= 7'b0;
				o_io_hex1	<= 7'b0;
				o_io_hex2	<= 7'b0;
				o_io_hex3	<= 7'b0;
				o_io_hex4	<= 7'b0;
				o_io_hex5	<= 7'b0;
				o_io_hex6	<= 7'b0;
				o_io_hex7	<= 7'b0;
        end else begin
            // WB stage không bao giờ stall/flush
				o_pc			<= i_pc;
            o_pc_four   <= i_pc_four;
            o_alu_data  <= i_alu_data;
            o_rd_addr   <= i_rd_addr;
            o_rd_wren   <= i_rd_wren;
            o_wb_sel    <= i_wb_sel;
            o_ctrl      <= i_ctrl;
            o_insn_vld  <= i_insn_vld;
            o_mispred   <= i_mispred;
				
				o_io_ledr	<= i_io_ledr;
				o_io_ledg	<= i_io_ledg;
				o_io_lcd		<= i_io_lcd;
				o_io_hex0	<= i_io_hex0;
				o_io_hex1	<= i_io_hex1;
				o_io_hex2	<= i_io_hex2;
				o_io_hex3	<= i_io_hex3;
				o_io_hex4	<= i_io_hex4;
				o_io_hex5	<= i_io_hex5;
				o_io_hex6	<= i_io_hex6;
				o_io_hex7	<= i_io_hex7;
        end
    end

endmodule