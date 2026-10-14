`timescale 1ns/1ps

// Control-unit verification is organized around assembly instructions first.
// The instruction words below are the corresponding RV32I machine encodings.
module control_unit_tb;
	reg  [31:0] inst;
	reg         eq_input;
	reg         lt_input;
	reg         ltu_input;

	wire       RegWrite;
	wire       ALUsrc;
	wire       MemToReg;
	wire       MemRead;
	wire       MemWrite;
	wire       Branch;
	wire [3:0] ALUop;
	wire       BranchTaken;
	wire       JAL;
	wire       JALR;
	wire [1:0] PC_sel;

	integer tests;

	control_unit dut (
		.inst        (inst),
		.Eq          (eq_input),
		.LT          (lt_input),
		.LTU         (ltu_input),
		.RegWrite    (RegWrite),
		.ALUsrc      (ALUsrc),
		.MemToReg    (MemToReg),
		.MemRead     (MemRead),
		.MemWrite    (MemWrite),
		.Branch      (Branch),
		.ALUop       (ALUop),
		.BranchTaken (BranchTaken),
		.JAL         (JAL),
		.JALR        (JALR),
		.PC_sel      (PC_sel)
	);

	// expected_controls is {RegWrite, ALUsrc, MemToReg, MemRead, MemWrite,
	//                        Branch, BranchTaken, JAL, JALR}.
	task check;
		input [31:0] instruction;
		input        eq_value;
		input        lt_value;
		input        ltu_value;
		input [3:0]  expected_alu;
		input [8:0]  expected_controls;
		begin
			inst = instruction;
			eq_input  = eq_value;
			lt_input  = lt_value;
			ltu_input = ltu_value;
			#1;
			tests = tests + 1;

			if ({RegWrite, ALUsrc, MemToReg, MemRead, MemWrite,
				 Branch, BranchTaken, JAL, JALR} !== expected_controls ||
				ALUop !== expected_alu) begin
				$display("FAIL instruction=%08h funct3=%b Eq=%b LT=%b LTU=%b Branch=%b ALU=%b controls=%b", inst, inst[14:12], eq_input, lt_input, ltu_input, Branch,
						 ALUop, {RegWrite, ALUsrc, MemToReg, MemRead,
								 MemWrite, Branch, BranchTaken, JAL, JALR});
				$fatal(1, "control output mismatch");
			end
		end
	endtask

	initial begin
		tests = 0;
		inst  = 32'd0;
		eq_input  = 1'b0;
		lt_input  = 1'b0;
		ltu_input = 1'b0;

		// add x3, x1, x2; sub x3, x1, x2; and x3, x1, x2
		check(32'h0020_81b3, 0, 0, 0, 4'b0010, 9'b100000000);
		check(32'h4020_81b3, 0, 0, 0, 4'b0110, 9'b100000000);
		check(32'h0020_f1b3, 0, 0, 0, 4'b0000, 9'b100000000);

		// or, xor, sll, srl, sra, slt, and sltu x3, x1, x2
		check(32'h0020_e1b3, 0, 0, 0, 4'b0001, 9'b100000000);
		check(32'h0020_c1b3, 0, 0, 0, 4'b0011, 9'b100000000);
		check(32'h0020_91b3, 0, 0, 0, 4'b0100, 9'b100000000);
		check(32'h0020_d1b3, 0, 0, 0, 4'b0101, 9'b100000000);
		check(32'h4020_d1b3, 0, 0, 0, 4'b1101, 9'b100000000);
		check(32'h0020_a1b3, 0, 0, 0, 4'b0111, 9'b100000000);
		check(32'h0020_b1b3, 0, 0, 0, 4'b1000, 9'b100000000);

		// addi x3, x1, 5; andi x3, x1, 5; srai x3, x1, 3
		check(32'h0050_8193, 0, 0, 0, 4'b0010, 9'b110000000);
		check(32'h0050_f193, 0, 0, 0, 4'b0000, 9'b110000000);
		check(32'h4030_d193, 0, 0, 0, 4'b1101, 9'b110000000);

		// lw x3, 4(x1); sw x3, 4(x1)
		check(32'h0040_a183, 0, 0, 0, 4'b0010, 9'b111100000);
		check(32'h0030_a223, 0, 0, 0, 4'b0010, 9'b010010000);

		// lui x3, 0x12345; auipc x3, 0x12345
		check(32'h1234_51b7, 0, 0, 0, 4'b0010, 9'b110000000);
		check(32'h1234_5197, 0, 0, 0, 4'b0010, 9'b110000000);

		// jal x1, 8; jalr x1, 4(x2)
		check(32'h0080_00ef, 0, 0, 0, 4'b0010, 9'b100000010);
		check(32'h0041_00e7, 0, 0, 0, 4'b0010, 9'b110000001);

		// beq/bne, blt/bge, bltu/bgeu with both taken and not-taken inputs.
		check(32'h0020_8463, 1, 0, 0, 4'b0110, 9'b000001100);
		check(32'h0020_8463, 0, 0, 0, 4'b0110, 9'b000001000);
		check(32'h0020_9463, 0, 0, 0, 4'b0110, 9'b000001100);
		check(32'h0020_c463, 0, 1, 0, 4'b0110, 9'b000001100);
		check(32'h0020_d463, 0, 0, 0, 4'b0110, 9'b000001100);
		check(32'h0020_e463, 0, 0, 1, 4'b0110, 9'b000001100);
		check(32'h0020_f463, 0, 0, 0, 4'b0110, 9'b000001100);

		// An unsupported opcode must not enable any side effect or branch.
		check(32'h0000_0000, 1, 1, 1, 4'b0010, 9'b000000000);

		// Verify the PC mux encoding used by IF:
		// 00 = sequential, 01 = immediate target, 10 = JALR target.
		inst = 32'h0000_0013; // addi: sequential
		#1;
		if (PC_sel !== 2'b00)
			$fatal(1, "PC_sel mismatch for sequential instruction: %b", PC_sel);

		inst = 32'h0080_00ef; // jal: PC + immediate
		#1;
		if (PC_sel !== 2'b01)
			$fatal(1, "PC_sel mismatch for JAL: %b", PC_sel);

		inst = 32'h0041_00e7; // jalr: rs1 + immediate
		#1;
		if (PC_sel !== 2'b10)
			$fatal(1, "PC_sel mismatch for JALR: %b", PC_sel);

		inst = 32'h0020_8463; // beq, taken
		eq_input = 1'b1;
		#1;
		if (PC_sel !== 2'b01)
			$fatal(1, "PC_sel mismatch for taken branch: %b", PC_sel);

		$display("PASS: %0d control-unit assertions", tests);
		$finish;
	end
endmodule
