//==============================================================================
// Module: control_unit
// Description:
//   RV32I instruction decoder for the pipelined processor (ID stage).
//   It generates control signals for the datapath and tags control-transfer
//   instructions (branch or jump) for later stages.
//==============================================================================

module control_unit (
    // Instruction at ID stage
    input  logic [31:0] i_instr,

    // Datapath / pipeline control

    output logic        o_rd_wren,    // write-back to rd
    output logic        o_mem_wren,   // store to memory
    output logic        o_mem_ren,    // load from memory (is_load)
    output logic [1:0]  o_wb_sel,     // 00: ALU, 01: load, 10: PC+4

    output logic        o_opa_sel,    // 0: rs1, 1: PC
    output logic        o_opb_sel,    // 0: rs2, 1: immediate
    output logic [3:0]  o_alu_op,     // ALU operation
    output logic        o_br_un,      // branch comparison: 1 signed, 0 unsigned

    // Control-transfer classification (for o_ctrl in WB)
    output logic        o_is_ctrl     // branch or jump
);

    //--------------------------------------------------------------------------
    // Field extraction
    //--------------------------------------------------------------------------
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = i_instr[6:0];
    assign funct3 = i_instr[14:12];
    assign funct7 = i_instr[31:25];

    //--------------------------------------------------------------------------
    // Opcode encodings
    //--------------------------------------------------------------------------
    localparam OPC_RTYPE  = 7'b0110011;
    localparam OPC_ITYPE  = 7'b0010011;
    localparam OPC_LOAD   = 7'b0000011;
    localparam OPC_STORE  = 7'b0100011;
    localparam OPC_BRANCH = 7'b1100011;
    localparam OPC_LUI    = 7'b0110111;
    localparam OPC_AUIPC  = 7'b0010111;
    localparam OPC_JAL    = 7'b1101111;
    localparam OPC_JALR   = 7'b1100111;

    //--------------------------------------------------------------------------
    // ALU operation encodings
    //--------------------------------------------------------------------------
    localparam ALU_ADD   = 4'b0000;
    localparam ALU_SUB   = 4'b0001;
    localparam ALU_SLL   = 4'b0010;
    localparam ALU_SLT   = 4'b0011;
    localparam ALU_SLTU  = 4'b0100;
    localparam ALU_XOR   = 4'b0101;
    localparam ALU_SRL   = 4'b0110;
    localparam ALU_SRA   = 4'b0111;
    localparam ALU_OR    = 4'b1000;
    localparam ALU_AND   = 4'b1001;
    localparam ALU_LUI   = 4'b1010;
    localparam ALU_AUIPC = 4'b1011;

    //--------------------------------------------------------------------------
    // Write-back source encodings
    //--------------------------------------------------------------------------
    localparam WB_ALU = 2'b00;
    localparam WB_LD  = 2'b01;
    localparam WB_PC4 = 2'b10;

    //--------------------------------------------------------------------------
    // Internal raw control signals
    //--------------------------------------------------------------------------

    logic       rd_wren_raw;
    logic       mem_wren_raw;
    logic       mem_ren_raw;
    logic [1:0] wb_sel_raw;
    logic       opa_sel_raw;
    logic       opb_sel_raw;
    logic [3:0] alu_op_raw;
    logic       br_un_raw;

    // internal flags for control-transfer classification
    logic       branch_raw;
    logic       jal_raw;
    logic       jalr_raw;

    //--------------------------------------------------------------------------
    // Main decode logic
    //--------------------------------------------------------------------------
    always_comb begin
        // Defaults correspond to a safe NOP

        rd_wren_raw  = 1'b0;
        mem_wren_raw = 1'b0;
        mem_ren_raw  = 1'b0;
        wb_sel_raw   = WB_ALU;

        opa_sel_raw  = 1'b0;
        opb_sel_raw  = 1'b0;
        alu_op_raw   = ALU_ADD;
        br_un_raw    = 1'b1;

        branch_raw   = 1'b0;
        jal_raw      = 1'b0;
        jalr_raw     = 1'b0;

        unique case (opcode)

            //------------------------------------------------------------------
            // R-type ALU operations
            //------------------------------------------------------------------
            OPC_RTYPE: begin
                rd_wren_raw  = 1'b1;
                wb_sel_raw   = WB_ALU;
                opa_sel_raw  = 1'b0;   // rs1
                opb_sel_raw  = 1'b0;   // rs2

                unique case (funct3)
                    3'b000: alu_op_raw = (funct7[5]) ? ALU_SUB : ALU_ADD; 
                    3'b001: alu_op_raw = ALU_SLL;
                    3'b010: alu_op_raw = ALU_SLT;
                    3'b011: alu_op_raw = ALU_SLTU;
                    3'b100: alu_op_raw = ALU_XOR;
                    3'b101: alu_op_raw = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    3'b110: alu_op_raw = ALU_OR;
                    3'b111: alu_op_raw = ALU_AND;
                    default: alu_op_raw = ALU_ADD;
                endcase
            end

            //------------------------------------------------------------------
            // I-type ALU operations
            //------------------------------------------------------------------
            OPC_ITYPE: begin

                rd_wren_raw  = 1'b1;
                wb_sel_raw   = WB_ALU;
                opa_sel_raw  = 1'b0;   // rs1
                opb_sel_raw  = 1'b1;   // immediate

                unique case (funct3)
                    3'b000: alu_op_raw = ALU_ADD;
                    3'b010: alu_op_raw = ALU_SLT;
                    3'b011: alu_op_raw = ALU_SLTU;
                    3'b100: alu_op_raw = ALU_XOR;
                    3'b110: alu_op_raw = ALU_OR;
                    3'b111: alu_op_raw = ALU_AND;
                    3'b001: alu_op_raw = ALU_SLL;
                    3'b101: alu_op_raw = (funct7[5]) ? ALU_SRA : ALU_SRL;  
                    default: alu_op_raw = ALU_ADD;
                endcase
            end

            //------------------------------------------------------------------
            // LOAD: LB, LH, LW, LBU, LHU
            //------------------------------------------------------------------
            OPC_LOAD: begin

                rd_wren_raw  = 1'b1;
                mem_ren_raw  = 1'b1;
                wb_sel_raw   = WB_LD;

                opa_sel_raw  = 1'b0;   // rs1
                opb_sel_raw  = 1'b1;   // immediate
                alu_op_raw   = ALU_ADD;
            end

            //------------------------------------------------------------------
            // STORE: SB, SH, SW
            //------------------------------------------------------------------
            OPC_STORE: begin

                mem_wren_raw = 1'b1;
                opa_sel_raw  = 1'b0;   // rs1 (base)
                opb_sel_raw  = 1'b1;   // immediate
                alu_op_raw   = ALU_ADD;
            end

            //------------------------------------------------------------------
            // BRANCH: BEQ, BNE, BLT, BGE, BLTU, BGEU
            //------------------------------------------------------------------
            OPC_BRANCH: begin
               
                logic is_bltu;
                logic is_bgeu;

                is_bltu = ~|(funct3 ^ 3'b110);
                is_bgeu = ~|(funct3 ^ 3'b111);

                branch_raw   = 1'b1;
                rd_wren_raw  = 1'b0;
                mem_wren_raw = 1'b0;
                mem_ren_raw  = 1'b0;

                // Branch target = PC + immediate
                opa_sel_raw  = 1'b1;   // PC
                opb_sel_raw  = 1'b1;   // immediate
                alu_op_raw   = ALU_ADD;

                // Unsigned comparison used for BLTU and BGEU
                br_un_raw    = ~(is_bltu | is_bgeu);
            end

            //------------------------------------------------------------------
            // LUI: rd = imm << 12
            //------------------------------------------------------------------
            OPC_LUI: begin

                rd_wren_raw  = 1'b1;
                wb_sel_raw   = WB_ALU;

                opa_sel_raw  = 1'b0;
                opb_sel_raw  = 1'b1;
                alu_op_raw   = ALU_LUI;
            end

            //------------------------------------------------------------------
            // AUIPC: rd = PC + imm << 12
            //------------------------------------------------------------------
            OPC_AUIPC: begin

                rd_wren_raw  = 1'b1;
                wb_sel_raw   = WB_ALU;

                opa_sel_raw  = 1'b1;   // PC
                opb_sel_raw  = 1'b1;   // immediate
                alu_op_raw   = ALU_AUIPC;
            end

            //------------------------------------------------------------------
            // JAL: rd = PC+4, PC = PC + immediate
            //------------------------------------------------------------------
            OPC_JAL: begin

                jal_raw      = 1'b1;

                rd_wren_raw  = 1'b1;
                wb_sel_raw   = WB_PC4;

                opa_sel_raw  = 1'b1;   // PC
                opb_sel_raw  = 1'b1;   // immediate
                alu_op_raw   = ALU_ADD;
            end

            //------------------------------------------------------------------
            // JALR: rd = PC+4, PC = rs1 + immediate
            //------------------------------------------------------------------
            OPC_JALR: begin

                jalr_raw     = 1'b1;

                rd_wren_raw  = 1'b1;
                wb_sel_raw   = WB_PC4;

                opa_sel_raw  = 1'b0;   // rs1
                opb_sel_raw  = 1'b1;   // immediate
                alu_op_raw   = ALU_ADD;
            end

            //------------------------------------------------------------------
            // Default: illegal or unsupported opcode
            //------------------------------------------------------------------
            default: begin
                // Keep NOP defaults
            end
        endcase
    end

    //--------------------------------------------------------------------------
    // Output assignments
    //--------------------------------------------------------------------------

    assign o_rd_wren  = rd_wren_raw;
    assign o_mem_wren = mem_wren_raw;
    assign o_mem_ren  = mem_ren_raw;

    assign o_opa_sel  = opa_sel_raw;
    assign o_opb_sel  = opb_sel_raw;
    assign o_alu_op   = alu_op_raw;
    assign o_wb_sel   = wb_sel_raw;

    // For an invalid instruction, default to signed comparison
    assign o_br_un    = br_un_raw;

    // Control-transfer flag (used to build o_ctrl in WB)
    assign o_is_ctrl  = (branch_raw | jal_raw | jalr_raw);

endmodule