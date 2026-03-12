module Processor
	(
		input clk,
		input [ 9:0] PC	/* Memory file has room for 256 instructions
									PC has to count up to (255 * 4) 			bc PC is divided by 4 before fetching instruction
									log(1020) / log(2) = 9.9 -> PC is a 10 bit bus to count up to 1020 */
	
	);
	
	wire [31:0] instruction;

	
	
//	-	-	-	-	-	-	-	-	-	INSTRUCTION MEMORY	-	-	-	-	-	-	-	-	-	
	Instruction_Mem my_instruction_memory 
		(
			.address ( PC[9:2]  ),  /* PC>>2 (dropping the first 2 bits)
											PC increments by 4 (1 byte) but the memory file is word addressable (4 bytes) */
			.clock ( clk ),       // Connect clock
			.q ( instruction )         // This is where the 32-bit data comes out
		);

	//SINGLE CYCLE MEMORY ACCESS
	//EVERY CLOCK CYCLE REFRESHES INSTRUCTION
	/* HOW I MADE THE MEMORY
			1. MADE A NEW MEMORY INITIALIZATION FILE (.mif)		note- I think it would work the same with a Hexidecimal file (.hex)
			2. SEARCHED FOR ROM: 1-PORT IN IP CATALOG
			3. USED MEGA WIZARD TO SET UP 1 CYCLE MEMORY
				3a. SET INITIAL CONTENT OF MEMORY TO MY .MIF FILE	*/
				

				
				
//	-	-	-	-	-	-	-	-	-	CONTROL MODULE	-	-	-	-	-	-	-	-	-	
	/*Control control
		(
			.opcode	(	instruction	[6:0]	),		//	[0-6] goes to control module
		
		);
*/




endmodule