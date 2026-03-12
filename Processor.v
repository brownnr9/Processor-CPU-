module Processor
	(
		input clk,
		input [ :0] PC	
	
	);
	
	wire [31:0] instruction;

	
	
//	-	-	-	-	-	-	-	-	-	INSTRUCTION MEMORY	-	-	-	-	-	-	-	-	-	
	Memory	Memory_inst (
		.address ( address_sig ),
		.clock ( clock_sig ),
		.data ( data_sig ),
		.wren ( wren_sig ),
		.q ( q_sig )
		);

		//		why cant I make a 1 cycle access ROM for instructions and a 2 cycle access RAM for data?
		
	/* HOW I MADE THE MEMORY
			1. MADE A NEW MEMORY INITIALIZATION FILE (.mif)		note- I think it would work the same with a Hexidecimal file (.hex)
			2. Under IP CATALOG TO SEARCH FOR RAM (RAM: 1-PORT)
			3. USED MEGA WIZARD TO SET UP MEMORY
				3a. 'q' = 32 because each instruction is 32 bits
				3b.	1052 32 BIT WORDS			 **MATCHES THE .MIF FILE** 
				3c.	REGISTER 'q' OUTPUT PORT		** MEMORY ACCESS IS 2 CYCLE ** (a little confused why registering 'q' is worth the extra cyccle)
				3d.	SWITCHED q OUTPUT TO Don't Care WHEN MEMORY IS BEING WRITEN TO
				3e.	INITIALIZE CONTENT OF THE MEMORY TO Memory.mif
				*/
				





endmodule