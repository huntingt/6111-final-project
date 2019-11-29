`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2019 02:26:41 PM
// Design Name: 
// Module Name: BinaryArbiter
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
module BinaryArbiter #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=24
    )(
    input clk,
    MemoryBus.Slave sbus0,
    MemoryBus.Slave sbus1,
    MemoryBus.Master mbus
    );
    BinaryArbiter_MS ms(.clk(clk), .sbus0(sbus0), .sbus1(sbus1), .mbus(mbus));
    BinaryArbiter_SM sm(.sbus0(sbus0), .sbus1(sbus1), .mbus(mbus));
endmodule

module BinaryArbiter_MS #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=24
    )(
    input clk,
    MemoryBus.Slave sbus0,
    MemoryBus.Slave sbus1,
    MemoryBus.Master mbus
    );
    logic lru;
    logic [1:0] state;
    localparam INACTIVE = 2'b00;
    localparam PASS_0 = 2'b10;
    localparam PASS_1 = 2'b11;
    always_comb begin
        if (sbus0.msValid && !sbus1.msValid) begin
            //pass from sbus0 to mbus
            mbus.msID = sbus0.msID;
            mbus.msAddress = sbus0.msAddress;
            mbus.msData = sbus0.msData;
            mbus.msWrite = sbus0.msWrite;
            mbus.msValid = sbus0.msValid;
            sbus0.msTaken = mbus.msTaken;
            sbus1.msTaken = 0;
            state = PASS_0;
        end else if (!sbus0.msValid && sbus1.msValid) begin
            //pass from sbus1 to mbux
            mbus.msID = sbus1.msID;
            mbus.msAddress = sbus1.msAddress;
            mbus.msData = sbus1.msData;
            mbus.msWrite = sbus1.msWrite;
            mbus.msValid = sbus1.msValid;
            sbus1.msTaken = mbus.msTaken;
            sbus0.msTaken = 0;
            state = PASS_1;
        end else if (sbus0.msValid && sbus1.msValid) begin
            // arbitrate
            if (!lru) begin
                //pass from sbus0 to mbus
                mbus.msID = sbus0.msID;
                mbus.msAddress = sbus0.msAddress;
                mbus.msData = sbus0.msData;
                mbus.msWrite = sbus0.msWrite;
                mbus.msValid = sbus0.msValid;
                sbus0.msTaken = mbus.msTaken;
                sbus1.msTaken = 0;
                state = PASS_0;
            end else begin
                //pass from sbus1 to mbux
                mbus.msID = sbus1.msID;
                mbus.msAddress = sbus1.msAddress;
                mbus.msData = sbus1.msData;
                mbus.msWrite = sbus1.msWrite;
                mbus.msValid = sbus1.msValid;
                sbus1.msTaken = mbus.msTaken;
                sbus0.msTaken = 0;
                state = PASS_1;
            end
        end else begin
            // not valid
            mbus.msValid = 0;
            sbus0.msTaken = 0;
            sbus1.msTaken = 0;
            state = INACTIVE;
        end
    end
    always_ff @ (posedge clk) begin
        if (state == PASS_0 && sbus0.msTaken) begin
            lru <= 1'b1;
        end else if (state == PASS_1 && sbus1.msTaken) begin
            lru <= 1'b0;
        end
    end
endmodule

module BinaryArbiter_SM #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=24
    )(
    input clk,
    MemoryBus.Slave sbus0,
    MemoryBus.Slave sbus1,
    MemoryBus.Master mbus
    );
    always_comb begin
        sbus0.smID = mbus.smID;
        sbus0.smData = mbus.smData;
        sbus0.smValid = mbus.smValid;
                
        sbus1.smID = mbus.smID;
        sbus1.smData = mbus.smData;
        sbus1.smValid = mbus.smValid;
                
        mbus.smTaken = sbus0.smTaken || sbus1.smTaken;
    end
endmodule
