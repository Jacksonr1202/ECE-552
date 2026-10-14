`default_nettype none

// The arithmetic logic unit (ALU) is responsible for performing the core
// calculations of the processor. It takes two 32-bit operands and outputs
// a 32 bit result based on the selection operation - addition, comparison,
// shift, or logical operation. This ALU is a purely combinational block, so
// you should not attempt to add any registers or pipeline it.
module alu (
    // NOTE: Both 3'b010 and 3'b011 are used for set less than operations and
    // your implementation should output the same result for both codes. The
    // reason for this will become clear in project 3.
    //
    // Major operation selection.
    // 3'b000: addition/subtraction if `i_sub` asserted
    // 3'b001: shift left logical
    // 3'b010,
    // 3'b011: set less than/unsigned if `i_unsigned` asserted
    // 3'b100: exclusive or
    // 3'b101: shift right logical/arithmetic if `i_arith` asserted
    // 3'b110: or
    // 3'b111: and
    input  wire [ 2:0] i_opsel,
    // When asserted, addition operations should subtract instead.
    // This is only used for `i_opsel == 3'b000` (addition/subtraction).
    input  wire        i_sub,
    // When asserted, comparison operations should be treated as unsigned.
    // This is used for branch comparisons and set less than unsigned. For
    // b ranch operations, the ALU result is not used, only the comparison
    // results.
    input  wire        i_unsigned,
    // When asserted, right shifts should be treated as arithmetic instead of
    // logical. This is only used for `i_opsel == 3'b101` (shift right).
    input  wire        i_arith,
    // First 32-bit input operand.
    input  wire [31:0] i_op1,
    // Second 32-bit input operand.
    input  wire [31:0] i_op2,
    // 32-bit output result. Any carry out should be ignored.
    output wire [31:0] o_result,
    // Equality result. This is used externally to determine if a branch
    // should be taken.
    output wire        o_eq,
    // Set less than result. This is used externally to determine if a branch
    // should be taken.
    output wire        o_slt
);
    localparam [2:0] OP_ADD  = 3'b000;
    localparam [2:0] OP_SLL  = 3'b001;
    localparam [2:0] OP_SLT  = 3'b010;
    localparam [2:0] OP_SLTU = 3'b011;
    localparam [2:0] OP_XOR  = 3'b100;
    localparam [2:0] OP_SRL  = 3'b101;
    localparam [2:0] OP_OR   = 3'b110;
    localparam [2:0] OP_AND  = 3'b111;

    reg [31:0] result;
    reg        eq;
    reg        slt;

    wire signed_lt;
    wire cmp_lt;
    wire [31:0] sll_s1;
    wire [31:0] sll_s2;
    wire [31:0] sll_s4;
    wire [31:0] sll_s8;
    wire [31:0] sll_s16;
    wire [31:0] srl_s1;
    wire [31:0] srl_s2;
    wire [31:0] srl_s4;
    wire [31:0] srl_s8;
    wire [31:0] srl_s16;
    wire [31:0] sra_s1;
    wire [31:0] sra_s2;
    wire [31:0] sra_s4;
    wire [31:0] sra_s8;
    wire [31:0] sra_s16;

    assign signed_lt = (i_op1[31] ^ i_op2[31]) ? i_op1[31] : (i_op1 < i_op2);
    assign cmp_lt = i_unsigned ? (i_op1 < i_op2) : signed_lt;

    // Constant-step barrel shifter (left).
    assign sll_s1  = i_op2[0] ? {i_op1[30:0], 1'b0} : i_op1;
    assign sll_s2  = i_op2[1] ? {sll_s1[29:0], 2'b00} : sll_s1;
    assign sll_s4  = i_op2[2] ? {sll_s2[27:0], 4'b0000} : sll_s2;
    assign sll_s8  = i_op2[3] ? {sll_s4[23:0], 8'b00000000} : sll_s4;
    assign sll_s16 = i_op2[4] ? {sll_s8[15:0], 16'b0000000000000000} : sll_s8;

    // Constant-step barrel shifter (logical right).
    assign srl_s1  = i_op2[0] ? {1'b0, i_op1[31:1]} : i_op1;
    assign srl_s2  = i_op2[1] ? {2'b00, srl_s1[31:2]} : srl_s1;
    assign srl_s4  = i_op2[2] ? {4'b0000, srl_s2[31:4]} : srl_s2;
    assign srl_s8  = i_op2[3] ? {8'b00000000, srl_s4[31:8]} : srl_s4;
    assign srl_s16 = i_op2[4] ? {16'b0000000000000000, srl_s8[31:16]} : srl_s8;

    // Constant-step barrel shifter (arithmetic right).
    assign sra_s1  = i_op2[0] ? {i_op1[31], i_op1[31:1]} : i_op1;
    assign sra_s2  = i_op2[1] ? {{2{sra_s1[31]}}, sra_s1[31:2]} : sra_s1;
    assign sra_s4  = i_op2[2] ? {{4{sra_s2[31]}}, sra_s2[31:4]} : sra_s2;
    assign sra_s8  = i_op2[3] ? {{8{sra_s4[31]}}, sra_s4[31:8]} : sra_s4;
    assign sra_s16 = i_op2[4] ? {{16{sra_s8[31]}}, sra_s8[31:16]} : sra_s8;

    assign o_result = result;
    assign o_eq = eq;
    assign o_slt = slt;

    always @(*) begin
        result = 32'b0;
        eq = (i_op1 == i_op2);
        slt = cmp_lt;

        case (i_opsel)
        OP_ADD: begin
            case (i_sub)
            1'b0: begin
                result = i_op1 + i_op2;
            end
            1'b1: begin
                result = i_op1 - i_op2;
            end
            default: begin
                result = i_op1 + i_op2;
            end
            endcase
        end
        OP_SLL: begin
            result = sll_s16;
        end
        OP_SLT, OP_SLTU: begin
            slt = cmp_lt;
            result = {31'b0, cmp_lt};
        end
        OP_XOR: begin
            result = i_op1 ^ i_op2;
        end
        OP_SRL: begin
            case (i_arith)
            1'b0: begin
                result = srl_s16;
            end
            1'b1: begin
                result = sra_s16;
            end
            default: begin
                result = srl_s16;
            end
            endcase
        end
        OP_OR: begin
            result = i_op1 | i_op2;
        end
        OP_AND: begin
            result = i_op1 & i_op2;
        end
        default: begin
            result = 32'b0;
            eq = (i_op1 == i_op2);
            slt = 1'b0;
        end
        endcase
    end
endmodule

`default_nettype wire
