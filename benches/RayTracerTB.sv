module RayTracerTB #(
    parameter POSITION_WIDTH=16,

    parameter DATA_WIDTH=24,
    parameter ADDRESS_WIDTH=32,
    
    parameter CONFIG_ADDRESS='h26,
    parameter MASTER_ID_BASE=8'd4,

    parameter MASTER_ID_WIDTH=8
    )(
    input logic clock,
    input logic reset,

    output logic doneInterrupt,

    output logic [MASTER_ID_WIDTH-1:0] mmsID,
    output logic [ADDRESS_WIDTH-1:0] mmsAddress,
    output logic [DATA_WIDTH-1:0] mmsData,
    output logic mmsWrite,
    input logic mmsTaken,
    output logic mmsValid,

    input logic [MASTER_ID_WIDTH-1:0] msmID,
    input logic [DATA_WIDTH-1:0] msmData,
    output logic msmTaken,
    input logic msmValid,

    input logic [MASTER_ID_WIDTH-1:0] cmsID,
    input logic [ADDRESS_WIDTH-1:0] cmsAddress,
    input logic [DATA_WIDTH-1:0] cmsData,
    input logic cmsWrite,
    output logic cmsTaken,
    input logic cmsValid,

    output logic [MASTER_ID_WIDTH-1:0] csmID,
    output logic [DATA_WIDTH-1:0] csmData,
    input logic csmTaken,
    output logic csmValid
    );

    MemoryBus#(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID_WIDTH(MASTER_ID_WIDTH)
    ) cfg;

    MemoryBus#(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID_WIDTH(MASTER_ID_WIDTH)
    ) mem;
    
    assign mmsID = mem.msID;
    assign mmsAddress = mem.msAddress;
    assign mmsData = mem.msData;
    assign mmsWrite = mem.msWrite;
    assign mem.msTaken = mmsTaken;
    assign mmsValid = mem.msValid;

    assign mem.smID = msmID;
    assign mem.smData = msmData;
    assign msmTaken = mem.smTaken;
    assign mem.smValid = msmValid;

    assign cfg.msID = cmsID;
    assign cfg.msAddress = cmsAddress;
    assign cfg.msData = cmsData;
    assign cfg.msWrite = cmsWrite;
    assign cmsTaken = cfg.msTaken;
    assign cfg.msValid = cmsValid;
    
    assign csmID = cfg.smID;
    assign csmData = cfg.smData;
    assign cfg.smTaken = csmTaken;
    assign csmValid = cfg.smValid;

    RayTracer#(
        .POSITION_WIDTH(POSITION_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .CONFIG_ADDRESS(CONFIG_ADDRESS),
        .MASTER_ID_BASE(MASTER_ID_BASE)
    ) dut(
        .clock(clock),
        .reset(reset),
        .interrupt(doneInterrupt),
        .configPort(cfg),
        .memoryPort(mem));
endmodule: RayTracerTB
