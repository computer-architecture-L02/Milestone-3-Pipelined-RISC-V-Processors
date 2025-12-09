module hazard_forwarding_unit (
    // --- Inputs for Hazard Detection (Load-Use) ---
    // From ID Stage (Current instruction)
    input  logic [4:0]  i_rs1_addr_id,
    input  logic [4:0]  i_rs2_addr_id,
    input  logic [31:0] i_instr_id, // Để check rs1_used, rs2_used
    
    // From EX Stage (Previous instruction - Load checking)
    input  logic        i_mem_ren_ex, // này bật thì lệnh ở EX là load
    input  logic [4:0]  i_rd_addr_ex,

    // --- Inputs for Forwarding Logic ---
    // From EX Stage (current instruction)
    input  logic [4:0]  i_rs1_addr_ex,
    input  logic [4:0]  i_rs2_addr_ex,
    
    // From MEM Stage (Previous instruction)
    input  logic        i_rd_wren_mem,
    input  logic [4:0]  i_rd_addr_mem,
    
    // From WB Stage (Previous previous instruction...)
    input  logic        i_rd_wren_wb,
    input  logic [4:0]  i_rd_addr_wb,

    // --- Input for Control Hazard ---
    input  logic        i_mispredict,

    // --- Outputs ---
    // Hazard Outputs
    output logic        o_stall_pc,
    output logic        o_stall_if_id,
    output logic        o_flush_if_id,
    output logic        o_flush_id_ex,
    
    // Forwarding Outputs
    output logic [1:0]  o_forward_a, // 00: IDEX, 01: MEM, 10: WB
    output logic [1:0]  o_forward_b
);

    // =================================================================
    // 1. LOGIC HAZARD DETECTION (LOAD-USE & BRANCH)
    // =================================================================
    
    // rs1/rs2 used checking
    logic [6:0] opcode;
    logic rs1_used, rs2_used;
    assign opcode = i_instr_id[6:0];

    always_comb begin
        case (opcode)
            7'b0110011: begin rs1_used = 1; rs2_used = 1; end // R-Type
            7'b0010011: begin rs1_used = 1; rs2_used = 0; end // I-Type
            7'b0000011: begin rs1_used = 1; rs2_used = 0; end // Load
            7'b0100011: begin rs1_used = 1; rs2_used = 1; end // Store
            7'b1100011: begin rs1_used = 1; rs2_used = 1; end // Branch
            7'b1100111: begin rs1_used = 1; rs2_used = 0; end // JALR
            default:    begin rs1_used = 0; rs2_used = 0; end // LUI, AUIPC, JAL
        endcase
    end

    // Load Detection
    logic is_load;
    assign is_load = i_mem_ren_ex && |i_rd_addr_ex && 
									  ((rs1_used && ~|(i_rs1_addr_id ^ i_rd_addr_ex)) || 
									  (rs2_used && ~|(i_rs2_addr_id ^ i_rd_addr_ex)));

    // Load -> Stall, Branch -> Flush
    assign o_stall_pc      = is_load;
    assign o_stall_if_id   = is_load;
    assign o_flush_if_id   = i_mispredict;
    assign o_flush_id_ex   = i_mispredict | is_load;

    // =================================================================
    // 2. LOGIC FORWARDING
    // =================================================================
    
    // Forward A Logic
    always_comb begin
        o_forward_a = 2'b00; // Mặc định lấy từ ID/EX

        // lấy mem trc
        if (i_rd_wren_mem && |i_rd_addr_mem && ~|(i_rd_addr_mem ^ i_rs1_addr_ex)) begin
            o_forward_a = 2'b01;
        end
        // hong fw từ mem thì lấy từ WB
        else if (i_rd_wren_wb && |i_rd_addr_wb && ~|(i_rd_addr_wb ^ i_rs1_addr_ex)) begin
            o_forward_a = 2'b10;
        end
    end

    // Forward B Logic
    always_comb begin
        o_forward_b = 2'b00;

        if (i_rd_wren_mem && |i_rd_addr_mem && ~|(i_rd_addr_mem ^ i_rs2_addr_ex)) begin
            o_forward_b = 2'b01;
        end else if (i_rd_wren_wb && |i_rd_addr_wb && ~|(i_rd_addr_wb ^ i_rs2_addr_ex)) begin
            o_forward_b = 2'b10;
        end
    end

endmodule