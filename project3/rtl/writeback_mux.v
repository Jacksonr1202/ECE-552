`default_nettype none

// Select the value written to the register file.
module writeback_mux (
    input  wire        i_jal,
    input  wire        i_jalr,
    input  wire        i_mem_to_reg,
    input  wire        i_is_lui,
    input  wire [31:0] i_pc_plus4,
    input  wire [31:0] i_load_data,
    input  wire [31:0] i_immediate,
    input  wire [31:0] i_alu_result,
    output wire [31:0] o_writeback_data
);
    assign o_writeback_data = (i_jal || i_jalr) ? i_pc_plus4 :
                              i_mem_to_reg     ? i_load_data :
                              i_is_lui         ? i_immediate :
                                                 i_alu_result;
endmodule

`default_nettype wire
