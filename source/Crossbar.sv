`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2019 08:56:18 PM
// Design Name: 
// Module Name: Crossbar
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Crossbar #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=24
    )(
    input clk,
    input rst,
    MemoryBus.Slave ray_m,
    MemoryBus.Slave ps,
    MemoryBus.Master ray_s,
    MemoryBus.Master bram,
    MemoryBus.Master dram
    );
    Crossbar_MS ms(.clk(clk), .rst(rst), .ray_m(ray_m), .ps(ps), .ray_s(ray_s), .bram(bram), .dram(dram));
    Crossbar_SM sm(.clk(clk), .rst(rst), .ray_m(ray_m), .ps(ps), .ray_s(ray_s), .bram(bram), .dram(dram));
endmodule

module Crossbar_MS #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=24
    )(
    input clk,
    input rst,
    MemoryBus.Slave ray_m,
    MemoryBus.Slave ps,
    MemoryBus.Master ray_s,
    MemoryBus.Master bram,
    MemoryBus.Master dram
    );
    
    localparam RAY_S_BASE = 32'h0;
    localparam BRAM_BASE = 32'h11;
    localparam DRAM_BASE = 32'h80;
    
    logic ray_m_ray_s;
    assign ray_m_ray_s = ray_m.msAddress < BRAM_BASE;
    logic ps_ray_s;
    assign ps_ray_s = ps.msAddress < BRAM_BASE;
    
    logic ray_m_bram;
    assign ray_m_bram = ray_m.msAddress < DRAM_BASE && ray_m.msAddress >= BRAM_BASE;
    logic ps_bram;
    assign ps_bram = ps.msAddress < DRAM_BASE && ps.msAddress >= BRAM_BASE;
    
    logic ray_m_dram;
    assign ray_m_dram = ray_m.msAddress >= DRAM_BASE;
    logic ps_dram;
    assign ps_dram = ps.msAddress >= DRAM_BASE;
    
    
    logic ray_s_lru;
    logic bram_lru;
    logic dram_lru;
    logic[1:0] ray_s_state;
    logic[1:0] bram_state;
    logic[1:0] dram_state;
    localparam INACTIVE = 2'b00;
    localparam PASS_RAY_M = 2'b10;
    localparam PASS_PS = 2'b11;
    localparam LRU_RAY_M = 1'b0;
    localparam LRU_PS = 1'b1;
    
    always_comb begin
        //ray_s   
        if (ray_m.msValid && ray_m_ray_s && !(ps.msValid && ps_ray_s)) begin
        //pass from ray_m to ray_s
            ray_s.msID = ray_m.msID;
            ray_s.msAddress = ray_m.msAddress - RAY_S_BASE;
            ray_s.msData = ray_m.msData;
            ray_s.msWrite = ray_m.msWrite;
            ray_s.msValid = ray_m.msValid;
            ray_m.msTaken = ray_s.msTaken;
            if (ps_ray_s) begin
                ps.msTaken = 0;
            end
            ray_s_state = PASS_RAY_M;
            //TODO: what to do about ps taken?
        end else if (!(ray_m.msValid && ray_m_ray_s) && ps.msValid && ps_ray_s) begin
        //pass from ps to ray_s
            ray_s.msID = ps.msID;
            ray_s.msAddress = ps.msAddress - RAY_S_BASE;
            ray_s.msData = ps.msData;
            ray_s.msWrite = ps.msWrite;
            ray_s.msValid = ps.msValid;
            ps.msTaken = ray_s.msTaken;
            if (ray_m_ray_s) begin
                ray_m.msTaken = 0;
            end
            ray_s_state = PASS_PS;
        end else if (ray_m.msValid && ray_m_ray_s && ps.msValid && ps_ray_s) begin
            if (ray_s_lru == LRU_RAY_M) begin
            //pass from ray_m to ray_s
                ray_s.msID = ray_m.msID;
                ray_s.msAddress = ray_m.msAddress - RAY_S_BASE;
                ray_s.msData = ray_m.msData;
                ray_s.msWrite = ray_m.msWrite;
                ray_s.msValid = ray_m.msValid;
                ray_m.msTaken = ray_s.msTaken;
                ps.msTaken = 0;
                ray_s_state = PASS_RAY_M;
            end else begin
                ray_s.msID = ps.msID;
                ray_s.msAddress = ps.msAddress - RAY_S_BASE;
                ray_s.msData = ps.msData;
                ray_s.msWrite = ps.msWrite;
                ray_s.msValid = ps.msValid;
                ps.msTaken = ray_s.msTaken;
                ray_m.msTaken = 0;
                ray_s_state = PASS_PS;
            end
        end else begin
            ray_s.msValid = 0;
            ray_s_state = INACTIVE;
            if (ps_ray_s) begin
                ps.msTaken = 0;
            end
            if (ray_m_ray_s) begin
                ray_m.msTaken = 0;
            end
        end
        
        //bram
        if (ray_m.msValid && ray_m_bram && !(ps.msValid && ps_bram)) begin
        //pass from ray_m to bram
            bram.msID = ray_m.msID;
            bram.msAddress = ray_m.msAddress - BRAM_BASE;
            bram.msData = ray_m.msData;
            bram.msWrite = ray_m.msWrite;
            bram.msValid = ray_m.msValid;
            ray_m.msTaken = bram.msTaken;
            if (ps_bram) begin
                ps.msTaken = 0;
            end
            bram_state = PASS_RAY_M;
        end else if (!(ray_m.msValid && ray_m_bram) && ps.msValid && ps_bram) begin
        //pass from ps to bram
            bram.msID = ps.msID;
            bram.msAddress = ps.msAddress - BRAM_BASE;
            bram.msData = ps.msData;
            bram.msWrite = ps.msWrite;
            bram.msValid = ps.msValid;
            ps.msTaken = bram.msTaken;
            if (ray_m_bram) begin
                ray_m.msTaken = 0;
            end
            bram_state = PASS_PS;
        end else if (ray_m.msValid && ray_m_bram && ps.msValid && ps_bram) begin
            if (bram_lru == LRU_RAY_M) begin
            //pass from ray_m to bram
                bram.msID = ray_m.msID;
                bram.msAddress = ray_m.msAddress - BRAM_BASE;
                bram.msData = ray_m.msData;
                bram.msWrite = ray_m.msWrite;
                bram.msValid = ray_m.msValid;
                ray_m.msTaken = bram.msTaken;
                ps.msTaken = 0;
                bram_state = PASS_RAY_M;
            end else begin
                bram.msID = ps.msID;
                bram.msAddress = ps.msAddress - BRAM_BASE;
                bram.msData = ps.msData;
                bram.msWrite = ps.msWrite;
                bram.msValid = ps.msValid;
                ps.msTaken = bram.msTaken;
                ray_m.msTaken = 0;
                bram_state = PASS_PS;
            end
        end else begin
            bram.msValid = 0;
            bram_state = INACTIVE;
            if (ps_bram) begin
                ps.msTaken = 0;
            end
            if (ray_m_bram) begin
                ray_m.msTaken = 0;
            end
        end
        
        //dram
        if (ray_m.msValid && ray_m_dram && !(ps.msValid && ps_dram)) begin
        //pass from ray_m to dram
            dram.msID = ray_m.msID;
            dram.msAddress = ray_m.msAddress;
            dram.msData = ray_m.msData;
            dram.msWrite = ray_m.msWrite;
            dram.msValid = ray_m.msValid;
            ray_m.msTaken = dram.msTaken;
            if (ps_dram) begin
                ps.msTaken = 0;
            end
            dram_state = PASS_RAY_M;
        end else if (!(ray_m.msValid && ray_m_dram) && ps.msValid && ps_dram) begin
        //pass from ps to dram
            dram.msID = ps.msID;
            dram.msAddress = ps.msAddress;
            dram.msData = ps.msData;
            dram.msWrite = ps.msWrite;
            dram.msValid = ps.msValid;
            ps.msTaken = dram.msTaken;
            if (ray_m_dram) begin
                ray_m.msTaken = 0;
            end
            dram_state = PASS_PS;
        end else if (ray_m.msValid && ray_m_dram && ps.msValid && ps_dram) begin
            if (dram_lru == LRU_RAY_M) begin
            //pass from ray_m to dram
                dram.msID = ray_m.msID;
                dram.msAddress = ray_m.msAddress;
                dram.msData = ray_m.msData;
                dram.msWrite = ray_m.msWrite;
                dram.msValid = ray_m.msValid;
                ray_m.msTaken = dram.msTaken;
                ps.msTaken = 0;
                dram_state = PASS_RAY_M;
            end else begin
                dram.msID = ps.msID;
                dram.msAddress = ps.msAddress;
                dram.msData = ps.msData;
                dram.msWrite = ps.msWrite;
                dram.msValid = ps.msValid;
                ps.msTaken = dram.msTaken;
                ray_m.msTaken = 0;
                dram_state = PASS_PS;
            end
        end else begin
            dram.msValid = 0;
            dram_state = INACTIVE;
            if (ps_dram) begin
                ps.msTaken = 0;
            end
            if (ray_m_dram) begin
                ray_m.msTaken = 0;
            end
        end
    end
    always_ff @ (posedge clk) begin
        if (rst) begin
            ray_s_lru <= LRU_PS;
            bram_lru <= LRU_PS;
            dram_lru <= LRU_PS;
        end else begin
            if (ray_s_state == PASS_RAY_M && ray_m.msTaken) begin
                ray_s_lru <= LRU_PS;
            end else if (ray_s_state == PASS_PS && ps.msTaken) begin
                ray_s_lru <= LRU_RAY_M;
            end
            if (bram_state == PASS_RAY_M && ray_m.msTaken) begin
                bram_lru <= LRU_PS;
            end else if (bram_state == PASS_PS && ps.msTaken) begin
                bram_lru <= LRU_RAY_M;
            end
            if (dram_state == PASS_RAY_M && ray_m.msTaken) begin
                dram_lru <= LRU_PS;
            end else if (dram_state == PASS_PS && ps.msTaken) begin
                dram_lru <= LRU_RAY_M;
            end
        end
    end
endmodule

module Crossbar_SM #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=24
    )(
    input clk,
    input rst,
    MemoryBus.Slave ray_m,
    MemoryBus.Slave ps,
    MemoryBus.Master ray_s,
    MemoryBus.Master bram,
    MemoryBus.Master dram
    );
    
    logic [1:0] state;
    logic [1:0] mru;
    
    localparam INACTIVE = 2'b00;
    localparam PASS_RAY_S = 2'b01;
    localparam PASS_BRAM = 2'b10;
    localparam PASS_DRAM = 2'b11;
    
    localparam MRU_RAY_S = 2'b00;
    localparam MRU_BRAM = 2'b01;
    localparam MRU_DRAM = 2'b10;
    
    always_comb begin
        if (mru == MRU_RAY_S) begin
            // check bram then dram then ray s
            if (bram.smValid) begin
                ray_m.smID = bram.smID;
                ray_m.smData = bram.smData;
                ray_m.smValid = bram.smValid;
                                
                ps.smID = bram.smID;
                ps.smData = bram.smData;
                ps.smValid = bram.smValid;
                                
                bram.smTaken = ray_m.smTaken || ps.smTaken;
                dram.smTaken = 0;
                ray_s.smTaken = 0;
                state = PASS_BRAM;
            end else if (dram.smValid) begin
                ray_m.smID = dram.smID;
                ray_m.smData = dram.smData;
                ray_m.smValid = dram.smValid;
                                
                ps.smID = dram.smID;
                ps.smData = dram.smData;
                ps.smValid = dram.smValid;
                                
                dram.smTaken = ray_m.smTaken || ps.smTaken;
                bram.smTaken = 0;
                ray_s.smTaken = 0;
                state = PASS_DRAM;
            end else if (ray_s.smValid) begin
                ray_m.smID = ray_s.smID;
                ray_m.smData = ray_s.smData;
                ray_m.smValid = ray_s.smValid;
                                
                ps.smID = ray_s.smID;
                ps.smData = ray_s.smData;
                ps.smValid = ray_s.smValid;
                               
                ray_s.smTaken = ray_m.smTaken || ps.smTaken;
                dram.smTaken = 0;
                bram.smTaken = 0;
                state = PASS_RAY_S;
            end else begin
                ray_m.smValid = 0;
                ps.smValid = 0;
                state = INACTIVE;
            end
        end else if (mru == MRU_BRAM) begin
            // check dram then ray s then bram
            if (dram.smValid) begin
                ray_m.smID = dram.smID;
                ray_m.smData = dram.smData;
                ray_m.smValid = dram.smValid;
                                
                ps.smID = dram.smID;
                ps.smData = dram.smData;
                ps.smValid = dram.smValid;
                                
                dram.smTaken = ray_m.smTaken || ps.smTaken;
                bram.smTaken = 0;
                ray_s.smTaken = 0;
                state = PASS_DRAM;
            end else if (ray_s.smValid) begin
                ray_m.smID = ray_s.smID;
                ray_m.smData = ray_s.smData;
                ray_m.smValid = ray_s.smValid;
                                
                ps.smID = ray_s.smID;
                ps.smData = ray_s.smData;
                ps.smValid = ray_s.smValid;
                                
                ray_s.smTaken = ray_m.smTaken || ps.smTaken;
                dram.smTaken = 0;
                bram.smTaken = 0;
                state = PASS_RAY_S;
            end else if (bram.smValid) begin
                ray_m.smID = bram.smID;
                ray_m.smData = bram.smData;
                ray_m.smValid = bram.smValid;
                                
                ps.smID = bram.smID;
                ps.smData = bram.smData;
                ps.smValid = bram.smValid;
                                
                bram.smTaken = ray_m.smTaken || ps.smTaken;
                dram.smTaken = 0;
                ray_s.smTaken = 0;
                state = PASS_BRAM;
            end else begin
                ray_m.smValid = 0;
                ps.smValid = 0;
                state = INACTIVE;
            end
        end else if (mru == MRU_DRAM) begin
            // check ray s then bram then dram
            if (ray_s.smValid) begin
                ray_m.smID = ray_s.smID;
                ray_m.smData = ray_s.smData;
                ray_m.smValid = ray_s.smValid;
                
                ps.smID = ray_s.smID;
                ps.smData = ray_s.smData;
                ps.smValid = ray_s.smValid;
                                
                ray_s.smTaken = ray_m.smTaken || ps.smTaken;
                dram.smTaken = 0;
                bram.smTaken = 0;
                state = PASS_RAY_S;
            end else if (bram.smValid) begin
                ray_m.smID = bram.smID;
                ray_m.smData = bram.smData;
                ray_m.smValid = bram.smValid;
                           
                ps.smID = bram.smID;
                ps.smData = bram.smData;
                ps.smValid = bram.smValid;
                
                bram.smTaken = ray_m.smTaken || ps.smTaken;
                dram.smTaken = 0;
                ray_s.smTaken = 0;
                state = PASS_BRAM;
            end else if (dram.smValid) begin
                ray_m.smID = dram.smID;
                ray_m.smData = dram.smData;
                ray_m.smValid = dram.smValid;
                
                ps.smID = dram.smID;
                ps.smData = dram.smData;
                ps.smValid = dram.smValid;
                
                dram.smTaken = ray_m.smTaken || ps.smTaken;
                bram.smTaken = 0;
                ray_s.smTaken = 0;
                state = PASS_DRAM;
            end else begin
                ray_m.smValid = 0;
                ps.smValid = 0;
                state = INACTIVE;
            end
        end
    end
    
    always_ff @ (posedge clk) begin
        if (rst) begin
            state <= INACTIVE;
            mru <= MRU_RAY_S;
        end
        if (state == PASS_RAY_S && ray_s.smTaken) begin
            mru <= MRU_RAY_S;
        end else if (state == PASS_BRAM && bram.smTaken) begin
            mru <= MRU_BRAM;
        end else if (state == PASS_DRAM && dram.smTaken) begin
            mru <= MRU_DRAM;
        end
    end
    
endmodule
