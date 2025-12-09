module branch_predictor #(
    parameter ENTRIES = 64, // Số lượng entry trong bảng (Power of 2)
    parameter INDEX_BITS = 6 // log2(ENTRIES)
)(
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic        i_stall, // Nếu Stall PC thì không update dự đoán mới

    // --- Port 1: FETCH STAGE (Dự đoán) ---
    input  logic [31:0] i_pc_if,        // PC hiện tại đang Fetch
    output logic [31:0] o_next_pc_pred, // PC dự đoán tiếp theo
    output logic        o_pred_taken,   // 1: Dự đoán nhảy, 0: Không nhảy

    // --- Port 2: EX STAGE (Update/Training) ---
    // Các tín hiệu này dùng để "học" từ kết quả thực tế
    input  logic [31:0] i_pc_ex,        // PC của lệnh đang ở EX
    input  logic        i_is_ctrl_ex,   // Có phải lệnh Branch/Jump không?
    input  logic        i_actual_taken, // Kết quả thực tế (từ BRC/Jump logic)
    input  logic [31:0] i_target_addr   // Địa chỉ đích thực tế (tính bởi ALU/Adder)
);

    // Bảng lưu trữ
    logic [1:0]  bht [ENTRIES-1:0];      // 2-bit state
    logic [31:0] btb [ENTRIES-1:0];      // Branch Target Buffer
    logic [31:0] tag [ENTRIES-1:0];      // Tag để xác định PC (Optional for simple direct-map)
    // Lưu ý: Để đơn giản cho sinh viên, thường dùng Direct-mapped dựa trên bits của PC

    // Trích xuất index từ PC
    logic [INDEX_BITS-1:0] idx_if;
    logic [INDEX_BITS-1:0] idx_ex;

    assign idx_if = i_pc_if[INDEX_BITS+1 : 2]; // Bỏ 2 bit cuối (vì PC % 4 == 0)
    assign idx_ex = i_pc_ex[INDEX_BITS+1 : 2];
	 
	 // =========================================================
    // 1. LOGIC DỰ ĐOÁN (FETCH STAGE)
    // =========================================================
    // Kiểm tra xem PC hiện tại có trong BTB không và trạng thái là gì
    // Ở mức đơn giản: Chỉ cần so sánh Tag (hoặc mặc định hit nếu dùng bảng nhỏ)
    logic hit;
    assign hit = ~|(tag[idx_if] ^ i_pc_if); 

	 logic [31:0] pc_4_pred;
	 pcplus4 next_pc_pred(
				.i_pc      (i_pc_if),
				.o_pc_four (pc_4_pred)
		  );
	 
    always_comb begin
        o_next_pc_pred = pc_4_pred;
        o_pred_taken   = 1'b0;

        if (hit) begin
            // Nếu state >= 2'b10 (Weakly Taken hoặc Strongly Taken) -> Dự đoán Nhảy
            if (~|(bht[idx_if] ^ 2'b10) | ~|(bht[idx_if] ^ 2'b11)) begin
                o_next_pc_pred = btb[idx_if];
                o_pred_taken   = 1'b1;
            end
        end
    end

    // =========================================================
    // 2. LOGIC CẬP NHẬT (EX STAGE - Sequential)
    // =========================================================
    // Định nghĩa các trạng thái cho dễ đọc
    localparam SNT = 2'b00; // Strongly Not Taken
    localparam WNT = 2'b01; // Weakly Not Taken
    localparam WT  = 2'b10; // Weakly Taken
    localparam ST  = 2'b11; // Strongly Taken

    always_ff @(posedge i_clk or negedge i_reset) begin 
        if (!i_reset) begin
		  for (int i = 0; i < ENTRIES; i++) begin
                bht[i] <= 2'b01; // Weakly Not Taken
                btb[i] <= 32'b0;
                tag[i] <= 32'hFFFFFFFF; 
            end
		  end else begin 
			  if (i_is_ctrl_ex && !i_stall) begin
					
					// Update Tag và Target
					tag[idx_ex] <= i_pc_ex;
					btb[idx_ex] <= i_target_addr;

					// Update 2-bit FSM (Thay thế phép cộng/trừ)
					// Logic bão hòa (Saturation) được viết tường minh
					case (bht[idx_ex])
						 SNT: begin // 00
							  if (i_actual_taken) bht[idx_ex] <= WNT; // Nhảy -> 01
							  else                bht[idx_ex] <= SNT; // Ko nhảy -> Giữ 00
						 end
						 
						 WNT: begin // 01
							  if (i_actual_taken) bht[idx_ex] <= WT;  // Nhảy -> 10
							  else                bht[idx_ex] <= SNT; // Ko nhảy -> 00
						 end

						 WT: begin // 10
							  if (i_actual_taken) bht[idx_ex] <= ST;  // Nhảy -> 11
							  else                bht[idx_ex] <= WNT; // Ko nhảy -> 01
						 end

						 ST: begin // 11
							  if (i_actual_taken) bht[idx_ex] <= ST;  // Nhảy -> Giữ 11
							  else                bht[idx_ex] <= WT;  // Ko nhảy -> 10
						 end
					endcase
			  end
			end
    end

endmodule
	 /*/ =========================================================
    // 2. LOGIC CẬP NHẬT (EX STAGE - Sequential)
    // =========================================================
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            for (int i = 0; i < ENTRIES; i++) begin
                bht[i] <= 2'b01; // Init: Weakly Not Taken
                btb[i] <= 32'b0;
                tag[i] <= 32'hFFFFFFFF; 
            end
        end else begin
            // FIX: Thêm điều kiện && !i_stall
            // Chỉ update khi có lệnh điều khiển VÀ pipeline không bị treo
            if (i_is_ctrl_ex && !i_stall) begin
                
                // Update Tag và Target
                tag[idx_ex] <= i_pc_ex;
                btb[idx_ex] <= i_target_addr;

                // Update 2-bit Counter
                if (i_actual_taken) begin
                    if (bht[idx_ex] != 2'b11)
                        bht[idx_ex] <= bht[idx_ex] + 1'b1;
                end else begin
                    if (bht[idx_ex] != 2'b00) 
                        bht[idx_ex] <= bht[idx_ex] - 1'b1;
                end
            end
        end
    end

endmodule*/