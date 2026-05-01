module Processor
	(
		input clk,
		input rst,
		input [4:0] switches,
		output [9:0] LED
	
	);
	
	
	
	reg [ 9:0] PC;
	reg [9:0] address;		// SIZE OF THIS BUS MAY CHANGE IF I CHANGE MEMORY CAPACITY	- UPDATE SYMBOL FILE FOR MEMORY.V TO DOUBLE CHECK
	reg [31:0] data_in;
	reg wren;
	wire [31:0] data_out;
	
	reg [31:0] stored_instr;
	
	
	/*		EXTENDED IMMEDIETE VALUES		*/
	wire [31:0] i_imm = { {20{stored_instr[31]}}, stored_instr[31:20] };
	wire [31:0] s_imm = { {20{stored_instr[31]}}, stored_instr[31:25], stored_instr[11:7] };
	wire [31:0] b_imm = { {19{stored_instr[31]}}, stored_instr[31], stored_instr[7], stored_instr[30:25], stored_instr[11:8] };
	wire [31:0] u_imm = { stored_instr[31:12], 12'b0 };
	wire [31:0] j_imm = { {12{stored_instr[31]}}, stored_instr[19:12], stored_instr[20], stored_instr[30:25], stored_instr[24:21], 1'b0 };

	
	
//	-	-	-	-	-	-	-	-	-	 MEMORY INSTANTIATION	-	-	-	-	-	-	-	-	-	
	Memory	Memory_inst (
		.address ( address ),
		.clock ( clk ),
		.data ( data_in ),
		.wren ( wren ),
		.q ( data_out )
		);
		

		/*
			NOTES: 2 CYCLE MEMORY ACCESS
						THIS IS **NOT** BYTE ACCESSABLE MEMORY
						EACH ADDRESS ACCESSES AN 32 BIT WORD
		*/

		//		why cant I make a 1 cycle access ROM for instructions and a 2 cycle access RAM for data?
		
	/* HOW I MADE THE MEMORY IN QUARTUS
			1. MADE A NEW MEMORY INITIALIZATION FILE (.mif)		note- I think it would work the same with a Hexidecimal file (.hex)
			2. Under IP CATALOG TO SEARCH FOR RAM (RAM: 1-PORT)
				1a.	SET WORD SIZE TO 32 BITS -> CORRESPONDS WITH INSTRUCTION SIZE IN TINY RISC-V
			3. USED MEGA WIZARD TO SET UP MEMORY
				3a. 'q' = 32 because each instruction is 32 bits
				3b.	1052 32 BIT WORDS			 **MATCHES THE .MIF FILE** 
				3c.	REGISTER 'q' OUTPUT PORT		** MEMORY ACCESS IS 2 CYCLE ** (a little confused why registering 'q' is worth the extra cyccle)
				3d.	SWITCHED q OUTPUT TO Don't Care WHEN MEMORY IS BEING WRITEN TO
				3e.	INITIALIZE CONTENT OF THE MEMORY TO Memory.mif
				*/
				
				
//	-	-	-	-	-	-	-	-	-	 REGISTER FILE INSTANTIATION	-	-	-	-	-	-	-	-	-	

	/*
		input clk,
		input rst,
		input wren,
		input [4:0] write_reg,		//	ADDRESS OF REGISTER TO BE WRITTEN TO
		input [ 31:0] write_data,
		input [4:0] read_reg_1,		//	ADDRESS OF REGISTER TO BE READ FROM
		input [4:0] read_reg_2,
		output [ 31:0] read_data_1,		//	THE DATA IN REGISTER AT ADDR READ_REG_1
		output [ 31:0] read_data_2;
		*/
		
	
	reg reg_wren;
	reg [4:0] write_reg;
	reg [31:0] write_data;
	reg [4:0] read_reg_1, read_reg_2;
	wire [31:0] read_data_1, read_data_2;
	
	Registers registers (
		.clk ( clk ),
		.rst ( rst ),
		.wren ( reg_wren ),
		.write_reg ( write_reg ),
		.write_data ( write_data ),
		.read_reg_1 ( read_reg_1 ),
		.read_reg_2 ( read_reg_2 ),
		.read_data_1 ( read_data_1 ),
		.read_data_2 ( read_data_2 ),
		.LEDout (LED),
		.switches (switches )
		);
		

		
//	-	-	-	-	-	-	-	-	-	 ALU INSTANTIATION	-	-	-	-	-	-	-	-	-	

	reg [ 3:0] aluControl;
	wire [31:0] aluOut;
	reg [31:0] aluIn1, aluIn2;
	ALU myALU (
		.rs1( aluIn1 ),		//register input to alu
		.rs2(	aluIn2 ),						//this could be a register or an immediete
		.aluControl( aluControl ),
		.out(aluOut)
	);
	
			/*		CONTROL SIGNALS	*/
						
	parameter
							ADD	=	4'd0,
							SUB	=	4'd1,
							AND	=	4'd2,
							OR	=	4'd3,
							XOR	=	4'd4,
							SLT	=	4'd5,
							SLTU	=	4'd6,
							SRA	=	4'd7,
							SRL	=	4'd8,
							SLL	=	4'd9,
							MUL	=	4'd10;


				/*		OPCODE DEFINITIONS		*/
	parameter
					
		/*		Control/Status Register Instructions		(CSRR, CSRW)		*/
		//NOTE: IGNORE THESE 2 INSTRUCTIONS FOR THIS EXCERCISE!
					CSR_INS	= 7'b1110011,
					
		/*		Register-Register Arithmetic Instructions
			(ADD, SUB, AND, OR, XOR, SLT, SLTU, SRA, SRL, SLL, MUL)		*/
		
					REG_REG	= 7'b0110011,
					
		/*		Register-Immediate Arithmetic Instructions
			(ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SRAI, SRLI, SLLI)		*/
					
					REG_IMM	= 7'b0010011,
					LUI		= 7'b0110111,
					AUIPC		= 7'b0010111,

		/*		Memory Instructions		*/
					
					LOAD			= 7'b0000011,
					STORE			= 7'b0100011,

		/*		Unconditional Jump Instructions		*/
					
					JAL		= 7'b1101111,
					JR			= 7'b1100111,		//	(JR, JALR)
					
		/*		Conditional Branch Instructions
			(BEQ, BNE, BLT, BGE, BLTU, BGEU)		*/
			
					BRANCH      = 7'b1100011;
					



//	-	-	-	-	-	-	-	-	-	 FINITE STATE MACHINE (FSM)	-	-	-	-	-	-	-	-	-	
				
	reg [ 2:0 ] S;		//	CURRENT STATE
	reg [ 2:0 ] NS;		//	NEXT STATE
	
	parameter
					START	=	3'd0,
					FETCH	=	3'd1,
					FETCH_2	=	3'd2,			//2 CYCLE MEMORY ACCESS
					DECODE	=	3'd3,
					EXECUTE	=	3'd4,			//DOES NOT NEED EXTRA STATE BC NEXT STATE DOES NOT READ MEM
					WRITE_BACK	=	3'd5,
					
					STOP	=	3'd6;

					
					
	/*		THIS BLOCK UPDATES THE FSM EACH CLOCK CYCLE	*/		
	always@(posedge clk or negedge rst)
		if(rst==1'b0)
			S<=START;
		else
			S<=NS;
			
	/*		THIS BLOCK ASIGNS THE NEXT STATE		*/
	always@(*)
		case(S)
			START:	NS = FETCH;
			FETCH:	NS	= FETCH_2;
			FETCH_2:	NS = DECODE;
			DECODE:	begin
                        if (data_out == 32'd0) 
                            NS = STOP;       // If instruction is 0, go to STOP
                        else 
                            NS = EXECUTE;    // Otherwise, continue as normal
                    end
			EXECUTE:	NS = WRITE_BACK;
			WRITE_BACK:	NS = FETCH;
			
			STOP: NS = STOP;
			default: NS = STOP;
			
		
		endcase
		
		
		
		
			
		
		
		/*		THIS BLOCK CHANGES SIGNALS BASED ON THE STATE		*/
		always@(posedge clk or negedge rst)
		
			if(rst == 1'b0)			//RESET BUTTON IS RESTING HIGH
				begin
					address <= 10'd0;		// SIZE OF THIS BUS MAY CHANGE IF I CHANGE MEMORY CAPACITY	- UPDATE SYMBOL FILE FOR MEMORY.V TO DOUBLE CHECK
					data_in <= 32'd0;
					wren <= 1'b0;
					PC <= 10'd0;
					reg_wren <= 1'b0;
					write_reg <= 5'd0;
					write_data <= 32'd0;
					read_reg_1 <= 5'd0;
					read_reg_2 <= 5'd0;
					aluControl <= 4'd0;
					aluIn1 <= 32'd0;
					aluIn2 <= 32'd0;
					
				end
			else
			
		begin
		
		wren <= 1'b0;
		reg_wren <= 1'b0;
					
			case(S)
			
				START:
					begin
						address <= 10'd0;		// SIZE OF THIS BUS MAY CHANGE IF I CHANGE MEMORY CAPACITY	- UPDATE SYMBOL FILE FOR MEMORY.V TO DOUBLE CHECK
						data_in <= 32'd0;
						wren <= 1'b0;
						reg_wren	<= 1'b0;
					end
					
				FETCH:
					begin
						address <= PC;
						wren <= 1'b0;
						reg_wren <= 1'b0;
					end
					
				FETCH_2:
					begin
							//EMPTY STATE WAITING FOR q (DATA_OUT)
					end
					
				DECODE:
					begin
						/*		UPDATE CONTROL SIGNALS BASED ON INSTRUCTION		*/	
						stored_instr <= data_out;
						case( data_out [6:0] )			// the first 7 bits of the instruction are the opcode in tiny risc-V
							
							REG_REG: 
								begin
									write_reg <= data_out [11:7];		//address of reg being written to
									read_reg_1 <= data_out [19:15];	//addresses of registers being read from
									read_reg_2 <= data_out [24:20];
								
									case ( data_out [14:12] ) 		// func3 specifies the instruction
										
										/*	add, sub, mul */
										3'b000:
											if(data_out [30])
												aluControl <= SUB;
											else if (data_out[25])
												aluControl	<= MUL;
											else
												aluControl <= ADD;
										
										3'b111:
											aluControl	<=	AND;
											
										3'b110:
											aluControl	<=	OR;
											
										3'b100:
											aluControl	<=	XOR;
											
										3'b010:
											aluControl	<=	SLT;
											
										3'b011:
											aluControl	<=	SLTU;
											
										/*	SHIFT RIGHT (ARETHMETIC AND LOGIC)	*/
										3'b101:
											if(data_out[30])
												aluControl	<=	SRA;
											else
												aluControl	<=	SRL;
										
										3'b001:
											aluControl	<=	SLL;
								
								endcase		//endcase for func3
									
							end		//end of Reg_Reg instructions
							
							REG_IMM:
								begin
									write_reg <= data_out [11:7];		//address of reg being written to
									read_reg_1 <= data_out [19:15];	//addresses of registers being read from
										
									case ( data_out [14:12] ) 		// func3 specifies the instruction
											/*	add, sub, mul */
										3'b000:
											aluControl <= ADD;
										
										3'b111:
											aluControl	<=	AND;
											
										3'b110:
											aluControl	<=	OR;
											
										3'b100:
											aluControl	<=	XOR;
											
										3'b010:
											aluControl	<=	SLT;
											
										3'b011:
											aluControl	<=	SLTU;
											
										/*	SHIFT RIGHT (ARETHMETIC AND LOGIC)	*/
										3'b101:
											if(data_out[30])
												aluControl	<=	SRA;
											else
												aluControl	<=	SRL;
										
										3'b001:
											aluControl	<=	SLL;
										
									endcase  // end of func3
										
								end		// end of Reg_Imm
							
							
							LUI:		//Load U type immediete into top 20 bits
								begin
									write_reg <= data_out [11:7];		//address of reg being written to
								end
								
							AUIPC:		//Add U type immediete and PC
								begin
									write_reg <= data_out [11:7];		//address of reg being written to
									aluControl	<= ADD;
								end
								
								
							LOAD:
								begin
									write_reg <= data_out [11:7];		//address of reg being written to
									
								end
								
							STORE:
								begin
									read_reg_1 <= data_out[19:15];	//address of where to be stored in memory
									read_reg_2 <= data_out[24:20];	//data to be stored
									aluControl <= ADD;
								end
								
								
							JAL:
								begin
									write_reg <= data_out [11:7];		//address of reg being written to
									aluControl	<=	ADD;
								end
								
							JR:
							begin
								aluControl <= ADD;
								write_reg	<=	data_out[11:7];
								read_reg_1	<=	data_out[19:15];
							end
							
							BRANCH:
							begin
								read_reg_1	<=	data_out[19:15];
								read_reg_2	<=	data_out[24:20];
								aluControl	<=	ADD;
								
							
							end
							
							default:
								begin
								
								
								
								
								end
							
							
					endcase
						
						
						
						
						
						
						
						
						
					end
					
				EXECUTE:
					begin
						reg_wren <= 1'b0;	//	do not write to register in execute phase
						case( stored_instr [6:0])
							REG_REG:
							begin
								aluIn1	<=	read_data_1;
								aluIn2 <= read_data_2;
							end
							
							REG_IMM:
							begin
								aluIn1 <= read_data_1;
								// For shift operations (SRAI, SRLI, SLLI), use only 5-bit shamt
								 if(stored_instr[14:12] == 3'b101 || stored_instr[14:12] == 3'b001)
									  aluIn2 <= {27'b0, stored_instr[24:20]};  // 5-bit shift amount
								 else
									  aluIn2 <= i_imm;  // Full 12-bit sign-extended immediate
							end
							
							LUI:
							begin
								// No ALU task to do
							end
							
							AUIPC:
							begin
								aluIn1	<= {22'b0, PC};
								aluIn2	<= u_imm;
							end
							
							STORE:
							begin
								aluIn1	<= read_data_1;
								aluIn2	<=	s_imm;
							end
							
							JAL:
							begin
								aluIn1	<= PC;
								aluIn2	<=	j_imm >>> 2;
							end
							
							JR:		//same as JALR
							begin
								aluIn1	<=	read_data_1;
								aluIn2	<=	i_imm >>> 2;
							end
							
							BRANCH:
							begin
							aluIn1	<=	PC;
								
								case(	stored_instr [ 14:12 ])
									3'b000:
										if(	read_data_1	==	read_data_2)
											aluIn2	<=	b_imm >>> 2;
										else
											aluIn2	<= 32'd1;
											
									3'b001:
										if(	read_data_1	!=	read_data_2)
												aluIn2	<=	b_imm >>> 2;
											else
												aluIn2	<= 32'd1;
												
									3'b100:
										if(	$signed(read_data_1)	<	$signed(read_data_2))
												aluIn2	<=	b_imm >>> 2;
											else
												aluIn2	<= 32'd1;
												
									3'b101:
									if(	$signed(read_data_1)	>=	$signed(read_data_2)	)
												aluIn2	<=	b_imm >>> 2;
											else
												aluIn2	<= 32'd1;
												
									3'b110:
										if(	read_data_1	<	read_data_2)
													aluIn2	<=	b_imm >>> 2;
												else
													aluIn2	<= 32'd1;
													
									3'b111:
										if(	read_data_1	>
	read_data_2)
													aluIn2	<=	b_imm >>> 2;
												else
													aluIn2	<= 32'd1;
								
								endcase
							
							
							end
						
						endcase
						
						
						
						
					end		// end of execute
					
				WRITE_BACK:
					begin			/*	TEST	*/
					
						case( stored_instr [6:0] )
							REG_REG, REG_IMM, AUIPC:
							begin
								reg_wren <= 1'b1;
								write_data <= aluOut;
								PC	<=	PC+1;
								address <= PC + 1;
							end
							
							LUI:
							begin
								reg_wren <= 1'b1;
								write_data <= u_imm;
								PC <= PC+1;
								address <= PC + 1;
							end
							
							STORE:
							begin
								wren <= 1'b1;
								data_in	<= read_data_2;
								address	<=	aluOut;
								PC <= PC+1;
								address <= PC + 1;
							end

							JAL:
							begin
								reg_wren <= 1'b1;
								write_data <= PC + 1;
								PC	<= aluOut;
								address <= aluOut;
								
							end
							
							JR:
							begin
								reg_wren	<=	1'b1;
								write_data	<=	PC + 1;
								PC	<=	aluOut;
								address <= aluOut;
							end
							
							
							
							BRANCH:
							begin
								PC	<=	aluOut;
								address <= aluOut;
							
							end
							
							
							
						
						endcase
					
					
					
					end		// END OF WRITE BACK


		endcase		//end of states
		
	end

endmodule