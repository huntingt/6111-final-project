module RayMemoryTB #(
    parameter POSITION_WIDTH=16,

    parameter DATA_WIDTH=24,
    parameter ADDRESS_WIDTH=32,
    
    parameter MASTER_ID_WIDTH=8,
    parameter MASTER_ID=0,
    
    parameter MATERIAL_ADDRESS_WIDTH=8
    )(
    input clock,
    input reset,
    input logic [ADDRESS_WIDTH-1:0] materialAddress,
    input logic [ADDRESS_WIDTH-1:0] treeAddress,
    input logic flush,
    input logic traverse,
    input logic [POSITION_WIDTH-1:0] position [2:0],
    output logic [3:0] depth,
    output logic [DATA_WIDTH-1:0] material
    input logic writePixel,
    input logic [23:0] pixel,
    input logic [ADDRESS_WIDTH-1:0] pixelAddress,
    output logic ready,
    
    output logic [MASTER_ID_WIDTH-1:0] msID,
    output logic [ADDRESS_WIDTH-1:0] msAddress,
    output logic [DATA_WIDTH-1:0] msData,
    output logic msWrite,
    input logic msReady,
    output logic msValid,

    input logic [MASTER_ID_WIDTH-1:0] smID,
    input logic [DATA_WIDTH-1:0] smData,
    output logic smReady,
    output logic smValid
    );

    MemoryBus#(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID_WIDTH(MASTER_ID_WIDTH)
    ) bus;

    assign msID = bus.msID;
    assign msAddress = bus.msAddress;
    assign msData = bus.msData;
    assign msWrite = bus.msWrite;
    assign bus.msReady = msReady;
    assign msValid = bus.msValid;

    assign bus.smID = smID;
    assign bus.smData = smData;
    assign smReady = bus.smReady;
    assign smValid = bus.smValid;

    RayMemory#(
        .POSITION_WIDTH(POSITION_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID_WIDTH(MASTER_ID_WIDTH),
        .MASTER_ID(MASTER_ID),
        .MATERIAL_ADDRESS_WIDTH(MATERIAL_ADDRESS_WIDTH)
    ) dut(
        .clock(clock),
        .reset(reset),
        .materialAddress(materialAddress),
        .treeAddress(treeAddress),
        .flush(flush),
        .traverse(traverse),
        .position(position),
        .depth(depth),
        .material(material),
        .writePixel(writePixel),
        .pixel(pixel),
        .pixelAddress(pixelAddress),
        .ready(ready),
        .bus(bus));
endmodule
