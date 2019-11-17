module RayTracer #(
    parameter POSITION_WIDTH=16,

    parameter DATA_WIDTH=24,
    parameter ADDRESS_WIDTH=32,
    
    parameter CONFIG_ADDRESS=0,
    parameter MASTER_ID_BASE=0
    )(
    input logic clock,
    input logic reset,

    output logic interrupt,

    MemoryBus.Slave configPort,
    MemoryBus.Master memoryPort
    );

    logic [ADDRESS_WIDTH-1:0] materialAddress;
    logic [ADDRESS_WIDTH-1:0] treeAddress;
    logic [ADDRESS_WIDTH-1:0] frameAddress;

    logic [POSITION_WIDTH-1:0] cameraQ [2:0];
    logic [POSITION_WIDTH-1:0] cameraV [2:0];
    logic [POSITION_WIDTH-1:0] cameraX [2:0];
    logic [POSITION_WIDTH-1:0] cameraY [2:0];

    logic [11:0] width;
    logic [11:0] height;

    logic start;
    logic ready;
    logic busy;
    
    logic flush;
    logic resetRT;
    logic normalize;

    RayConfig #(
        .POSITION_WIDTH(POSITION_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .ADDRESS(CONFIG_ADDRESS)
    ) cnfg (
        .clock(clock),
        .reset(reset),
        .materialAddress(materialAddress),
        .treeAddress(treeAddress),
        .frameAddress(frameAddress),
        .cameraQ(cameraQ),
        .cameraV(cameraV),
        .cameraX(cameraX),
        .cameraY(cameraY),
        .width(width),
        .height(height),
        .start(start),
        .ready(ready),
        .busy(busy),
        .flush(flush),
        .resetRT(resetRT),
        .normalize(normalize),
        .interrupt(interrupt),
        .bus(configPort));

    logic [POSITION_WIDTH-1:0] rayV [2:0];
    logic [ADDRESS_WIDTH-1:0] rayAddress;
    logic rayStart;
    logic rayReady;
    logic rayBusy;

    RayGenerator #(
        .POSITION_WIDTH(POSITION_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) generator (
        .clock(clock),
        .resetRT(reset),
        .start(start),
        .busy(busy),
        .ready(ready),
        .normalize(normalize),
        .cameraV(cameraV),
        .cameraX(cameraX),
        .cameraY(cameraY),
        .width(width),
        .height(height),
        .frameAddress(frameAddress),
        .rayV(rayV),
        .rayAddress(rayAddress),
        .rayStart(rayStart),
        .rayReady(rayReady),
        .rayBusy(rayBusy));

    RayUnit #(
        .POSITION_WIDTH(POSITION_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID(MASTER_ID_BASE + 0)
    ) unit (
        .clock(clock),
        .reset(resetRT),
        .flush(flush),
        .start(rayStart),
        .busy(rayBusy),
        .ready(rayReady),
        .rayQ(cameraQ),
        .rayV(rayV),
        .pixelAddress(rayAddress),
        .materialAddress(materialAddress),
        .treeAddress(treeAddress),
        .bus(memoryPort));

endmodule: RayTracer

