/*
 * This module is a deterministic ray stepper. It will take in a ray
 * (a position and a direction) and an AABB then return the position
 * along the ray where it just exits the bounding box.
 */

module RayStepper #(
    parameter WIDTH=16
    )(
    input clock,
    input reset,

    // resets and starts new operation
    // operation begins after start returns to 0
    input start,
    // q and v are latched when start is high
    // q is the initial position
    // v is the signed direction vector and must have a length
    // in (sqrt(3)/2, 1). This assumption allows faster searching
    input [WIDTH-1:0] q [2:0],
    input [WIDTH-1:0] v [2:0],
    // l and u must be held constant during the operation
    // l is the lower bound on each axis
    // u is the upper bound on each axis
    input [WIDTH-1:0] l [2:0],
    input [WIDTH-1:0] u [2:0],

    // indicates that the ray exited the maximum width
    output logic outOfBounds,
    output logic done,
    // gives the new position
    output logic [WIDTH-1:0] qp [2:0]
    );

    // extra bit allows outOfBounds detection
    logic [WIDTH:0] accumulator [2:0];
    // 2 extra bits to ensure that vector is large enough
    // 1 extra bit for to round up
    logic [WIDTH+2:0] step [2:0];

    logic [WIDTH+1:0] roundedStep [2:0];
    logic [WIDTH+1:0] proposedPosition [2:0];
    
    
    logic [WIDTH+1:0] lMinusOne [2:0];
    logic [WIDTH+1:0] uPlusOne [2:0];

    logic inAABB [2:0];
    logic onAABB [2:0];

    always_comb begin
        for (int i = 0; i < 3; i++) begin
            roundedStep[i] = step[i][WIDTH+2:1] + {{WIDTH{1'b0}}, 1'b0, step[i][0]};
            proposedPosition[i] = accumulator[i] + roundedStep[i];
            
            lMinusOne[i] = {2'b0, l[i]} - 1;
            uPlusOne[i]  = {2'b0, u[i]} + 1;

            inAABB[i] = signed'(lMinusOne[i]) <= signed'(proposedPosition[i])
                                         && proposedPosition[i] <= uPlusOne[i];
            onAABB[i] = lMinusOne[i] == proposedPosition[i]
                                         || proposedPosition[i] == uPlusOne[i];
            
            qp[i] = accumulator[i][WIDTH-1:0];
        end
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            done <= 1;
            outOfBounds <= 0;
        end else if (start) begin
            // load registers
            for (int i = 0; i < 3; i++) begin
                step[i] <= {v[i], 3'b0};
                accumulator[i] <= {1'b0, q[i]};
            end
            
            // start
            done <= 0;
        end else if (!done) begin
            //$display("on: %d, %d, %d", onAABB[0], onAABB[1], onAABB[2]);
            //$display("in: %d, %d, %d", inAABB[0], inAABB[1], inAABB[2]);
            //$display("lower: %d, %d, %d", l[0], l[1], l[2]);
            //$display("upper: %d, %d, %d", u[0], u[1], u[2]);
            //$display("working: %d, %d, %d", accumulator[0], accumulator[1], accumulator[2]);
            //$display("pos: %d, %d, %d", proposedPosition[0], proposedPosition[1], proposedPosition[2]);
            
            // commit changes if they fit
            if (inAABB[0] && inAABB[1] && inAABB[2]) begin
                for (int i = 0; i < 3; i++) begin
                    accumulator[i] <= proposedPosition[i][WIDTH:0];
                end
            end

            if (onAABB[0] || onAABB[1] || onAABB[2]) begin
                done <= 1;
                if (proposedPosition[0][WIDTH] ||
                    proposedPosition[1][WIDTH] ||
                    proposedPosition[2][WIDTH]) begin
                    outOfBounds <= 1;
                end
            end
            
            for (int i = 0; i < 3; i++) begin
                step[i] <= {step[i][WIDTH+2], step[i][WIDTH+2:1]};
            end
        end
    end

endmodule: RayStepper
