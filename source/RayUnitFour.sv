/*
 * Top level container for a quad ray unit
 */
module RayUnitFour #(
    parameter POSITION_WIDTH=16,
    parameter DATA_WIDTH=24,
    parameter ADDRESS_WIDTH=32,
    parameter MASTER_ID=0
    )(
    input logic clock,
    input logic reset,
    
    input logic flush,

    input logic start,
    output logic busy,
    output logic ready,

    input logic [POSITION_WIDTH-1:0] rayQ [2:0],
    input logic [POSITION_WIDTH-1:0] rayV [2:0],
    
    input logic [ADDRESS_WIDTH-1:0] pixelAddress,

    input logic [ADDRESS_WIDTH-1:0] materialAddress,
    input logic [ADDRESS_WIDTH-1:0] treeAddress,
    
    MemoryBus.Master bus
    );

    MemoryBus#(
        .MASTER_ID_WIDTH(8),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) bus0 ();
    MemoryBus#(
        .MASTER_ID_WIDTH(8),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) bus1 ();

    logic start0;
    logic start1;

    logic ready0;
    logic ready1;

    logic busy0;
    logic busy1;

    assign start0 = start && ready0;
    assign start1 = start && ready1 && !start0;

    assign ready = ready0 || ready1;
    assign busy = busy0 || busy1;

    RayUnitTwo#(
        .POSITION_WIDTH(POSITION_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID(MASTER_ID)
    ) ru0 (
        .clock(clock),
        .reset(reset),
        .flush(flush),
        .start(start0),
        .busy(busy0),
        .ready(ready0),
        .rayQ(rayQ),
        .rayV(rayV),
        .pixelAddress(pixelAddress),
        .materialAddress(materialAddress),
        .treeAddress(treeAddress),
        .bus(bus0)
    );

    RayUnitTwo#(
        .POSITION_WIDTH(POSITION_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID(MASTER_ID+2)
    ) ru1 (
        .clock(clock),
        .reset(reset),
        .flush(flush),
        .start(start1),
        .busy(busy1),
        .ready(ready1),
        .rayQ(rayQ),
        .rayV(rayV),
        .pixelAddress(pixelAddress),
        .materialAddress(materialAddress),
        .treeAddress(treeAddress),
        .bus(bus1)
    );

    BinaryArbiter#(
        .MASTER_ID_WIDTH(8),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) arbiter (
        .clk(clock),
        .sbus0(bus0),
        .sbus1(bus1),
        .mbus(bus)
    );

endmodule: RayUnitFour
