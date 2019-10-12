/*
 * This module is a deterministic ray stepper. It will take in a ray
 * (a position and a direction) and an AABB then return the position
 * along the ray where it just exits the bounding box.
 */

/* verilator lint_off UNUSED */
module RayStepper #(
    parameter WIDTH=16
    )(
    input clock,
    input reset,

    // resets and starts new operation
    input start,
    // q and v are commited at start
    input [WIDTH-1:0] q [2:0],
    input [WIDTH-1:0] v [2:0],
    // l and u must be held constant during the operation
    input [WIDTH-1:0] l [2:0],
    input [WIDTH-1:0] u [2:0],

    output logic outOfBounds,
    output logic done,
    output logic [WIDTH-1:0] vp [2:0]
    );
    
    assign outOfBounds = 0;
    assign done = 0;
    assign vp[0] = 0;
    assign vp[1] = 0;
    assign vp[2] = 0;

endmodule: RayStepper
/* verilator lint_on UNUSED */
