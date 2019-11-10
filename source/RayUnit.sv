/*
 * Top level container for a ray unit
 */

module RayUnit #(
    parameter WIDTH=16,
    parameter ADDRESS_WIDTH=32,
    parameter MASTER_ID=0
    )(
    input clock,
    input reset,
    
    // ready/valid pair for controlling ray unit
    // TODO: consider seperate busy and ready signals
    // so that the ray tracer management system can
    // know when the system is finished with a frame.
    input logic start,
    output logic busy,

    // incoming ray position and direction
    // the ray position is garunteed to remain stable
    // while busy
    input logic [WIDTH-1:0] rayQ [2:0],
    input logic [WIDTH-1:0] rayV [2:0],
    
    // addresses for finding the color and tree
    // these are garunteed to remain stable while the
    // ray unit is busy
    input logic [ADDRESS_WIDTH-1:0] colorAddress,
    input logic [ADDRESS_WIDTH-1:0] treeAddress
    
    // TODO: memory interface
    
    // TODO: pixel interface
    );
    enum logic {
        IDLE,

    } state;
    // TODO: implement module

endmodule: RayUnit
