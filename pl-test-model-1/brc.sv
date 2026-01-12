module brc (
    // Data Inputs
    input  logic [31:0] i_rs1_data,
    input  logic [31:0] i_rs2_data,
    
    // Control Inputs
    input  logic [31:0] i_instr,     // đi từ instruction qua
	 input  logic 			i_br_un,    
    
    // Output
    output logic        o_pc_sel     // 1: Taken (nhảy), 0: Not Taken
);

    //======================================================
	 // --- 1. Equal and Less than Logic ---
	 //======================================================
	 
    logic [31:0] sum;
    logic        c_out;
    logic        overflow;
    logic        signed_less;
    logic        unsigned_less;
    logic        is_equal;
    logic        is_less;
	 logic [6:0]  opcode;
	 logic [2:0]  funct3;
	 
    assign opcode = i_instr[6:0];
	 assign funct3 = i_instr[14:12];
    
    // rs1 - rs2
    adder32 u_subtractor (
        .a      (i_rs1_data),
        .b      (i_rs2_data),
        .c_in   (1'b1),
        .s    	 (sum),
        .c_out  (c_out)
    );
	 
	 // Sign bits
    logic s1_sign, s2_sign, sum_sign;
    assign s1_sign  = i_rs1_data[31];
    assign s2_sign  = i_rs2_data[31];
    assign sum_sign = sum[31];

    // Equal signal
    assign is_equal = ~|sum;

    // Less Than Logic
    assign overflow      = (s1_sign ^ s2_sign) & (s1_sign ^ sum_sign); // Overflow check
    assign signed_less   = sum_sign ^ overflow;                         // Signed Less
    assign unsigned_less = ~c_out;                                      // Unsigned Less (Borrow)
    
		  
    // Choose Less result based on br_un
    assign is_less = i_br_un ? signed_less : unsigned_less;

	 //======================================================
    // --- 2. Branch Decision Logic ---
	 //======================================================
	 
    logic 		 branch_condition_met;
	 logic 		 is_branch;
	 logic 		 is_jump;
	 

    // Branch Decoder (Opcode: 1100011)
    assign is_branch = ~|(opcode ^ 7'b1100011);

    // Jump Decoder
	 // 1. JAL  (Opcode: 1101111)
    // 2. JALR (Opcode: 1100111)
    assign is_jump = ~|(opcode[6:4] ^ 3'b110) & ~|(opcode[2:0] ^ 3'b111);
	 
	 always_comb begin
			case (funct3)
            3'b000:  branch_condition_met = is_equal;          // BEQ
            3'b001:  branch_condition_met = !is_equal;         // BNE
            3'b100:  branch_condition_met = is_less;           // BLT
            3'b101:  branch_condition_met = !is_less;          // BGE
            3'b110:  branch_condition_met = is_less;           // BLTU (is_less lo vụ unsigned ròi)
            3'b111:  branch_condition_met = !is_less;          // BGEU
            default: branch_condition_met = 1'b0;
			endcase
     end
	 
	 //======================================================
    // --- 3. PC Select Logic ---
	 //======================================================
	 
    // pc_sel = 1 when (Branch & met condition) | Jump
    assign o_pc_sel = (is_branch & branch_condition_met) | is_jump;

endmodule