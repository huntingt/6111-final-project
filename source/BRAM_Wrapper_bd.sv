`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2019 04:03:25 PM
// Design Name: 
// Module Name: BRAM_Wrapper
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


module BRAM_Wrapper_bd #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=24,
    parameter BRAM_ADDRESS_WIDTH=15,
    parameter BRAM_DATA_WIDTH=32
    )(
    input clk,
    input rst,
    MemoryBus.Slave bus,
    
    output logic[BRAM_ADDRESS_WIDTH-1:0] awaddr,
    output logic awvalid,
    input awready,
    output logic [BRAM_DATA_WIDTH-1:0] wdata,
    output logic wvalid,
    input wready,
    output logic[BRAM_ADDRESS_WIDTH-1:0] araddr,
    output logic arvalid,
    input arready,
    input [BRAM_DATA_WIDTH-1:0] rdata,
    input rvalid,
    output logic rready,
    output logic [2:0] awprot,
    output logic [2:0] arprot,
    output logic bready,
    output logic [3:0] wstrb,
    output logic rstb
    );
        
    logic[MASTER_ID_WIDTH-1:0] id_fifo[3:0];
    logic[1:0] fifo_count;
    logic msValid_prev;
    logic rvalid_prev;
//    bram_wrapper bram (
//    .S_AXI_0_araddr(araddr),
//    .S_AXI_0_arprot(arprot),
//    .S_AXI_0_arready(arready),
//    .S_AXI_0_arvalid(arvalid),
//    .S_AXI_0_awaddr(awaddr),
//    .S_AXI_0_awprot(awprot),
//    .S_AXI_0_awready(awready),
//    .S_AXI_0_awvalid(awvalid),
//    .S_AXI_0_bready(bready),
//    .S_AXI_0_bresp(),
//    .S_AXI_0_bvalid(),
//    .S_AXI_0_rdata(rdata),
//    .S_AXI_0_rready(rready),
//    .S_AXI_0_rresp(),
//    .S_AXI_0_rvalid(rvalid),
//    .S_AXI_0_wdata(wdata),
//    .S_AXI_0_wready(wready),
//    .S_AXI_0_wstrb(wstrb),
//    .S_AXI_0_wvalid(wvalid),
//    .rsta_busy_0(rsta_busy),
//    .s_axi_aclk_0(clk),
//    .s_axi_aresetn_0(!rst));
    
    assign rstb = !rst;
    
    assign arprot = 0;
    assign wstrb = 4'b1111;
    assign awprot = 0;
    assign bready = 1;
    
    assign awvalid = bus.msValid && bus.msWrite;
    assign wvalid = bus.msValid && bus.msWrite;
    assign awaddr = {bus.msAddress[BRAM_ADDRESS_WIDTH-3:0], 2'b0};
    assign wdata = {8'b0, bus.msData};

    assign arvalid = bus.msValid && (!bus.msWrite);
    assign araddr = {bus.msAddress[BRAM_ADDRESS_WIDTH-3:0], 2'b0};
    assign rready = bus.smTaken;
    
    assign bus.msTaken = bus.msWrite ? wready: arready;
    assign bus.smValid = rvalid;
    assign bus.smData = rdata[23:0];
    assign bus.smID = id_fifo[0];
    
    
    logic pushFifo;
    logic popFifo;
    assign pushFifo = bus.msValid && !bus.msWrite && bus.msTaken;
    assign popFifo = rvalid && bus.smTaken;
    
    always_ff @ (posedge clk) begin
        rvalid_prev <= rvalid;
        msValid_prev <= bus.msValid;
        if (rst) begin
            fifo_count <= 0;
            rvalid_prev <= 0;
            msValid_prev <= 0;
        end else begin
            if (pushFifo) begin
                if (popFifo) begin
                    bus.smID <= id_fifo[0];
                    for(integer i = 0; i < fifo_count; i = i+1) begin
                        id_fifo[i] <= id_fifo[i+1];
                    end
                    id_fifo[fifo_count] <= bus.msID;
                end else begin
                    id_fifo[fifo_count] <= bus.msID;
                    fifo_count <= fifo_count + 1;
                end 
            end else begin
                if (popFifo) begin
                    id_fifo[0] <= id_fifo[1];
                    id_fifo[1] <= id_fifo[2];
                    id_fifo[2] <= id_fifo[3];
                    fifo_count <= fifo_count - 1;
                end
            end
        end
    end
endmodule
