/*
 * Top level container for a ray unit
 */
module RayUnit #(
    parameter POSITION_WIDTH=16,
    parameter DATA_WIDTH=24,
    parameter ADDRESS_WIDTH=32,
    parameter MASTER_ID=0
    )(
    input logic clock,
    input logic reset,
    
    // flush cached data
    input logic flush,

    // ready/valid pair for controlling ray unit
    // TODO: consider seperate busy and ready signals
    // so that the ray tracer management system can
    // know when the system is finished with a frame.
    input logic start,
    output logic busy,

    // incoming ray position and direction
    // the ray position is garunteed to remain stable
    // while busy
    input logic [POSITION_WIDTH-1:0] rayQ [2:0],
    input logic [POSITION_WIDTH-1:0] rayV [2:0],
    
    // pixel address to write out to, it is saved on the
    // start signal
    input logic [ADDRESS_WIDTH-1:0] pixelAddress,

    // addresses for finding the material and tree
    // these are garunteed to remain stable while the
    // ray unit is busy
    input logic [ADDRESS_WIDTH-1:0] materialAddress,
    input logic [ADDRESS_WIDTH-1:0] treeAddress,
    
    MemoryBus.Master bus
    );
    enum logic[2:0] {
        IDLE,
        STEP_START,
        STEP_FINISH,
        TRAVERSE_START,
        TRAVERSE_FINISH,
        WRITE
    } state;

    logic [POSITION_WIDTH-1:0] q [2:0];
    logic [POSITION_WIDTH-1:0] qp [2:0];
    logic [POSITION_WIDTH-1:0] v [2:0];

    logic [POSITION_WIDTH-1:0] l [2:0];
    logic [POSITION_WIDTH-1:0] u [2:0];

    logic [POSITION_WIDTH-1:0] mask;

    logic [3:0] depth;

    logic step;
    logic stepReady;
    
    logic traverse;
    logic traverseReady;
    
    logic write;
    logic writeReady;
    
    logic memoryReady;
    logic outOfBounds;

    logic [DATA_WIDTH-1:0] material;
    logic [DATA_WIDTH-1:0] pixel;

    logic [ADDRESS_WIDTH-1:0] pixelAddressF;

    always_comb begin
        // find l and u
        mask = (1 << (POSITION_WIDTH - depth)) - 1;
        for (int i = 0; i < 3; i++) begin
            l[i] = q[i] & ~mask;
            u[i] = q[i] | mask;
        end

        write = state == WRITE;
        step = state == STEP_START;
        traverse = state == TRAVERSE_START;
        
        // so that these can be decoupled later
        writeReady = memoryReady;
        traverseReady = memoryReady & !write;

        //TODO: is this stable?
        pixel = outOfBounds ? 0 : material;

        busy = state != IDLE;
    end

    always_ff @(posedge clock) begin
        if (0) begin
            $display("state: %d, traverse: %d, tReady: %d, x: %d, y: %d, z: %d", state, traverse, traverseReady, q[0], q[1], q[2]);
            $display("mask: %b, x: [%d, %d], y: [%d, %d], z: [%d, %d]", mask, l[0], u[0], l[1], u[1], l[2], u[2]);
        end

        if (reset) begin
            state <= IDLE;
        end else if (state == IDLE) begin
            if (start) begin
                state <= TRAVERSE_START;
                
                pixelAddressF <= pixelAddress;
                for (int i = 0; i < 3; i++) begin
                    q[i] <= rayQ[i];
                    v[i] <= rayV[i];
                end
            end
        end else if (state == TRAVERSE_START) begin
            if (traverseReady) begin
                state <= TRAVERSE_FINISH;
            end
        end else if (state == TRAVERSE_FINISH) begin
            if (traverseReady) begin
                if (material == 0) begin
                    state <= STEP_START;
                end else begin
                    state <= WRITE;
                end
            end
        end else if (state == STEP_START) begin
            if (stepReady) begin
                state <= STEP_FINISH;
            end
        end else if (state == STEP_FINISH) begin
            if (stepReady) begin
                if (outOfBounds) begin
                    state <= WRITE;
                end else begin
                    state <= TRAVERSE_START;
                    q <= qp;
                end
            end
        end else if (state == WRITE) begin
            if (writeReady) begin
                state <= IDLE;
            end
        end
    end

    // TODO: seperate ready done interfaces
    // TODO: unify signal names between modules
    RayStepper#(
        .WIDTH(POSITION_WIDTH)
        ) stepper(
        .clock(clock),
        .reset(reset),
        .start(step),
        .q(q),
        .v(v),
        .l(l),
        .u(u),
        .outOfBounds(outOfBounds),
        .done(stepReady),
        .qp(qp));

    RayMemory#(
        .POSITION_WIDTH(POSITION_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .MASTER_ID(MASTER_ID),
        .MATERIAL_ADDRESS_WIDTH(8)
        ) memory(
        .clock(clock),
        .reset(reset),
        .materialAddress(materialAddress),
        .treeAddress(treeAddress),
        .flush(flush),
        .traverse(traverse),
        .position(q),
        .depth(depth),
        .material(material),
        .writePixel(write),
        .pixel(pixel),
        .pixelAddress(pixelAddressF),
        .ready(memoryReady),
        .bus(bus));

endmodule: RayUnit
