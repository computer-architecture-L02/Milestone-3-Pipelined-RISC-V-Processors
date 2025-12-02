module hazard_detection_unit (
    // --- Inputs from ID stage (currently instruction) ---
    input  logic [4:0] i_rs1_addr,
    input  logic [4:0] i_rs2_addr,
    // input logic     i_rs1_used, // (Tuỳ chọn: Nếu muốn tối ưu kỹ hơn)
    // input logic     i_rs2_used, 

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
	 output logic       o_stall_id_ex,  // Stall ID/EX
    output logic       o_flush_if_id,  // Flush IF/ID
    output logic       o_flush_id_ex   // Flush ID/EX
);

    // =================================================================
    // 1. DATA HAZARD DETECTION (NON-FORWARDING)
    // =================================================================
    /* Non-forwarding:
       Nếu EX hoặc MEM của lệnh trước có ghi vào thanh ghi mà ID của lệnh sau cần đọc
       -> STALL toàn bộ để chờ lệnh trước ghi xong (tới WB) rồi mới chạy tiếp lệnh sau.
    */

    logic hazard_ex;
    logic hazard_mem;
    logic data_stall;

    // Check EX Hazard (if 1/2 rs (!0) is similar, and write enable -> hazard!)
    assign hazard_ex = i_rd_wren_ex && |i_rd_addr_ex && ( ~|(i_rd_addr_ex ^ i_rs1_addr) || ~|(i_rd_addr_ex ^ i_rs2_addr) );

    // Check MEM Hazard
    assign hazard_mem = i_rd_wren_mem && |i_rd_addr_mem && ( ~|(i_rd_addr_mem ^ i_rs1_addr) || ~|(i_rd_addr_mem ^ i_rs2_addr) );

    // if any hazard(s) -> stall on
    assign data_stall = hazard_ex | hazard_mem;


    // =================================================================
    // 2. CONTROL HAZARD DETECTION (IF BRANCH TAKEN)
    // =================================================================
    // if branch_taken = 1, instructions in IF & ID is wrong -> Flush
    
    logic branch_flush;
    assign branch_flush = i_branch_taken;


    // =================================================================
    // 3. OUTPUT LOGIC
    // =================================================================
	 
	 // ===== 1. Stall logic ================ 
	 
    // --- PC Control ---
    // Stall PC when Data Hazard occurs (PC remain constant - don't insert new instruction)
    assign o_stall_pc = data_stall;

    // --- IF/ID Register Control ---
    // Stall IF/ID when Data Hazard occurs (keep the current instruction in ID stage)
    assign o_stall_if_id = data_stall;
	 
    // --- ID/EX Register Control ---
	 assign o_stall_id_ex = data_stall;
    
    // ===== 2. Flush logic ================
	 
	 // Flush IF/ID when Branch Taken (to cancel the wrong fetch instructions)
    // if both stall and flush, then flush is favored
    assign o_flush_if_id = branch_flush;
    
	 // --- ID/EX Register Control ---
    // Flush ID/EX in 2 cases:
    // 1. Branch Taken: cancel the instruction in ID (has just decoded but wrong)
    // 2. Data Stall: "install bubbles" (NOP - When Stall, IF/ID is stopped, but ID/EX still running)
    //    phải biến lệnh đang đi vào ID/EX thành NOP để nó không làm gì cả ở các tầng sau.
    assign o_flush_id_ex = branch_flush;

endmodule
