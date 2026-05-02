
/*			SINGLE CYCLE REGISTER FILE			*/

module Registers
	(
		input clk,
		input rst,
		input wren,
		input [4:0] write_reg,		//	ADDRESS OF REGISTER TO BE WRITTEN TO
		input [ 31:0] write_data,
		input [4:0] read_reg_1,		//	ADDRESS OF REGISTER TO BE READ FROM
		input [4:0] read_reg_2,
		input [4:0] switches,
		output [ 31:0] read_data_1,		//	THE DATA IN REGISTER AT ADDR READ_REG_1
		output [ 31:0] read_data_2,
		output reg [ 9:0] LEDout
	
	);
	
	reg [31:0] register [31:0];		//	A 32 INDEX ARRAY OF REGISTERS
	
	integer i;
	always@(posedge clk or negedge rst)
	begin
		if( rst == 1'b0)
			begin
				for (i=0; i<32;i=i+1)
					register [i] <= 32'd0;
				end
		
		else if( wren == 1'b1 && write_reg != 5'd0)			//WRITE ENABLE IS ON
			register [write_reg] <= write_data;
		
		/*		REG TYPES <= THEMSELVES BY DEFAULT
					ALL OTHER INDICIES OF REGISTER STAY THE SAME		*/
					
	end
	
	
	/*		OUTPUT 32 BIT REGISTER DATA OF REGISTER W/ ADDR READ_REG		*/
	assign read_data_1 = register [ read_reg_1];
	assign read_data_2 = register [ read_reg_2];
			
			
	/*		TEST		*/
	/*		switches	->	displayed register
			00000	->	t0 (x5)
			00001	-> t1 (x6)
			00010 -> t2	(x7)
			00011	->	s0 (x8)	*/
	always@(*)
		begin
		if(switches == 5'b00000)
			LEDout = register[5] [9:0];
		else if(switches == 5'b00001)
			LEDout = register[6] [9:0];
		else if(switches == 5'b00010)
			LEDout = register[7] [9:0];
		else if(switches == 5'b00011)
			LEDout = register[8] [9:0];
		else
			LEDout = 10'd0;
	end
	
endmodule