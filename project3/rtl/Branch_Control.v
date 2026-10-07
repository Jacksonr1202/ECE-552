// Determine whether an RV32I conditional branch is taken. The Branch input
// qualifies the result so non-branch instructions cannot redirect the PC.
module Branch_Control(
	input  wire       Branch,
	input  wire       Eq,
	input  wire       LT,
	input  wire       LTU,
	input  wire [2:0] Funct3,
	output reg        BranchTaken
);
	always @(*) begin
		BranchTaken = 1'b0;

		if (Branch) begin
			// funct3 selects signed, unsigned, equal, or inverse comparisons.
			case (Funct3)
				3'b000: BranchTaken = Eq;
				3'b001: BranchTaken = ~Eq;
				3'b100: BranchTaken = LT;
				3'b101: BranchTaken = ~LT;
				3'b110: BranchTaken = LTU;
				3'b111: BranchTaken = ~LTU;
				default: BranchTaken = 1'b0;
			endcase
		end
	end
endmodule
