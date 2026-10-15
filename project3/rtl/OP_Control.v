// Decode the instruction opcode into datapath control signals. ALUOp selects
// the class of ALU operation; the ALU decoder uses funct3/funct7 to finish it.
module OP_Control(
	input  wire [6:0] Opcode,
	output reg        RegWrite,
	output reg        ALUsrc,
	output reg        MemToReg,
	output reg        MemRead,
	output reg        MemWrite,
	output reg        Branch,
	output reg  [1:0] ALUOp,
	output reg        JAL,
	output reg        JALR,
	output reg        AUIPC
);
	// RV32I opcodes.
	localparam [6:0] OPCODE_U_LUI       = 7'b0110111;
	localparam [6:0] OPCODE_U_AUIPC     = 7'b0010111;
	localparam [6:0] OPCODE_J_TYPE      = 7'b1101111;
	localparam [6:0] OPCODE_I_JALR     = 7'b1100111;
	localparam [6:0] OPCODE_B_TYPE      = 7'b1100011;
	localparam [6:0] OPCODE_I_LOAD     = 7'b0000011;
	localparam [6:0] OPCODE_S_TYPE      = 7'b0100011;
	localparam [6:0] OPCODE_I_TYPE      = 7'b0010011;
	localparam [6:0] OPCODE_R_TYPE      = 7'b0110011;

	// ALU class values
	localparam [1:0] ALU_CLASS_DEFAULT  = 2'b00;
	localparam [1:0] ALU_CLASS_BRANCH   = 2'b01;
	localparam [1:0] ALU_CLASS_R_TYPE   = 2'b10;
	localparam [1:0] ALU_CLASS_I_TYPE   = 2'b11;

	always @(*) begin
		RegWrite = 1'b0;
		ALUsrc   = 1'b0;
		MemToReg = 1'b0;
		MemRead  = 1'b0;
		MemWrite = 1'b0;
		Branch   = 1'b0;
		ALUOp    = ALU_CLASS_DEFAULT;
		JAL      = 1'b0;
		JALR     = 1'b0;
		AUIPC    = 1'b0;

		case (Opcode)
			// LUI and AUIPC both use an immediate source and write a result.
			OPCODE_U_LUI: begin
				RegWrite = 1'b1;
				ALUsrc   = 1'b1;
			end
			OPCODE_U_AUIPC: begin
				RegWrite = 1'b1;
				ALUsrc   = 1'b1;
				AUIPC    = (Opcode == OPCODE_U_AUIPC);
			end
			OPCODE_J_TYPE: begin
				RegWrite = 1'b1;
				JAL      = 1'b1;
			end
			OPCODE_I_JALR: begin
				RegWrite = 1'b1;
				ALUsrc   = 1'b1;
				JALR     = 1'b1;
			end
			OPCODE_B_TYPE: begin
				// Branch comparisons are selected as subtraction in the ALU.
				Branch = 1'b1;
				ALUOp  = ALU_CLASS_BRANCH;
			end
			OPCODE_I_LOAD: begin
				RegWrite = 1'b1;
				ALUsrc   = 1'b1;
				MemToReg = 1'b1;
				MemRead  = 1'b1;
			end
			OPCODE_S_TYPE: begin
				ALUsrc   = 1'b1;
				MemWrite = 1'b1;
			end
			OPCODE_I_TYPE: begin
				// Keep OP-IMM separate so an immediate bit cannot request SUB/SRA.
				RegWrite = 1'b1;
				ALUsrc   = 1'b1;
				ALUOp    = ALU_CLASS_I_TYPE;
			end
			OPCODE_R_TYPE: begin
				RegWrite = 1'b1;
				ALUOp    = ALU_CLASS_R_TYPE;
			end
			default: begin
			end
		endcase
	end
endmodule