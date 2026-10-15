// Determine whether an RV32I conditional branch is taken. The Branch input
// qualifies the result so non-branch instructions cannot redirect the PC.
module Branch_Control(
	input  wire       Branch,
	input  wire       Eq,
	input  wire       LT,
	input  wire       LTU,
	input  wire [2:0] Funct3,
	output wire       BranchTaken
);
	assign BranchTaken = !Branch ? 1'b0 :
	                      (Funct3 == 3'b000) ? Eq :
	                      (Funct3 == 3'b001) ? ~Eq :
	                      (Funct3 == 3'b100) ? LT :
	                      (Funct3 == 3'b101) ? ~LT :
	                      (Funct3 == 3'b110) ? LTU :
	                      (Funct3 == 3'b111) ? ~LTU : 1'b0;
endmodule
