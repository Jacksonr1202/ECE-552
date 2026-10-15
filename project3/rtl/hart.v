module hart #(
    // After reset, the program counter (PC) should be initialized to this
    // address and start executing instructions from there.
    parameter RESET_ADDR = 32'h00000000
) (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // Instruction fetch goes through a read only instruction memory (imem)
    // port. The port accepts a 32-bit address (e.g. from the program counter)
    // per cycle and combinationally returns a 32-bit instruction word. This
    // is not representative of a realistic memory interface; it has been
    // modeled as more similar to a DFF or SRAM to simplify phase 3. In
    // later phases, you will replace this with a more realistic memory.
    //
    // 32-bit read address for the instruction memory. This is expected to be
    // 4 byte aligned - that is, the two LSBs should be zero.
    output wire [31:0] o_imem_raddr,
    // Instruction word fetched from memory, available on the same cycle.
    input  wire [31:0] i_imem_rdata,
    // Data memory accesses go through a separate read/write data memory (dmem)
    // that is shared between read (load) and write (stored). The port accepts
    // a 32-bit address, read or write enable, and mask (explained below) each
    // cycle. Reads are combinational - values are available immediately after
    // updating the address and asserting read enable. Writes occur on (and
    // are visible at) the next clock edge.
    //
    // Read/write address for the data memory. This should be 32-bit aligned
    // (i.e. the two LSB should be zero). See `o_dmem_mask` for how to perform
    // half-word and byte accesses at unaligned addresses.
    output wire [31:0] o_dmem_addr,
    // When asserted, the memory will perform a read at the aligned address
    // specified by `i_addr` and return the 32-bit word at that address
    // immediately (i.e. combinationally). It is illegal to assert this and
    // `o_dmem_wen` on the same cycle.
    output wire        o_dmem_ren,
    // When asserted, the memory will perform a write to the aligned address
    // `o_dmem_addr`. When asserted, the memory will write the bytes in
    // `o_dmem_wdata` (specified by the mask) to memory at the specified
    // address on the next rising clock edge. It is illegal to assert this and
    // `o_dmem_ren` on the same cycle.
    output wire        o_dmem_wen,
    // The 32-bit word to write to memory when `o_dmem_wen` is asserted. When
    // write enable is asserted, the byte lanes specified by the mask will be
    // written to the memory word at the aligned address at the next rising
    // clock edge. The other byte lanes of the word will be unaffected.
    output wire [31:0] o_dmem_wdata,
    // The dmem interface expects word (32 bit) aligned addresses. However,
    // the processor supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    //
    // To perform a half-word read at address 0x00001002, align `o_dmem_addr`
    // to 0x00001000, assert `o_dmem_ren`, and set the mask to 0b1100 to
    // indicate that only the upper two bytes should be read. Only the upper
    // two bytes of `i_dmem_rdata` can be assumed to have valid data; to
    // calculate the final value of the `lh[u]` instruction, shift the rdata
    // word right by 16 bits and sign/zero extend as appropriate.
    //
    // To perform a byte write at address 0x00002003, align `o_dmem_addr` to
    // `0x00002000`, assert `o_dmem_wen`, and set the mask to 0b1000 to
    // indicate that only the upper byte should be written. On the next clock
    // cycle, the upper byte of `o_dmem_wdata` will be written to memory, with
    // the other three bytes of the aligned word unaffected. Remember to shift
    // the value of the `sb` instruction left by 24 bits to place it in the
    // appropriate byte lane.
    output wire [ 3:0] o_dmem_mask,
    // The 32-bit word read from data memory. When `o_dmem_ren` is asserted,
    // this will immediately reflect the contents of memory at the specified
    // address, for the bytes enabled by the mask. When read enable is not
    // asserted, or for bytes not set in the mask, the value is undefined.
    input  wire [31:0] i_dmem_rdata,
	// The output `retire` interface is used to signal to the testbench that
    // the CPU has completed and retired an instruction. A single cycle
    // implementation will assert this every cycle; however, a pipelined
    // implementation that needs to stall (due to internal hazards or waiting
    // on memory accesses) will not assert the signal on cycles where the
    // instruction in the writeback stage is not retiring.
    //
    // Asserted when an instruction is being retired this cycle. If this is
    // not asserted, the other retire signals are ignored and may be left invalid.
    output wire        o_retire_valid,
    // The 32 bit instruction word of the instrution being retired. This
    // should be the unmodified instruction word fetched from instruction
    // memory.
    output wire [31:0] o_retire_inst,
    // Asserted if the instruction produced a trap, due to an illegal
    // instruction, unaligned data memory access, or unaligned instruction
    // address on a taken branch or jump.
    output wire        o_retire_trap,
    // Asserted if the instruction is an `ebreak` instruction used to halt the
    // processor. This is used for debugging and testing purposes to end
    // a program.
    output wire        o_retire_halt,
    // The first register address read by the instruction being retired. If
    // the instruction does not read from a register (like `lui`), this is
    // don't-care -- the grading testbench doesn't look at it in that case.
    output wire [ 4:0] o_retire_rs1_raddr,
    // The second register address read by the instruction being retired. If
    // the instruction does not read from a second register (like `addi`),
    // this is don't-care -- the grading testbench doesn't look at it in that
    // case.
    output wire [ 4:0] o_retire_rs2_raddr,
    // The first source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs1 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs1_rdata,
    // The second source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs2 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs2_rdata,
    // The destination register address written by the instruction being
    // retired. If the instruction does not write to a register (like `sw`),
    // this should be 5'd0.
    output wire [ 4:0] o_retire_rd_waddr,
    // The destination register data written to the register file in the
    // writeback stage by this instruction. If rd is 5'd0, this field is
    // ignored and can be treated as a don't care.
    output wire [31:0] o_retire_rd_wdata,
    // The current program counter of the instruction being retired - i.e.
    // the instruction memory address that the instruction was fetched from.
    output wire [31:0] o_retire_pc,
    // the next program counter after the instruction is retired. For most
    // instructions, this is `o_retire_pc + 4`, but must be the branch or jump
    // target for *taken* branches and jumps.
    output wire [31:0] o_retire_next_pc

`ifdef RISCV_FORMAL
    ,`RVFI_OUTPUTS,
`endif
);
    wire [31:0] pc;
    wire [31:0] inst;
    wire [31:0] pc_plus4;
    wire [31:0] imm;
    wire [ 5:0] imm_select;
    wire [ 4:0] rd_addr;
    wire [ 4:0] rs1_addr;
    wire [ 4:0] rs2_addr;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] rd_wdata;
    wire [ 1:0] PC_sel;
    wire [ 2:0] ALU_sel;
    wire        ALU_src;
    wire        ALU_sub;
    wire        ALU_arith;
    wire        ALU_unsigned;
    wire        reg_write;
    wire        mem_write;
    wire        mem_read;
    wire        mem_to_reg;
    wire        branch;
    wire        jal;
    wire        jalr;
    wire [31:0] alu_op2;
    wire [31:0] alu_result;
    wire        alu_eq;
    wire        alu_slt;
    wire [31:0] load_data;
    wire        dmem_misaligned;

    localparam [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam [6:0] OPCODE_STORE  = 7'b0100011;
    localparam [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam [6:0] OPCODE_JAL    = 7'b1101111;
    localparam [6:0] OPCODE_JALR   = 7'b1100111;
    localparam [6:0] OPCODE_LUI    = 7'b0110111;
    localparam [6:0] OPCODE_AUIPC  = 7'b0010111;
    localparam [6:0] OPCODE_OPIMM  = 7'b0010011;
    localparam [6:0] OPCODE_OP     = 7'b0110011;
    localparam [6:0] OPCODE_SYSTEM = 7'b1110011;

    assign o_imem_raddr = pc;
    assign o_retire_valid = 1'b1;
    assign o_retire_inst = inst;
    assign o_retire_trap = (mem_read || mem_write) && dmem_misaligned;
    assign o_retire_halt = (inst == 32'h0010_0073);
    assign o_retire_pc = pc;
    assign o_retire_next_pc = (PC_sel == 2'b00) ? pc_plus4 :
                              (PC_sel == 2'b01) ? pc + imm :
                                                  (rs1_data + imm) & ~32'd1;
    assign o_retire_rs1_raddr = rs1_addr;
    assign o_retire_rs2_raddr = rs2_addr;
    assign o_retire_rs1_rdata = rs1_data;
    assign o_retire_rs2_rdata = rs2_data;
    assign o_retire_rd_waddr = reg_write ? rd_addr : 5'd0;
    assign o_retire_rd_wdata = reg_write ? rd_wdata : 32'd0;
    control_unit control_unit (
        .inst(inst),
        .Eq(alu_eq),
        .LT(alu_slt),
        .LTU(alu_slt),
        .RegWrite(reg_write),
        .ALUsrc(ALU_src),
        .MemToReg(mem_to_reg),
        .MemRead(mem_read),
        .MemWrite(mem_write),
        .Branch(branch),
        .ALU_sub(ALU_sub),
        .ALU_arith(ALU_arith),
        .ALU_unsigned(ALU_unsigned),
        .ALUop(ALU_sel),
        .JAL(jal),
        .JALR(jalr),
        .PC_sel(PC_sel)
    );
    
    //Instruction fetch
    IF #(
        .RESET_ADDR(RESET_ADDR)
    ) if_stage (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_imem_rdata(i_imem_rdata),
        .PC_sel(PC_sel),
        .imm(imm),
        .rs1_data(rs1_data),

        .pc_plus4(pc_plus4),
        .pc(pc),
        .inst(inst)
    );

    // Immediate generator
    imm imm_generation(
        .i_inst(inst),
        .i_format(imm_select),
        .o_immediate(imm)
    );

    // Instruction decode
    assign rd_addr = inst[11:7];
    assign rs1_addr = inst[19:15];
    assign rs2_addr = inst[24:20];
    assign imm_select[0] = (inst[6:0] == OPCODE_OP);
    assign imm_select[1] = (inst[6:0] == OPCODE_OPIMM) |
                           (inst[6:0] == OPCODE_LOAD) |
                           (inst[6:0] == OPCODE_JALR);
    assign imm_select[2] = (inst[6:0] == OPCODE_STORE);
    assign imm_select[3] = (inst[6:0] == OPCODE_BRANCH);
    assign imm_select[4] = (inst[6:0] == OPCODE_LUI) |
                           (inst[6:0] == OPCODE_AUIPC);
    assign imm_select[5] = (inst[6:0] == OPCODE_JAL);

    //Register file with no bypassing
    rf #(
        .BYPASS_EN(0)
    ) rf (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rs1_raddr(rs1_addr),
        .i_rs2_raddr(rs2_addr),
        .i_rd_waddr(rd_addr),
        .i_rd_wdata(rd_wdata),
        .i_rd_wen(reg_write),

        .o_rs1_rdata(rs1_data),
        .o_rs2_rdata(rs2_data)
    );

    //ALU src mux
    assign alu_op2 = ALU_src ? imm : rs2_data;
    //ALU
    alu alu (
        .i_op1(rs1_data),
        .i_op2(alu_op2),
        .i_opsel(ALU_sel),
        .i_sub(ALU_sub),
        .i_unsigned(ALU_unsigned),
        .i_arith(ALU_arith),
        .o_result(alu_result),
        .o_eq(alu_eq),
        .o_slt(alu_slt)
    );

    MAU mau (
        .i_alu_result(alu_result),
        .i_store_data(rs2_data),
        .i_funct3(inst[14:12]),
        .i_mem_read(mem_read),
        .i_mem_write(mem_write),
        .i_dmem_rdata(i_dmem_rdata),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_ren(o_dmem_ren),
        .o_dmem_wen(o_dmem_wen),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_mask(o_dmem_mask),
        .o_load_data(load_data),
        .o_misaligned(dmem_misaligned)
    );

    writeback_mux writeback_mux (
        .i_jal(jal),
        .i_jalr(jalr),
        .i_mem_to_reg(mem_to_reg),
        .i_is_lui(inst[6:0] == OPCODE_LUI),
        .i_pc_plus4(pc_plus4),
        .i_load_data(load_data),
        .i_immediate(imm),
        .i_alu_result(alu_result),
        .o_writeback_data(rd_wdata)
    );

endmodule

`default_nettype wire
