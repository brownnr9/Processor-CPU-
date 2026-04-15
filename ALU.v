


module ALU
(
	input [31:0] rs1, rs2,
	input [3:0] aluControl,
	output reg [31:0] out
);

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


always@(*)

	case (aluControl)
		ADD:	out = rs1 + rs2;
		SUB:	out = rs1 - rs2;
		AND:	out = rs1 && rs2;
		OR:	out = rs1 || rs2;
		XOR:	out = rs1 ^ rs2;
		SLT:	out = $signed(rs1) < $signed(rs2);
		SLTU: out = rs1 < rs2;
		SRA:	out = rs1 >>> rs2;
		SRL:	out = rs1 >> rs2;
		MUL:	out = rs1 * rs2;
		
	endcase

endmodule
		