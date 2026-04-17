
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
		output [ 31:0] read_data_1,		//	THE DATA IN REGISTER AT ADDR READ_REG_1
		output [ 31:0] read_data_2
	
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
		
		else if( wren == 1'b1)			//WRITE ENABLE IS ON
			register [write_reg] <= write_data;
		
		/*		REG TYPES <= THEMSELVES BY DEFAULT
					ALL OTHER INDICIES OF REGISTER STAY THE SAME		*/
	end
	
	
	/*		OUTPUT 32 BIT REGISTER DATA OF REGISTER W/ ADDR READ_REG		*/
	assign read_data_1 = register [ read_reg_1];
	assign read_data_2 = register [ read_reg_2];
			
endmodule