module Processor
	(
		input clk,
		input rst,
		output reg [9:0] LED
	
	);
	
	reg [ 9:0] PC;
	reg [9:0] address;		// SIZE OF THIS BUS MAY CHANGE IF I CHANGE MEMORY CAPACITY	- UPDATE SYMBOL FILE FOR MEMORY.V TO DOUBLE CHECK
	reg [31:0] data_in;
	reg wren;
	wire [31:0] data_out;
	
	
	/*		EXTENDED IMMEDIETE VALUES		*/
	wire [31:0] i_imm = { {20{data_out[31]}}, data_out[31:20] };
	wire [31:0] s_imm = { {20{data_out[31]}}, data_out[31:25], data_out[11:7] };
	wire [31:0] b_imm = { {19{data_out[31]}}, data_out[31], data_out[7], data_out[30:25], data_out[11:8] };

	
	
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
		.read_data_2 ( read_data_2 )
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
			DECODE:	NS = EXECUTE;
			EXECUTE:	NS = WRITE_BACK;
			WRITE_BACK:	NS = FETCH;
			
				default: NS = STOP;		//IF ERROR -> STOP
				STOP:	NS = STOP;
		
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
			
					
			case(S)
			
				START:
					begin
						address <= 10'd0;		// SIZE OF THIS BUS MAY CHANGE IF I CHANGE MEMORY CAPACITY	- UPDATE SYMBOL FILE FOR MEMORY.V TO DOUBLE CHECK
						data_in <= 32'd0;
						wren <= 1'b0;
					end
					
				FETCH:
					begin
						address <= PC;
						wren <= 1'b0;
					end
					
				FETCH_2:
					begin
							//EMPTY STATE WAITING FOR q (DATA_OUT)
					end
					
				DECODE:
					begin
						/*		UPDATE CONTROL SIGNALS BASED ON INSTRUCTION		*/	
						
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
							
							
							
							
							
					endcase
						
						
						
						
						
						
						
						
						
					end
					
				EXECUTE:
					begin
						reg_wren <= 1'b0;	//	do not write to register in execute phase
						case( data_out [6:0])
							REG_REG:
							begin
								aluIn1	<=	read_data_1;
								aluIn2 <= read_data_2;
							end
							
							REG_IMM:
							begin
								aluIn1	<=	read_data_1;
								aluIn2	<=	i_imm;
							end
						
						endcase
						
						
						
						
					end		// end of execute
					
				WRITE_BACK:
					begin
					//TEST
					if(aluOut == 20)
						LED <= 10'b0101010101;
					else
						LED <= 10'd1;
					
						reg_wren <= 1'b1;
						case( data_out [6:0] )
							REG_REG, REG_IMM:
							begin
								write_data <= aluOut;
								PC	<=	PC+1;
							end
							
							
						
						endcase
					
					
					
					end		// END OF WRITE BACK


		endcase		//end of states

endmodule