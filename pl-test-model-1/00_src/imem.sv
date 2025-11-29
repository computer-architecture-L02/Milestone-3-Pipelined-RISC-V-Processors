//===================================================================================
// Module: imem (Instruction Memory)
// Description: Synchronous Read-Only Memory for Pipeline Fetch Stage
//===================================================================================

// Cuối module này có 1 MUX để chọn giữa instr và NOP (0x00000013) phòng khi có flush
// Stall thì giữ nguyên i_pc ko đổi

module imem(
    input  logic        i_clk,     	
    input  logic        i_reset,		//cần reset hem
    input  logic [31:0] i_pc,      
    output logic [31:0] o_instr		//nếu đồng bộ thì ngõ ra instr có cần phải qua thanh ghi IF/ID ko, hay nhảy dô control unit luôn
);

    logic [31:0] inst_mem [0:16383]; 
    logic [13:0] pc_word;

    /*initial begin
        $readmemh("./../02_test/isa.mem", inst_mem); 
    end*/

    assign pc_word = i_pc[15:2];

    //========================================================
    // SYNCHRONOUS READ
    //========================================================
	 
    always_ff @(posedge i_clk or negedge i_reset) begin
		 if (!i_reset) begin
				o_instr <= 32'b0;
		 end else begin
				o_instr <= inst_mem[pc_word]; 
		 end
	 end

endmodule
