module rw_mem(
    input [31:0] addr_d,
    input [31:0] data_d,
    input mem_rw,
    input imem_w,
    input [31:0] bios_doutb,
    output reg [31:0] mem_bios_dout,
    output reg [31:0] mem_dmem_dout,
    output reg [11:0] bios_addrb,
    output reg [13:0] dmem_addr,
    output reg [31:0]
);

endmodule