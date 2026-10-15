module instruction_decoder (
    input [31:0] instruction,
    output reg [4:0] rd_addr,
    output reg [4:0] rs1_addr,
    output reg [4:0] rs2_addr,
    output reg [5:0] imm_select
);

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

    assign rd_addr = instruction[11:7];
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];

    // The format is one-hot and uses the same bit positions as imm.v.
    assign imm_select[0] = (opcode == OPCODE_OP);
    assign imm_select[1] = (opcode == OPCODE_OPIMM) |
                           (opcode == OPCODE_LOAD) |
                           (opcode == OPCODE_JALR);
    assign imm_select[2] = (opcode == OPCODE_STORE);
    assign imm_select[3] = (opcode == OPCODE_BRANCH);
    assign imm_select[4] = (opcode == OPCODE_LUI) |
                           (opcode == OPCODE_AUIPC);
    assign imm_select[5] = (opcode == OPCODE_JAL);
endmodule