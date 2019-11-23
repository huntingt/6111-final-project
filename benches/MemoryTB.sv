module MemoryTB(
    input clock,
    input reset,

    input logic [31:0] configIn,
    output logic [31:0] configOut,
    input logic [31:0] memoryIn,
    output logic [31:0] memoryOut
    );

    parameter DATA_WIDTH = 24;
    parameter ADDRESS_WIDTH = 32;
    parameter MASTER_ID_WIDTH = 8;
    parameter CONFIG_ADDRESS = 'h26;

    MemoryBus#(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID_WIDTH(MASTER_ID_WIDTH)
    ) cfg ();
    MemoryBus#(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID_WIDTH(MASTER_ID_WIDTH)
    ) memory ();

    MemoryMaster cfgctl(
        .clock(clock),
        .reset(reset),
        .in(configIn),
        .out(configOut),
        .bus(cfg)
    );

    MemorySlave memctl(
        .clock(clock),
        .reset(reset),
        .in(memoryIn),
        .out(memoryOut),
        .bus(memory)
    );

    RayTracer#(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .CONFIG_ADDRESS('h1000000),
        .MASTER_ID_BASE(10)
    ) dut(
        .clock(clock),
        .reset(reset),
        .configPort(cfg),
        .memoryPort(memory));
endmodule: MemoryTB
