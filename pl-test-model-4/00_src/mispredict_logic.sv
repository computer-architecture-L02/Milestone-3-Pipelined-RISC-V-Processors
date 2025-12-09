module mispredict_logic(
		input  logic 		  i_is_ctrl_ex,
		input  logic 		  i_pc_sel,
		input  logic 		  i_pred_taken_ex,
		input  logic [31:0] i_alu_data_ex,
		input  logic [31:0] i_pc_ex,
		
		output logic [31:0] o_correct_pc,
		output logic 		  o_mispred_ex
);


	logic 		 mispredict;
	logic [31:0] pc_ex_four;
	assign mispredict = i_is_ctrl_ex & |(i_pc_sel ^ i_pred_taken_ex);
	
	pcplus4 pc_ex_4(
		.i_pc			(i_pc_ex),
		.o_pc_four	(pc_ex_four)
	);
    // [MỚI] Tính Correct PC để sửa sai
    always_comb begin
        // Nếu thực tế là Nhảy (Taken) -> PC đúng phải là Target Address (tính bởi ALU)
        // Nếu thực tế là Không Nhảy (Not Taken) -> PC đúng là PC_EX + 4
        if (i_pc_sel) 
            o_correct_pc = i_alu_data_ex;
        else        
            o_correct_pc = pc_ex_four;
    end

    // Gán tín hiệu này vào dây mispred_ex để đưa xuống MEM/WB (cho debug/thống kê)
    assign o_mispred_ex = mispredict;
	 
endmodule