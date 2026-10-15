`default_nettype none

// Memory Access Unit. Converts an ALU effective address and instruction
// memory controls into the aligned external data-memory interface.
module MAU (
    input  wire [31:0] i_alu_result,
    input  wire [31:0] i_store_data,
    input  wire [ 2:0] i_funct3,
    input  wire        i_mem_read,
    input  wire        i_mem_write,
    input  wire [31:0] i_dmem_rdata,

    output wire [31:0] o_dmem_addr,
    output wire        o_dmem_ren,
    output wire        o_dmem_wen,
    output wire [31:0] o_dmem_wdata,
    output wire [ 3:0] o_dmem_mask,
    output wire [31:0] o_load_data,
    output wire        o_misaligned
);
    wire [1:0]  byte_offset;
    wire [3:0]  dmem_mask;
    wire [31:0] store_data;
    wire [31:0] shifted_load_data;

    assign byte_offset = i_alu_result[1:0];
    assign o_dmem_addr = {i_alu_result[31:2], 2'b00};

    assign o_misaligned = (((i_funct3 == 3'b001) ||
                            (i_funct3 == 3'b101)) &&
                            (i_alu_result[0] != 1'b0)) ||
                            ((i_funct3 == 3'b010) &&
                            (i_alu_result[1:0] != 2'b00));

    assign o_dmem_ren = i_mem_read && !o_misaligned;
    assign o_dmem_wen = i_mem_write && !o_misaligned;

    assign dmem_mask = ((i_funct3 == 3'b000) || (i_funct3 == 3'b100)) ?
                       ((byte_offset == 2'b00) ? 4'b0001 :
                        (byte_offset == 2'b01) ? 4'b0010 :
                        (byte_offset == 2'b10) ? 4'b0100 : 4'b1000) :
                       ((i_funct3 == 3'b001) || (i_funct3 == 3'b101)) ?
                       ((byte_offset == 2'b00) ? 4'b0011 :
                        (byte_offset == 2'b10) ? 4'b1100 : 4'b0000) :
                       (i_funct3 == 3'b010) ? 4'b1111 : 4'b0000;

    assign o_dmem_mask = (i_mem_read || i_mem_write) ? dmem_mask : 4'b0000;

    assign store_data = (i_funct3 == 3'b000) ? {{24{i_store_data[7]}}, i_store_data[7:0]} :
                        (i_funct3 == 3'b001) ? {{16{i_store_data[15]}}, i_store_data[15:0]} :
                                                i_store_data;
    
    assign o_dmem_wdata = (byte_offset == 2'b00) ? store_data :
                          (byte_offset == 2'b01) ? (store_data << 8) :
                          (byte_offset == 2'b10) ? (store_data << 16) :
                                                   (store_data << 24);

    assign shifted_load_data = (byte_offset == 2'b00) ? i_dmem_rdata :
                               (byte_offset == 2'b01) ? (i_dmem_rdata >> 8) :
                               (byte_offset == 2'b10) ? (i_dmem_rdata >> 16) :
                                                        (i_dmem_rdata >> 24);

    assign o_load_data = (i_funct3 == 3'b000) ?
                         {{24{shifted_load_data[7]}}, shifted_load_data[7:0]} :
                         (i_funct3 == 3'b100) ?
                         {24'b0, shifted_load_data[7:0]} :
                         (i_funct3 == 3'b001) ?
                         {{16{shifted_load_data[15]}}, shifted_load_data[15:0]} :
                         (i_funct3 == 3'b101) ?
                         {16'b0, shifted_load_data[15:0]} :
                         i_dmem_rdata;
endmodule

`default_nettype wire
