//===================================================================================
// Module: imem (Instruction Memory)
// Description: A wrapper for the generic memory module, configured for read-only
//              instruction fetching. It takes a 32-bit byte address (PC) and
//              outputs the corresponding 32-bit instruction.
//===================================================================================

module imem(
	 input  logic [31:0] i_pc,
    output logic [31:0] o_instr
);
	logic [31:0] inst_mem [0:16383];
	logic [13:0] pc_word;
	
	//initial begin
		//$readmemh("./../02_test/application_ver2.hex", inst_mem); //cả 2 file ok
	//end
	
	assign pc_word = i_pc[15:2];
	
	assign o_instr = inst_mem[pc_word];
endmodule
