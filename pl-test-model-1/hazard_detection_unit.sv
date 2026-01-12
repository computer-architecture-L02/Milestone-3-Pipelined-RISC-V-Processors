module hazard_detection_unit (
    // --- Inputs from ID stage (currently instruction) ---
    input  logic [4:0]  i_rs1_addr,
    input  logic [4:0]  i_rs2_addr,
    input logic  [31:0] i_instr, 

    // --- Inputs from EX stage (previous instruction) ---
    input  logic [4:0] i_rd_addr_ex,
    input  logic       i_rd_wren_ex,
    // input  logic       i_is_load,  // tới Forwarding thì xài
    
    // --- Inputs from MEM stage (previous instruction) ---
    input  logic [4:0] i_rd_addr_mem,
    input  logic       i_rd_wren_mem,

    // --- Input from BRC ---
    input  logic       i_branch_taken,       // = 1 if Branch Taken

    // --- Outputs (for separate Stall/Flush) ---
    output logic       o_stall_pc,     // Stall PC
    output logic       o_stall_if_id,  // Stall IF/ID
    output logic       o_flush_if_id,  // Flush IF/ID
    output logic       o_flush_id_ex   // Flush ID/EX
);

    // =================================================================
    // 1. CHECKING IF RS1 OR RS2 IS USED
    // =================================================================
	 
	 logic [6:0] opcode;
	 logic 		 rs1_used;
	 logic 		 rs2_used;
	 
	 assign opcode = i_instr[6:0];
	 
    always_comb begin
        case (opcode)
            7'b0110011: begin 		//RTYPE
                rs1_used = 1'b1;
                rs2_used = 1'b1;
            end
            7'b0010011: begin 		//ITYPE
                rs1_used = 1'b1;
                rs2_used = 1'b0;
            end
            7'b0000011: begin			//LOAD
                rs1_used = 1'b1;
                rs2_used = 1'b0;
            end
            7'b0100011: begin			//STORE
                rs1_used = 1'b1;
                rs2_used = 1'b1;
            end
            7'b1100011: begin			//BRANCH
                rs1_used = 1'b1;
                rs2_used = 1'b1;
            end
            7'b1100111: begin			//JALR
                rs1_used = 1'b1;
                rs2_used = 1'b0;
            end
            // LUI, AUIPC, JAL
            default: begin 
                rs1_used = 1'b0;
                rs2_used = 1'b0;
            end
        endcase
    end
	 
	 // =================================================================
    // 2. DATA HAZARD DETECTION (NON-FORWARDING)
    // =================================================================
    /* Non-forwarding:
       Nếu EX hoặc MEM của lệnh trước có ghi vào thanh ghi mà ID của lệnh sau cần đọc
       -> stall toàn bộ để chờ lệnh trước ghi xong (tới WB) rồi mới chạy tiếp lệnh sau.
    */

    logic hazard_ex;
    logic hazard_mem;
    logic data_stall;
	 logic rs1_conflict_ex;
	 logic rs2_conflict_ex;
	 logic rs1_conflict_mem;
	 logic rs2_conflict_mem;
	
	 //checking conflict logic
    assign rs1_conflict_ex = rs1_used && ~|(i_rs1_addr ^ i_rd_addr_ex);
    assign rs2_conflict_ex = rs2_used && ~|(i_rs2_addr ^ i_rd_addr_ex);
	 
	 // Check EX Hazard (if 1/2 rs (!0) has conflict, and write enable -> hazard!)
    assign hazard_ex = i_rd_wren_ex && |i_rd_addr_ex && (rs1_conflict_ex || rs2_conflict_ex);

    
	 assign rs1_conflict_mem = rs1_used && ~|(i_rs1_addr ^ i_rd_addr_mem);
    assign rs2_conflict_mem = rs2_used && ~|(i_rs2_addr ^ i_rd_addr_mem);
	 
	 // Check MEM Hazard
    assign hazard_mem = i_rd_wren_mem && |i_rd_addr_mem && (rs1_conflict_mem || rs2_conflict_mem);

    // if any hazard(s) -> stall on
    assign data_stall = hazard_ex | hazard_mem;


    // =================================================================
    // 3. CONTROL HAZARD DETECTION (IF BRANCH TAKEN)
    // =================================================================
    // if branch_taken = 1, instructions in IF & ID is wrong -> Flush
    
    logic branch_flush;
    assign branch_flush = i_branch_taken;


    // =================================================================
    // 3. OUTPUT LOGIC
    // =================================================================

    // --- PC Control ---
    // Stall PC when Data Hazard occurs (PC remain constant - don't insert new instruction)
    assign o_stall_pc = data_stall;

    // --- IF/ID Register Control ---
    // Stall IF/ID when Data Hazard occurs (keep the current instruction in ID stage)
    assign o_stall_if_id = data_stall;
    
    // Flush IF/ID when Branch Taken (to cancel the wrong fetch instructions)
    // if both stall and flush, then flush is favored
    assign o_flush_if_id = branch_flush;

    // --- ID/EX Register Control ---
    // Flush ID/EX in 2 cases:
    // 1. Branch Taken: cancel the instruction in ID (has just decoded but wrong)
    // 2. Data Stall: "install bubbles" (NOP - When Stall, IF/ID is stopped, but ID/EX still running)
    //    phải biến lệnh đang đi vào ID/EX thành NOP để nó không làm gì cả ở các tầng sau.
    assign o_flush_id_ex = branch_flush | data_stall;

endmodule