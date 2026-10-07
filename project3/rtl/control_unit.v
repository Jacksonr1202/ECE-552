// Top-level control decoder. Opcode control, ALU control, and branch control
// are kept separate so each instruction field is interpreted in one place.
module control_unit(
   // The 32 bit instruction being executed 
   input wire [31:0] inst,
   // Three signals determining the relation between the two operands.
   // Used for branching logic
   input wire        Eq,
   input wire        LT,
   input wire        LTU,
   // Signal to determine if we should write to a register
   output wire       RegWrite,
   // Signal to determine what operand we should feed alu, register or imm
   output wire       ALUsrc,
   // Signal to determine if we are loading from memory
   output wire       MemToReg,
   // Signal to determine if we are reading from memory
   output wire       MemRead,
   // Signal to determine if we are writing to memory
   output wire       MemWrite,
   // Signal to determine if we have a branch instruction
   output wire       Branch,
   // Signal determining the operation the ALU will do
   output wire [3:0] ALUop,
   // Signal indicating if we should take the branch or not
   output wire       BranchTaken,
   // Signals selecting the jump target/writeback path
   output wire       JAL,
   output wire       JALR
);

   // Internal two-bit operation class produced by OP_Control.
   wire [1:0] ALUClass;

   // Decode instruction class and datapath enables.
   OP_Control op_control(
      .Opcode   (inst[6:0]),
      .RegWrite (RegWrite),
      .ALUsrc   (ALUsrc),
      .MemToReg (MemToReg),
      .MemRead  (MemRead),
      .MemWrite (MemWrite),
      .Branch   (Branch),
      .ALUOp    (ALUClass),
      .JAL      (JAL),
      .JALR     (JALR)
   );

   // Decode the operation within the selected ALU class.
   ALU_Control alu_control(
      .ALUOp  (ALUClass),
      .Funct3 (inst[14:12]),
      .Funct7 (inst[30]),
      .ALUop  (ALUop)
   );

   // Produce the single qualified branch decision used by the PC controller.
   Branch_Control branch_control(
      .Branch      (Branch),
      .Eq          (Eq),
      .LT          (LT),
      .LTU         (LTU),
      .Funct3      (inst[14:12]),
      .BranchTaken (BranchTaken)
   );

endmodule