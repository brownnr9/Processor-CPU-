module Processor
	(
		input clk,
		input rst,
		input [ 9:0] PC	
	
	);
	
	reg [9:0] address;		// SIZE OF THIS BUS MAY CHANGE IF I CHANGE MEMORY CAPACITY	- UPDATE SYMBOL FILE FOR MEMORY.V TO DOUBLE CHECK
	reg [31:0] data_in;
	reg wren;
	wire [31:0] data_out;
	

	
	
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
		
		
					/*		OPCODE DEFINITIONS		*/
		parameter
						
			/*		Control/Status Register Instructions		(CSRR, CSRW)		*/
			
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
						STPRE			= 7'b0100011,

			/*		Unconditional Jump Instructions		*/
						
						JAL		= 7'b1101111,
						JR			= 7'b1100111,		//	(JR, JALR)
						
			/*		Conditional Branch Instructions
				(BEQ, BNE, BLT, BGE, BLTU, BGEU)		*/
				
						BRANCH      = 7'b1100011;
			
						
			
		
		
		/*		THIS BLOCK CHANGES SIGNALS BASED ON THE STATE		*/
		always@(posedge clk or negedge rst)
		
			if(rst == 1'b0)			//RESET BUTTON IS RESTING HIGH
				begin
					address <= 10'd0;		// SIZE OF THIS BUS MAY CHANGE IF I CHANGE MEMORY CAPACITY	- UPDATE SYMBOL FILE FOR MEMORY.V TO DOUBLE CHECK
					data_in <= 32'd0;
					wren <= 1'b0;
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
							
						endcase
						
						
						
						
						
						
						
						
						
						
					end
					
				EXECUTE:
					begin
						
					end
					
				WRITE_BACK:
					begin
					
					end





endmodule