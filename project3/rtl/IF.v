module IF#(
    parameter RESET_ADDR = 32'h00000000
)(
    input i_clk,
    input i_rst,
    input [31:0] i_imem_rdata,
    input [1:0] PC_sel,
    input [31:0] imm,
    input [31:0] rs1_data,

    output wire [31:0] pc_plus4,
    output reg [31:0] pc,
    output wire [31:0] inst
);

wire [31:0] next_pc;
wire [31:0] pc_target;
wire [31:0] jalr_target;
// PC + 4 ADDER
assign pc_plus4 = pc + 32'd4;

// PC Target ADDER
assign pc_target = pc + imm;

// JALR ADD + BIT 0 CLEAR
assign jalr_target = (rs1_data + imm) & (~32'd1);

// Next PC MUX
assign next_pc = (PC_sel == 2'b00) ? pc_plus4 : (PC_sel == 2'b01) ? pc_target : (PC_sel == 2'b10) ? jalr_target : pc_plus4;

// PC Register
always @(posedge i_clk) begin
    if (i_rst) begin
        pc <= RESET_ADDR;
    end else begin
        pc <= next_pc;
    end
end

// Instruction Memory
assign inst = i_imem_rdata;

endmodule