module pipelined (
    input  logic        i_clk,
    input  logic        i_reset,
    
    // Outputs for Debugging
    output logic [31:0] o_pc_debug,
    output logic        o_insn_vld,
    output logic        o_ctrl,
    output logic        o_mispred,
    
    // I/O Interface
    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [6:0]  o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
    output logic [6:0]  o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7,
    output logic [31:0] o_io_lcd,
    input  logic [31:0] i_io_sw
);
    
	 //======================================================
	 // 						WIRES 
	 //======================================================
	 
	 // PC & Instructions
	 logic [31:0] next_pc;
	 logic [31:0] pc_if;
	 logic [31:0] pc_id;
	 logic [31:0] pc_ex;
	 logic [31:0] pc_mem;
	 
	 logic [31:0] instr_if;
	 logic [31:0] instr_id;
	 logic [31:0] instr_ex;
	 logic [31:0] instr_mem;
	 
	 // Hazard Decoder Signals
	 logic stall_pc;
	 logic stall_if_id;
	 logic stall_id_ex;
	 logic flush_if_id;
	 logic flush_id_ex;
	 
	 // Control Signals (pha ID)
	 logic 		 ctrl_rd_wren;
	 logic 		 ctrl_mem_wren;
	 logic 		 ctrl_mem_ren;
	 logic [1:0] ctrl_wb_sel;
	 logic 		 ctrl_opa_sel;
	 logic 		 ctrl_opb_sel;
	 logic [3:0] ctrl_alu_op;
	 logic 		 ctrl_br_un;
	 logic 		 ctrl_is_ctrl;
	 
	 // Data Signals
	 
	 // IF
	 logic [31:0] pc_four_if;
	 logic [31:0] pc_next;
	 logic 		  pc_sel;
	 
	 // ID
	 logic [31:0] rs1_data_id;
	 logic [31:0] rs2_data_id;
	 logic 		  insn_vld_id;
	 logic [31:0] ImmExt_id;
	 
	 // EX
	 logic [31:0] rs1_data_ex;
	 logic [31:0] rs2_data_ex;
	 logic [31:0] ImmExt_ex;
	 logic [4:0]  rs1_addr_ex;
	 logic [4:0]  rs2_addr_ex;
	 logic [4:0]  rd_addr_ex;
	 logic 		  rd_wren_ex;
	 logic 		  mem_ren_ex;
	 logic 		  mem_wren_ex;
	 logic [3:0]  alu_op_ex;
	 logic		  opa_sel_ex;
	 logic 		  opb_sel_ex;
	 logic 		  br_un_ex;
	 logic [1:0]  wb_sel_ex;
	 logic 		  insn_vld_ex;
	 logic 		  is_ctrl_ex;
	 logic [31:0] operand_a;
	 logic [31:0] operand_b;
	 logic [31:0] alu_data_ex;
	 logic 		  mispred_ex;
	 
	 // MEM
	 logic [31:0] alu_data_mem;
	 logic [31:0] rs2_data_mem;
	 logic [4:0]  rd_addr_mem;
	 logic 		  rd_wren_mem;
	 logic 		  mem_ren_mem;
	 logic 		  mem_wren_mem;
	 logic [1:0]  wb_sel_mem;
	 logic 		  is_ctrl_mem;
	 logic 		  insn_vld_mem;
	 logic [31:0] ld_data_mem;
	 logic [31:0] io_ledr_mem;
    logic [31:0] io_ledg_mem;
    logic [6:0]  io_hex0_mem, io_hex1_mem, io_hex2_mem, io_hex3_mem;
	logic [6:0]  io_hex4_mem, io_hex5_mem, io_hex6_mem, io_hex7_mem;
    logic [31:0] io_lcd_mem;
	 logic [31:0] pc_four_mem;
	 logic 		  mispred_mem;
	 
	 // WB
	 logic [31:0] wb_data;
    logic [31:0] pc_wb;
    logic [31:0] pc_four_wb;
    logic [31:0] alu_data_wb;
    logic [31:0] ld_data_wb;
    logic [4:0]  rd_addr_wb;
    logic        rd_wren_wb;
    logic [1:0]  wb_sel_wb;
	 
	 // ======================================================
    // 						HAZARD DETECTION INSTANCE
    // ======================================================
    
    hazard_detection_unit u_hazard (
        // Inputs from ID
        .i_rs1_addr     (instr_id[19:15]),
        .i_rs2_addr     (instr_id[24:20]),
        
        // Inputs from EX
        .i_rd_addr_ex   (rd_addr_ex),
        .i_rd_wren_ex   (rd_wren_ex),
        
        // Inputs from MEM
        .i_rd_addr_mem  (rd_addr_mem),
        .i_rd_wren_mem  (rd_wren_mem),
        
        // Input from BRC (Branch Taken)
        .i_branch_taken (pc_sel), //lấy từ brc
        
        // Outputs
        .o_stall_pc     (stall_pc),
        .o_stall_if_id  (stall_if_id),
        .o_stall_id_ex  (stall_id_ex),
        .o_flush_if_id  (flush_if_id),
        .o_flush_id_ex  (flush_id_ex)
    );
	 
	 //======================================================
	 // 						INSTRUCTION FETCH 
	 //======================================================
	 
	 pcplus4 pc_plus_4_if(
		  .i_pc (pc_if),
		  .o_pc_four (pc_four_if)
	 );
	 
	 pcsel pcsel(
		  .i_alu_data   (alu_data_ex),
		  .i_pc_four    (pc_four_if),
		  .i_pc_sel     (pc_sel),
		  .o_pc_next    (pc_next)
	 );
	 
	 imem imem (
        .i_pc    (pc_if),
        .o_instr (instr_if)
    );
	 
	 pc pc(
		  .i_clk 	 (i_clk),
		  .i_reset 	 (i_reset),
		  .i_stall 	 (stall_pc),
		  .i_pc_next (pc_next),
		  .o_pc 		 (pc_if)
	 );
	 
	 // IF/ID Register
	 IF_ID IFID(
		  .i_clk				(i_clk),
		  .i_reset			(i_reset),
		  .i_stall			(stall_if_id),
		  .i_flush			(flush_if_id),
		  .i_pc				(pc_if),
		  .i_instr			(instr_if),
		  
		  .o_pc				(pc_id),
		  .o_instr			(instr_id),
		  .o_insn_vld		(insn_vld_id)
	 );
	 
	 //======================================================
	 // 						INSTRUCTION DECODER 
	 //======================================================
	 
	 regfile register_file (
        .i_clk      (i_clk),
        .i_reset    (i_reset),
        .i_rs1_addr (instr_id[19:15]), // Extract rs1 address
        .i_rs2_addr (instr_id[24:20]), // Extract rs2 address
        .o_rs1_data (rs1_data_id),
        .o_rs2_data (rs2_data_id),
        .i_rd_addr  (rd_addr_wb),  // Extract rd address
        .i_rd_data  (wb_data),
        .i_rd_wren  (rd_wren_wb)
    );
	 
	 control_unit u_control_unit (
			.i_instr			(instr_id),
			.o_rd_wren		(ctrl_rd_wren),    
			.o_br_un			(ctrl_br_un),      
			.o_opa_sel		(ctrl_opa_sel),    
			.o_opb_sel		(ctrl_opb_sel),    
			.o_alu_op		(ctrl_alu_op),     
			.o_mem_wren		(ctrl_mem_wren),  
			.o_mem_ren		(ctrl_mem_ren),
			.o_wb_sel		(ctrl_wb_sel),
			.o_is_ctrl 		(ctrl_is_ctrl)
	);
	
	ImmGen immgen(
			.i_instr			(instr_id),
			.o_ImmExt 		(ImmExt_id)
	);
	
	// ID/EX Register
	ID_EX IDEX(
			 .i_clk			(i_clk),
			 .i_reset		(i_reset),
			 .i_stall		(stall_id_ex),
			 .i_flush		(flush_id_ex),
			 
			 .i_pc			(pc_id),
			 .i_rs1_data	(rs1_data_id),
			 .i_rs2_data	(rs2_data_id),
			 .i_ImmExt		(ImmExt_id),
			 .i_rs1_addr	(instr_id[19:15]),
			 .i_rs2_addr	(instr_id[24:20]),
			 .i_rd_addr		(instr_id[11:7]),
			 .i_instr		(instr_id),
			 
			 .i_rd_wren		(ctrl_rd_wren),
			 .i_mem_ren		(ctrl_mem_ren),
			 .i_mem_wren	(ctrl_mem_wren),
			 .i_alu_op		(ctrl_alu_op),
			 .i_opa_sel		(ctrl_opa_sel),
			 .i_opb_sel		(ctrl_opb_sel),
			 .i_br_un		(ctrl_br_un),
			 .i_wb_sel		(ctrl_wb_sel),
			 .i_insn_vld	(insn_vld_id),
			 .i_ctrl			(ctrl_is_ctrl),
			 
			 // sau dòng này là EX
			 .o_pc			(pc_ex),
			 .o_rs1_data	(rs1_data_ex),
			 .o_rs2_data	(rs2_data_ex),
			 .o_ImmExt		(ImmExt_ex),
			 .o_rs1_addr	(rs1_addr_ex),
			 .o_rs2_addr	(rs2_addr_ex),
			 .o_rd_addr		(rd_addr_ex),
			 .o_rd_wren		(rd_wren_ex),
			 .o_mem_ren		(mem_ren_ex),
			 .o_mem_wren	(mem_wren_ex),
			 .o_alu_op		(alu_op_ex),
			 .o_opa_sel		(opa_sel_ex),
			 .o_opb_sel		(opb_sel_ex),
			 .o_br_un		(br_un_ex),
			 .o_wb_sel		(wb_sel_ex),
			 .o_instr		(instr_ex),
			 .o_insn_vld	(insn_vld_ex),
			 .o_ctrl			(is_ctrl_ex)
	);
	
	 //======================================================
	 // 						EXECUTION 
	 //======================================================
	 
	 opasel opasel(
			  .i_pc				(pc_ex),
			  .i_rs1_data		(rs1_data_ex),
			  .i_opa_sel		(opa_sel_ex),
			  .o_operand_a		(operand_a)
	 );
	 
	 opbsel opbsel(
			  .i_ImmExt			(ImmExt_ex),
			  .i_rs2_data		(rs2_data_ex),
			  .i_opb_sel		(opb_sel_ex),
			  .o_operand_b		(operand_b)
	 );
	 
	 alu alu(
			  .i_op_a 			(operand_a),
			  .i_op_b 			(operand_b),
			  .i_alu_op 		(alu_op_ex),
			  .o_alu_data 		(alu_data_ex)
	 );
	 
	 brc brc(
			  .i_rs1_data	(rs1_data_ex),
			  .i_rs2_data	(rs2_data_ex),
			  .i_br_un		(br_un_ex),
			  .i_instr		(instr_ex),
			  .o_pc_sel		(pc_sel)
	 );
	 
	 assign mispred_ex = pc_sel & is_ctrl_ex;
	 
	 // EX/MEM Register
	 EX_MEM EXMEM(
			 .i_clk			(i_clk),
			 .i_reset		(i_reset),
			 
			 .i_pc			(pc_ex),
			 .i_alu_data	(alu_data_ex),    
			 .i_rs2_data	(rs2_data_ex),    
			 .i_rd_addr		(rd_addr_ex),
			 .i_instr		(instr_ex),       
			 
			 .i_rd_wren		(rd_wren_ex),
			 .i_mem_ren		(mem_ren_ex),
			 .i_mem_wren	(mem_wren_ex),
			 .i_wb_sel		(wb_sel_ex),
			 .i_ctrl			(is_ctrl_ex),        
			 .i_insn_vld	(insn_vld_ex),
			 .i_mispred		(mispred_ex),
			 
			 .o_pc			(pc_mem),
			 .o_alu_data	(alu_data_mem),
			 .o_rs2_data	(rs2_data_mem),
			 .o_rd_addr		(rd_addr_mem),
			 .o_instr		(instr_mem),
			 .o_rd_wren		(rd_wren_mem),
			 .o_mem_ren		(mem_ren_mem),
			 .o_mem_wren	(mem_wren_mem),
			 .o_wb_sel		(wb_sel_mem),
			 .o_ctrl			(is_ctrl_mem),
			 .o_insn_vld	(insn_vld_mem),
			 .o_mispred		(mispred_mem)
	 );
	 
	 
	 //======================================================
	 // 						MEMORY 
	 //======================================================    

    lsu lsu (
        .i_clk      (i_clk),
        .i_reset    (i_reset),
        
        // Memory Interface
        .i_lsu_addr (alu_data_mem),
        .i_st_data  (rs2_data_mem),
        .i_lsu_wren (mem_wren_mem),
        .i_funct3   (instr_mem[14:12]),
		  .i_lsu_ren  (mem_ren_mem)
        .o_ld_data  (ld_data_mem),  	  
        
        // I/O Interface (Nối ra ngoài module pipelined)
        .o_io_ledr  (io_ledr_mem),
        .o_io_ledg  (io_ledg_mem),
        .o_io_hex0  (io_hex0_mem), 
		  .o_io_hex1  (io_hex1_mem),
        .o_io_hex2  (io_hex2_mem), 
		  .o_io_hex3  (io_hex3_mem),
        .o_io_hex4  (io_hex4_mem), 
		  .o_io_hex5  (io_hex5_mem),
        .o_io_hex6  (io_hex6_mem), 
		  .o_io_hex7  (io_hex7_mem),
        .o_io_lcd   (io_lcd_mem),
        .i_io_sw    (i_io_sw)
    );

	 pcplus4 pc_plus_4_mem(
		  .i_pc		 (pc_mem),
		  .o_pc_four (pc_four_mem)
	 );
	 
    // MEM/WB Register
    MEM_WB MEMWB (
        .i_clk          (i_clk),
        .i_reset        (i_reset),
        
        // Data Inputs
        .i_pc           (pc_mem), // PC của lệnh hiện tại (để debug)
        .i_pc_four      (pc_four_mem), // Tính PC+4 tại đây hoặc truyền từ trước
        .i_alu_data     (alu_data_mem),
        .i_ld_data      (ld_data_mem),
        .i_rd_addr      (rd_addr_mem),
        
        // Control Inputs
        .i_rd_wren      (rd_wren_mem),
        .i_wb_sel       (wb_sel_mem),
        .i_ctrl         (is_ctrl_mem),
        .i_insn_vld     (insn_vld_mem),
        .i_mispred      (mispred_mem),
        
        // I/O Inputs (Pass-through for debugging/display consistency if needed)
        .i_io_ledr  (io_ledr_mem),
        .i_io_ledg  (io_ledg_mem),
        .i_io_hex0  (io_hex0_mem), 
		  .i_io_hex1  (io_hex1_mem),
        .i_io_hex2  (io_hex2_mem), 
		  .i_io_hex3  (io_hex3_mem),
        .i_io_hex4  (io_hex4_mem), 
		  .i_io_hex5  (io_hex5_mem),
        .i_io_hex6  (io_hex6_mem), 
		  .i_io_hex7  (io_hex7_mem),
        .i_io_lcd   (io_lcd_mem),
		  
		  .o_io_ledr  (o_io_ledr),
        .o_io_ledg  (o_io_ledg),
        .o_io_hex0  (o_io_hex0), 
		  .o_io_hex1  (o_io_hex1),
        .o_io_hex2  (o_io_hex2), 
		  .o_io_hex3  (o_io_hex3),
        .o_io_hex4  (o_io_hex4), 
		  .o_io_hex5  (o_io_hex5),
        .o_io_hex6  (o_io_hex6), 
		  .o_io_hex7  (o_io_hex7),
        .o_io_lcd   (o_io_lcd),
        
        // Outputs
        .o_pc           (pc_wb),
        .o_pc_four      (pc_four_wb),
        .o_alu_data     (alu_data_wb),
        .o_ld_data      (ld_data_wb),
        .o_rd_addr      (rd_addr_wb),
        .o_rd_wren      (rd_wren_wb),
        .o_wb_sel       (wb_sel_wb),
        
        // Output Debug
        .o_insn_vld     (o_insn_vld),
        .o_ctrl         (o_ctrl),
        .o_mispred      (o_mispred)
    );
    
    assign o_pc_debug = pc_wb; // Output PC Debug lấy từ WB

    // ======================================================
    // 						WRITE BACK
    // ======================================================
    
    wbsel wbsel (
		  .i_pc_four(pc_four_wb),
		  .i_alu_data(alu_data_wb),
		  .i_ld_data(ld_data_wb),
		  .i_wb_sel(wb_sel_wb),
		  .o_wb_data(wb_data)
	 );
	 
endmodule
