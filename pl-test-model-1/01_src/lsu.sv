//==============================================================================
// Module: lsu
// Description: Load-Store Unit for Pipelined Processor
//              Synchronous read for memory, asynchronous read for peripherals
//              Memory size: 64 KiB (16K words)
//==============================================================================

module lsu(
    input  logic        i_clk,
    input  logic        i_reset,
    // Memory interface
    input  logic [31:0] i_lsu_addr,
    input  logic [31:0] i_st_data,
    input  logic        i_lsu_wren,
	 input  logic 			i_lsu_ren,
    input  logic [2:0]  i_funct3,
    output logic [31:0] o_ld_data,

    // I/O interface
    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [6:0]  o_io_hex0,
    output logic [6:0]  o_io_hex1,
    output logic [6:0]  o_io_hex2,
    output logic [6:0]  o_io_hex3,
    output logic [6:0]  o_io_hex4,
    output logic [6:0]  o_io_hex5,
    output logic [6:0]  o_io_hex6,
    output logic [6:0]  o_io_hex7,
    output logic [31:0] o_io_lcd,
    input  logic [31:0] i_io_sw
);

    //==========================================
    // Memory array: 16K words x 32-bit = 64KiB
    //==========================================
    logic [31:0] memory [0:16383];
    //==========================================
    // Initialize memory from file
    //==========================================
    initial begin 
        $readmemh("./../02_test/isa_4b.hex", memory);
    end
    
    //==========================================
    // Address extraction
    //==========================================
    logic [13:0] word_addr;
    logic [1:0] byte_offset;
    logic       half_select;  // For half-word: 0=lower, 1=upper
    
    assign word_addr   = i_lsu_addr[15:2];
    assign byte_offset = i_lsu_addr[1:0];
    assign half_select = i_lsu_addr[1];  // Only bit[1] for half-word
    //==========================================
    // Memory read data
    //==========================================
    
	 
    //==========================================
    // I/O registers
    //==========================================
    logic [31:0] reg_ledr;
    logic [31:0] reg_ledg;
    logic [31:0] reg_hex_lo;
    logic [31:0] reg_hex_hi;
    logic [31:0] reg_lcd;
    
    //==========================================
    // Address decoding signals
    //==========================================
    logic sel_mem;
    logic sel_ledr;
    logic sel_ledg;
    logic sel_hex;
    logic sel_lcd;
    logic sel_sw;
  
    //==========================================
    // Address decoder
    //==========================================
    always_comb begin
        sel_mem  = 1'b0;
        sel_ledr = 1'b0;
        sel_ledg = 1'b0;
        sel_hex  = 1'b0;
        sel_lcd  = 1'b0;
        sel_sw   = 1'b0;
		  if (~|(i_lsu_addr[31:16] ^ 16'h1000)) begin
        case (i_lsu_addr[15:12])
		  
            4'h0: sel_ledr = 1'b1;
            4'h1: sel_ledg = 1'b1;
            4'h2,
            4'h3: sel_hex  = 1'b1;
            4'h4: sel_lcd  = 1'b1;
            default: ;
				
        endcase
		  end else if (~|(i_lsu_addr[31:12] ^ 20'h10010)) begin
			  sel_sw = 1'b1;
		  end else if (~|i_lsu_addr[31:16]) begin
			  sel_mem = 1'b1;
		  end
    end
    
    //==========================================
    // Memory read (Synchronous)
    //==========================================
	
	always_ff @(posedge i_clk or negedge i_reset) begin
			if (!i_reset) begin
				o_ld_data <= 32'b0;
			end else if (i_lsu_ren)begin
		 
				if (sel_mem) begin
						case (i_funct3)
								// LB - Load Byte (sign-extended)
								3'b000: begin
									 case (byte_offset)
										  2'b00: o_ld_data <= {{24{memory[word_addr][7]}},  memory[word_addr][7:0]};
										  2'b01: o_ld_data <= {{24{memory[word_addr][15]}}, memory[word_addr][15:8]};
										  2'b10: o_ld_data <= {{24{memory[word_addr][23]}}, memory[word_addr][23:16]};
										  2'b11: o_ld_data <= {{24{memory[word_addr][31]}}, memory[word_addr][31:24]};
									 endcase
								end
								// LH - Load Half-word (sign-extended)
								3'b001: begin
									 case (half_select)
										  1'b0: o_ld_data <= {{16{memory[word_addr][15]}}, memory[word_addr][15:0]};
										  1'b1: o_ld_data <= {{16{memory[word_addr][31]}}, memory[word_addr][31:16]};
									 endcase
								end
								// LW - Load Word
								3'b010: begin
									 o_ld_data <= memory[word_addr];
								end
								// LBU - Load Byte Unsigned
								3'b100: begin
									 case (byte_offset)
										  2'b00: o_ld_data <= {24'b0, memory[word_addr][7:0]};
										  2'b01: o_ld_data <= {24'b0, memory[word_addr][15:8]};
										  2'b10: o_ld_data <= {24'b0, memory[word_addr][23:16]};
										  2'b11: o_ld_data <= {24'b0, memory[word_addr][31:24]};
									 endcase
								end
								// LHU - Load Half-word Unsigned
								3'b101: begin
									 case (half_select)
										  1'b0: o_ld_data <= {16'b0, memory[word_addr][15:0]};
										  1'b1: o_ld_data <= {16'b0, memory[word_addr][31:16]};
									 endcase
								end
								default: begin
									 o_ld_data <= 32'b0;
								end
					   endcase
				
				end else if (sel_ledr) begin
						o_ld_data <= reg_ledr;
				end else if (sel_ledg) begin
						o_ld_data <= reg_ledg;
				end else if (sel_sw) begin
						o_ld_data <= i_io_sw;
				end else if (sel_hex) begin
						o_ld_data <= i_lsu_addr[12] ? reg_hex_hi : reg_hex_lo;
				end else if (sel_lcd) begin 
						o_ld_data <= reg_lcd;
				end else begin
						o_ld_data <= 32'b0;
				end 
		 
			end
		 
		end
	
	
	//==========================================
   // Memory read (Synchronous)
   //==========================================
	always_ff @(posedge i_clk or negedge i_reset) begin
			if (!i_reset) begin
				for (int i=0; i<16384;i++) memory[i] <= 32'b0;
				reg_ledr   <= 32'b0;
            reg_ledg   <= 32'b0;
            reg_hex_lo <= 32'b0;
            reg_hex_hi <= 32'b0;
            reg_lcd    <= 32'b0;
			end else if (i_lsu_wren) begin
				
				if (sel_mem) begin
						case (i_funct3)
								 // SB - Store Byte
								 3'b000: begin
									  case (byte_offset)
											2'b00: memory[word_addr][7:0]   <= i_st_data[7:0];
											2'b01: memory[word_addr][15:8]  <= i_st_data[7:0];
											2'b10: memory[word_addr][23:16] <= i_st_data[7:0];
											2'b11: memory[word_addr][31:24] <= i_st_data[7:0];
									  endcase
								 end
								 // SH - Store Half-word
								 3'b001: begin
									  case (half_select)
											1'b0: memory[word_addr][15:0]  <= i_st_data[15:0];
											1'b1: memory[word_addr][31:16] <= i_st_data[15:0];
									  endcase 
								 end
								 // SW - Store Word
								 3'b010: begin
									  memory[word_addr] <= i_st_data;
								 end
								 default: begin
									  // Do nothing
								 end
						endcase
				end else if (sel_ledr) begin
						reg_ledr <= i_st_data;
				end else if (sel_ledg) begin
						reg_ledg <= i_st_data;
				end else if (sel_hex) begin
						if (i_lsu_addr[12]) begin
                    reg_hex_hi <= i_st_data;
                  end else begin
                    reg_hex_lo <= i_st_data;
                  end
				end else if (sel_lcd) begin
						reg_lcd <= i_st_data;
				end 
				
			end			
				
	end
	

	  
    //==========================================
    // Output assignments
    //==========================================
    assign o_io_ledr = reg_ledr;
    assign o_io_ledg = reg_ledg;
    
    assign o_io_hex0 = reg_hex_lo[6:0];
    assign o_io_hex1 = reg_hex_lo[14:8];
    assign o_io_hex2 = reg_hex_lo[22:16];
    assign o_io_hex3 = reg_hex_lo[30:24];
    assign o_io_hex4 = reg_hex_hi[6:0];
    assign o_io_hex5 = reg_hex_hi[14:8];
    assign o_io_hex6 = reg_hex_hi[22:16];
    assign o_io_hex7 = reg_hex_hi[30:24];

    assign o_io_lcd = reg_lcd;

endmodule
