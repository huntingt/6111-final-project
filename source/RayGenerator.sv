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

    input logic signed [POSITION_WIDTH-1:0] cameraV [2:0],
    input logic signed [POSITION_WIDTH-1:0] cameraX [2:0],
    input logic signed [POSITION_WIDTH-1:0] cameraY [2:0],
    
    input logic [11:0] width,
    input logic [11:0] height,

    // address of the start of the frame
    input logic [ADDRESS_WIDTH-1:0] frameAddress,

    // output to ray units
    output logic signed [POSITION_WIDTH-1:0] rayV [2:0],
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
    logic valid [9:0];
    
    logic advanace;
    
    // leading zero pairs
    logic [2:0] lzp [3:0];
    logic [2:0] lza [3:0];

    logic h [3:0];
    logic l [3:0];

    logic [31:0] norm2;
    logic [31:0] y0, y1;
    logic [31:0] y0_norm2, y1_norm2;
    logic [31:0] ny0, ny1;
    logic [31:0] ny0_y0, ny1_y1;
    logic [31:0] ny0_norm2;
    logic [31:0] nyy0, nyy1;
    logic [31:0] nyy0_y0, nyy1_y0;
    logic [31:0] nyy0_norm2;

    always_comb begin
        nextX = x[0] + 1;
        nextY = y[0] + 1;
        
        for (int i = 0; i < 4; i++) begin
            h[i] = norm2[31 - 2*i];
            l[i] = norm2[30 - 2*i];
        end

        // zero counting
        for (int i = 0; i < 4; i++) begin
            lzp[i] = {0, !h[i] & !l[i], !h[i] & l[i]};
        end
        
        lza[3] = lzp[3];
        for (int i = 0; i < 3; i++) begin
            lza[i] = lzp[i][1] ? lzp[i] + lza[i+1] : lzp[i];
        end

        advance = rayReady;
        rayStart = valid[9];
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
            end
        end else if (state == GENERATING) begin
            if (advance) begin
                if (nextX < width) begin
                    x[0] <= nextX
                end else if (nextY < height) begin
                    y[0] <= nextY;
                    x[0] <= 0;
                end else begin
                    state <= IDLE;
                end
            end
        end
    
        if (advance || reset) begin
            for (int i = 0; i < 9; i++) begin
                x[i + 1] <= x[i];
                y[i + 1] <= y[i];
                valid[i + 1] <= reset ? 0 : valid[i];
            end

            // (0) 0. find vector (not carried forth)
            for (int i = 0; i < 3; i++) begin
                genV[i] <= cameraX[i] * signed'(x[0] -  width/2)
                         + cameraY[i] * signed'(height/2 - y[0])
                         + cameraV[i];
            end
            
            // (1) 1. calculate norm
            norm2 <= (genV[0]*genV[0]
                    + genV[1]*genV[1]
                    + genV[2]*genV[2]) >> 16;

            // (2) 2. find guess
            y0 <= 1 << 16 + (lza[i]>>1);
            
            y0_norm2 <= norm2;

            // (3) 3.1 mult step 1
            ny0 <= y0_norm2 * y0 >> 16;
            
            ny0_y0 <= y0;
            ny0_norm2 <= y0_norm2;
            
            // (4) 3.2 mult step 2 and subtraction
            nyy0 <= (3<<32) - ny0 * ny0_y0;
            
            nyy0_y0 <= ny0_y0;
            nyy0_norm2 <= ny0_norm2;
            
            // (5) 3.3 mult step 3 and drop lower
            y1 <= nyy0_y0 * nyy0 >> 33;
            
            y1_norm2 <= nyy0_norm2;
            
            // (6) 4.1
            ny1 <= y1_norm2 * y1 >> 16;

            ny1_y1 <= y1;
            
            // (7) 4.2
            nyy1 <= (3<<32) - ny1 * ny1_y1;

            nyy1_y1 <= ny1_y1;
            
            // (8) 4.3
            y2 <= nyy1_y1 * nyy1 >> 33;

            for (int i = 0; i < 3; i++) begin
                regenV[i] <= cameraX[i] * signed'(x[8] -  width/2)
                           + cameraY[i] * signed'(height/2 - y[8])
                           + cameraV[i];
            end

            // (9) regenerate ray
            for (int i = 0; i < 3; i++) begin
                rayV[i] <= y2 * regenV[i] * 7 >> 3;
            end
            rayAddress <= x[9] + y[9]*width + frameAddress;
        end
    end

endmodule: RayGenerator
