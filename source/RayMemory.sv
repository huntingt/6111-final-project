module RayMemory #(
    parameter POSITION_WIDTH=16,

    parameter DATA_WIDTH=24,
    parameter ADDRESS_WIDTH=32,
    
    parameter MASTER_ID=0,
    
    parameter MATERIAL_ADDRESS_WIDTH=8
    )(
    input clock,
    input reset,

    // These addresses are the base addresses
    // used for finding the data structures in
    // memory. They are expected to remain constant
    // while the module is in use.
    input logic [ADDRESS_WIDTH-1:0] materialAddress,
    input logic [ADDRESS_WIDTH-1:0] treeAddress,

    // flush out the octree caching, should only be
    // called when the system is idleing.
    input logic flush,
    
    // Control signal to start traversing the octree and find
    // the depth and material at the position.
    input logic traverse,
    input logic outOfBounds,
    input logic [POSITION_WIDTH-1:0] position [2:0],
    // Depth in the octree where 0 is the root node, and
    // each addition number is one node further down in the
    // tree. Used to calculate the bounding box of the leaf
    // node.
    output logic [3:0] depth,
    // Material properties at that leaf node. Currently this
    // width is limited to a single data width, but it can be
    // easily extended in the future.
    output logic [DATA_WIDTH-1:0] material,

    // Control signal used to write a 'pixel' pixel to pixelAddress
    input logic writePixel,
    input logic [23:0] pixel,
    input logic [ADDRESS_WIDTH-1:0] pixelAddress,

    output logic ready,
    
    MemoryBus.Master bus
    );

    parameter TREE_OCTANT_SELECT = 3;

    parameter MATERIAL_MASK_SIZE = DATA_WIDTH - MATERIAL_ADDRESS_WIDTH;

    // IDLE - system is ready for a new command
    //
    // PIXEL_SEND - used to potentially extend the
    //      signal if it is not ready to immediatly be
    //      sent, then turn off valid once it is
    //
    // TRAVERSE_SEND - similar to pixel send
    // 
    // TRAVERSE_RECIEVE - wait on requested data
    //
    // MARTERIAL_(SEND/RECIEVE) - similar to TRAVERSE
    enum logic[2:0] {
        IDLE,
        CACHE_SEARCH,
        PIXEL_SEND,
        TRAVERSE_SEND,
        TRAVERSE_RECIEVE,
        MATERIAL_SEND,
        MATERIAL_RECIEVE
    } state;
    
    // used to select the correct octant from an octree node
    logic [TREE_OCTANT_SELECT-1:0] octantSelect;

    logic [POSITION_WIDTH-1:0] cacheQ [2:0];
    logic [3:0] cacheDepth;
    logic [DATA_WIDTH-1:0] cacheNode [POSITION_WIDTH-1:0];

    // set whether bus is currently receiving
    logic busReceiving;
    logic busReceived;
    logic busSending;
    logic busSent;
    
    logic [3:0] dSelect;

    always_comb begin
        ready = state == IDLE;
        /* verilator lint_off WIDTH */
        bus.msID = MASTER_ID;
        /* verilator lint_on WIDTH */

        // selecting the bits at depth, then packing them
        // into a value that will be used to select the octant
        // in each octree node
        dSelect = 4'(POSITION_WIDTH - 1) - depth;
        octantSelect =
            {
                position[2][dSelect],
                position[1][dSelect],
                position[0][dSelect]
            };

        busReceiving =
               state == TRAVERSE_RECIEVE
            || state == MATERIAL_RECIEVE;
        
        /* verilator lint_off WIDTH */
        bus.smTaken =
               busReceiving
            && (bus.smID == MASTER_ID)
            && bus.smValid;
        busReceived = bus.smTaken && bus.smValid;
        /* verilator lint_on WIDTH */

        busSending =
               state == TRAVERSE_SEND
            || state == MATERIAL_SEND
            || state == PIXEL_SEND;
        bus.msValid = busSending;
        busSent = bus.msTaken && bus.msValid;
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            cacheDepth <= 0;
        end else if (flush) begin
            cacheDepth <= 0;
        end else if (state == IDLE) begin
            if (writePixel) begin
                state <= PIXEL_SEND;

                bus.msData <= DATA_WIDTH'(pixel);
                bus.msAddress <= pixelAddress;
                bus.msWrite <= 1;
            end else if (traverse) begin
                if (outOfBounds) begin
                    state <= MATERIAL_SEND;
                    bus.msAddress <= materialAddress;
                end else begin
                    state <= CACHE_SEARCH;
                    depth <= 0;
                end
            end
        end else if (state == CACHE_SEARCH) begin
            if (depth >= cacheDepth
                || cacheQ[0][dSelect] != position[0][dSelect]
                || cacheQ[1][dSelect] != position[1][dSelect]
                || cacheQ[2][dSelect] != position[2][dSelect]) begin
                state <= TRAVERSE_SEND;
                
                bus.msAddress <= treeAddress + (depth == 0 ?
                    ADDRESS_WIDTH'(octantSelect) :
                    ADDRESS_WIDTH'({cacheNode[depth-1] , octantSelect}));
                bus.msWrite <= 0;
            end

            depth <= depth + 1;
        end else if (state == PIXEL_SEND) begin
            if (busSent) begin
                state <= IDLE;
            end
        end else if (state == TRAVERSE_SEND) begin
            if (busSent) begin
                state <= TRAVERSE_RECIEVE;
            end
        end else if (state == TRAVERSE_RECIEVE) begin
            if (busReceived) begin
                if (bus.smData[DATA_WIDTH-1:DATA_WIDTH-MATERIAL_MASK_SIZE] == '1) begin
                    // this is a material
                    // check if this is spacial case 0
                    if (bus.smData[MATERIAL_ADDRESS_WIDTH-1:0] == 0) begin
                        state <= IDLE;
                        material <= 0;
                    end else begin
                        state <= MATERIAL_SEND;
                        bus.msAddress <= materialAddress +
                            ADDRESS_WIDTH'(bus.smData[MATERIAL_ADDRESS_WIDTH-1:0]);
                    end
                
                    cacheDepth <= depth - 1;
                    cacheQ[0] <= position[0];
                    cacheQ[1] <= position[1];
                    cacheQ[2] <= position[2];
                end else begin
                    // this is a node
                    state <= TRAVERSE_SEND;
                    bus.msAddress <= treeAddress +
                        ADDRESS_WIDTH'({bus.smData, octantSelect});
                    
                    // save to cache
                    cacheNode[depth-1] <= bus.smData;
            
                    depth <= depth + 1;
                end
            end
        end else if (state == MATERIAL_SEND) begin
            if (busSent) begin
                state <= MATERIAL_RECIEVE;
            end
        end else if (state == MATERIAL_RECIEVE) begin
            if (busReceived) begin
                state <= IDLE;
                material <= bus.smData;
            end
        end

        if (0) begin
            $display("state: %d, msValid: %d, msTaken: %d, msAddress: %d, msData: %d, smValid: %d, smTaken: %d, smData: %h",
                state, bus.msValid, bus.msTaken, bus.msAddress, bus.msData, bus.smValid, bus.smTaken, bus.smData);
        end
        if (0) begin
            $display("octant: %b, depth: %d, position: {%d, %d, %d}, cacheDepth: %d",
                octantSelect, depth, position[0], position[1], position[2], cacheDepth);
        end
    end
endmodule: RayMemory
