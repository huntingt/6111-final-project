/*
 * Module for generating camera rays and driving the
 * ray units.
 */
module RayGenerator #(
    parameter POSITION_WIDTH=16,
    parameter ADDRESS_WIDTH=32
    )(
    input logic clock,
    input logic reset,

    input logic start,
    output logic busy,
    output logic ready,
    input logic normalize,

    input logic signed [POSITION_WIDTH-1:0] cameraV [2:0],
    input logic signed [POSITION_WIDTH-1:0] cameraX [2:0],
    input logic signed [POSITION_WIDTH-1:0] cameraY [2:0],
    
    input logic [11:0] width,
    input logic [11:0] height,

    // address of the start of the frame
    input logic [ADDRESS_WIDTH-1:0] frameAddress,

    // output to ray units
    output logic [POSITION_WIDTH-1:0] rayV [2:0],
    output logic [ADDRESS_WIDTH-1:0] rayAddress,
    output logic rayStart,
    input logic rayReady,
    input logic rayBusy
    );
    
    enum logic {
        IDLE,
        GENERATING
    } state;

    logic [11:0] nextX;
    logic [11:0] nextY;

    logic signed [POSITION_WIDTH-1:0] genV [2:0];
    logic signed [POSITION_WIDTH-1:0] regenV [2:0];
    
    logic [11:0] x [9:0];
    logic [11:0] y [9:0];
    logic valid [10:0];
    logic anyBusy [9:0];
    
    logic advance;
    
    // leading zero pairs
    logic [3:0] lzp [7:0];
    logic [3:0] lza [7:0];
    logic [3:0] toShift;

    logic h [7:0];
    logic l [7:0];

    logic signed [31:0] norm2;
    logic signed [31:0] y0, y1, y2;
    logic signed [31:0] y0_norm2, y1_norm2;
    logic signed [31:0] ny0, ny1;
    logic signed [31:0] ny0_y0, ny1_y1;
    logic signed [31:0] ny0_norm2;
    logic signed [31:0] nyy0, nyy1;
    logic signed [31:0] nyy0_y0, nyy1_y1;
    logic signed [31:0] nyy0_norm2;

    always_comb begin
        nextX = x[0] + 1;
        nextY = y[0] + 1;
        
        for (int i = 0; i < 8; i++) begin
            h[i] = norm2[15 - 2*i];
            l[i] = norm2[14 - 2*i];
        end

        // zero counting
        for (int i = 0; i < 8; i++) begin
            lzp[i] = {2'b0, !h[i] & !l[i], !h[i] & l[i]};
        end
        
        lza[7] = lzp[7];
        for (int i = 6; i >= 0; i--) begin
            lza[i] = lzp[i] == 2 ? lzp[i] + lza[i+1] : lzp[i];
        end
        toShift = (lza[0] + 1)>>1;

        advance = rayReady;
        rayStart = valid[10];
        
        anyBusy[9] = rayStart;
        for (int i = 0; i < 9; i++) begin
            anyBusy[i] = valid[i] || anyBusy[i + 1];
        end
        busy = anyBusy[0] || rayBusy || state != IDLE ;
        ready = state == IDLE;
    end

    // normalization pipeline
    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;          
        end else if (state == IDLE) begin
            if (start) begin
                state <= GENERATING;
                x[0] <= 0;
                y[0] <= 0;
                valid[0] <= 1;
            end
        end else if (state == GENERATING) begin
            if (advance) begin
                if (nextX < width) begin
                    x[0] <= nextX;
                end else if (nextY < height) begin
                    y[0] <= nextY;
                    x[0] <= 0;
                end else begin
                    state <= IDLE;
                    valid[0] <= 0;
                end
            end
        end
    
        if (advance || reset) begin
            for (int i = 0; i < 9; i++) begin
                x[i + 1] <= x[i];
                y[i + 1] <= y[i];
            end
            for (int i = 0; i < 10; i++) begin
                valid[i + 1] <= reset ? 0 : valid[i];
            end

            // (0) 0. find vector (not carried forth)
            for (int i = 0; i < 3; i++) begin
                genV[i] <= 16'(cameraX[i] * signed'(x[0] -  width/2))
                         + 16'(cameraY[i] * signed'(height/2 - y[0]))
                         + cameraV[i];
            end
            
            // (1) 1. calculate norm
            norm2 <= (genV[0]*genV[0]
                    + genV[1]*genV[1]
                    + genV[2]*genV[2]) >> 16;

            // (2) 2. find guess
            y0 <= 1 << 5'(toShift);
            
            y0_norm2 <= norm2;

            // (3) 3.1 mult step 1
            ny0 <= y0_norm2 * y0;
            
            ny0_y0 <= y0;
            ny0_norm2 <= y0_norm2;
            
            // (4) 3.2 mult step 2 and subtraction
            nyy0 <= (3<<16) - (ny0 * ny0_y0);
            
            nyy0_y0 <= ny0_y0;
            nyy0_norm2 <= ny0_norm2;
            
            // (5) 3.3 mult step 3 and drop lower
            y1 <= (nyy0_y0 * nyy0 >> 17);
            
            y1_norm2 <= nyy0_norm2;
            
            // (6) 4.1
            ny1 <= y1_norm2 * y1;

            ny1_y1 <= y1;
            
            // (7) 4.2
            nyy1 <= (3<<16) - (ny1 * ny1_y1);

            nyy1_y1 <= ny1_y1;
            
            // (8) 4.3
            y2 <= (nyy1_y1 * nyy1 >> 17);

            for (int i = 0; i < 3; i++) begin
                regenV[i] <= 16'(cameraX[i] * signed'(x[8] -  width/2))
                           + 16'(cameraY[i] * signed'(height/2 - y[8]))
                           + cameraV[i];
            end

            // (9) regenerate ray
            for (int i = 0; i < 3; i++) begin
                rayV[i] <= normalize ? 16'(y2 * regenV[i] * 15 / 16) : regenV[i];
            end
            rayAddress <= ADDRESS_WIDTH'(x[9]) + y[9]*width + frameAddress;
        end
    end

    if (0) begin
        always_ff @(posedge clock) begin
            $display("state: %d, advance: %b", state, advance);
            for (int i = 0; i < 10; i++) begin
                $display("%d = x: %d, y: %d, valid: %d", i, x[i], y[i], valid[i]);
            end
            $display("(2) y0: %d, norm2: %d, lza: %d", y0, y0_norm2, lza[0]);
            $display("(2.lz) a: {%d, %d, %d, %d, %d, %d, %d, %d}, p: {%d, %d, %d, %d, %d, %d, %d, %d}",
                lza[0], lza[1], lza[2], lza[3], lza[4], lza[5], lza[6], lza[7],
                lzp[0], lzp[1], lzp[2], lzp[3], lzp[4], lzp[5], lzp[6], lzp[7]);
            $display("(2.hl) h: {%d, %d, %d, %d, %d, %d, %d, %d}, l: {%d, %d, %d, %d, %d, %d, %d, %d}",
                h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7],
                l[0], l[1], l[2], l[3], l[4], l[5], l[6], l[7]);
            $display("(3) ny0: %d, y0: %d, norm2: %d", ny0, ny0_y0, ny0_norm2);
            $display("(4) nyy0: %d, y0: %d, norm2: %d", nyy0, nyy0_y0, nyy0_norm2);
            $display("(5) y1: %d, norm2: %d", y1, y1_norm2);
            $display("(6) ny1: %d, y1: %d", ny1, ny1_y1);
            $display("(7) nyy1: %d, y1: %d", nyy1, nyy1_y1);
            $display("(8) y2: %d, regenV: {%d, %d, %d}",
                y2, regenV[0], regenV[1], regenV[2]);
            $display("(9) valid: %d, rayV: {%d, %d, %d}, address: %d\n",
                valid[10], rayV[0], rayV[1], rayV[2], rayAddress);
        end
    end

endmodule: RayGenerator
