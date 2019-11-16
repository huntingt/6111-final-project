module RayUnitTB #(
    parameter POSITION_WIDTH=16,
    parameter DATA_WIDTH=24,
    parameter ADDRESS_WIDTH=32,
    parameter MASTER_ID=5,
    parameter MASTER_ID_WIDTH=8
    )(
    input clock,
    input reset,
    input logic flush,
    
    input logic start,
    output logic busy,
    output logic ready,

    input logic [POSITION_WIDTH-1:0] rayQ [2:0],
    input logic [POSITION_WIDTH-1:0] rayV [2:0],

    input logic [ADDRESS_WIDTH-1:0] pixelAddress,

    input logic [ADDRESS_WIDTH-1:0] materialAddress,
    input logic [ADDRESS_WIDTH-1:0] treeAddress,
    
    output logic [MASTER_ID_WIDTH-1:0] msID,
    output logic [ADDRESS_WIDTH-1:0] msAddress,
    output logic [DATA_WIDTH-1:0] msData,
    output logic msWrite,
    input logic msTaken,
    output logic msValid,

    input logic [MASTER_ID_WIDTH-1:0] smID,
    input logic [DATA_WIDTH-1:0] smData,
    output logic smTaken,
    input logic smValid
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
    assign bus.msTaken = msTaken;
    assign msValid = bus.msValid;

    assign bus.smID = smID;
    assign bus.smData = smData;
    assign smTaken = bus.smTaken;
    assign bus.smValid = smValid;

    RayUnit#(
        .POSITION_WIDTH(POSITION_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID(MASTER_ID)
    ) dut(
        .clock(clock),
        .reset(reset),
        .flush(flush),
        .start(start),
        .busy(busy),
        .ready(ready),
        .rayQ(rayQ),
        .rayV(rayV),
        .pixelAddress(pixelAddress),
        .materialAddress(materialAddress),
        .treeAddress(treeAddress),
        .bus(bus));
endmodule: RayUnitTB
