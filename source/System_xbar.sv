`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2019 05:54:29 PM
// Design Name: 
// Module Name: System_xbar
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


module System_xbar(
    input logic clock,
    input logic reset,

    input logic [31:0] gpio_in,
    output logic [31:0] gpio_out,

    input logic arready,
    input logic awready,
    input logic bvalid,
    input logic rlast,
    input logic rvalid,
    input logic wready,
    input logic [1:0] bresp,
    input logic [1:0] rresp,
    input logic [5:0] bid,
    input logic [5:0] rid,
    input logic [31:0] rdata,
    
    output logic arvalid,
    output logic awvalid,
    output logic bready,
    output logic rready,
    output logic wlast,
    output logic wvalid,
    output logic [1:0] arburst,
    output logic [1:0] arlock,
    output logic [2:0] arsize,
    output logic [1:0] awburst,
    output logic [1:0] awlock,
    output logic [2:0] awsize,
    output logic [2:0] arprot,
    output logic [2:0] awprot,
    output logic [31:0] araddr,
    output logic [31:0] awaddr,
    output logic [3:0] arcache,
    output logic [3:0] arlen,
    output logic [3:0] arqos,
    output logic [3:0] awcache,
    output logic [3:0] awlen,
    output logic [3:0] awqos,
    output logic [5:0] arid,
    output logic [5:0] awid,
    output logic [5:0] wid,
    output logic [31:0] wdata,
    output logic [3:0] wstrb,
    
    input logic b_arready,
    input logic b_awready,
    input logic b_bvalid,
    input logic b_rvalid,
    input logic b_wready,
    input logic [1:0] b_bresp,
    input logic [1:0] b_rresp,
    input logic [31:0] b_rdata,
    
    output logic b_arvalid,
    output logic b_awvalid,
    output logic b_bready,
    output logic b_rready,
    output logic b_wvalid,
    output logic [2:0] b_arprot,
    output logic [2:0] b_awprot,
    output logic [31:0] b_araddr,
    output logic [31:0] b_awaddr,
    output logic [31:0] b_wdata,
    output logic [3:0] b_wstrb
    );
    MemoryBus#(
        .DATA_WIDTH(24),
        .ADDRESS_WIDTH(32),
        .MASTER_ID_WIDTH(8)
    ) ps();
    MemoryBus#(
        .DATA_WIDTH(24),
        .ADDRESS_WIDTH(32),
        .MASTER_ID_WIDTH(8)
    ) ray_m();
    MemoryBus#(
        .DATA_WIDTH(24),
        .ADDRESS_WIDTH(32),
        .MASTER_ID_WIDTH(8)
    ) ray_s();
    MemoryBus#(
        .DATA_WIDTH(24),
        .ADDRESS_WIDTH(32),
        .MASTER_ID_WIDTH(8)
    ) bram_bus();
    MemoryBus#(
        .DATA_WIDTH(24),
        .ADDRESS_WIDTH(32),
        .MASTER_ID_WIDTH(8)
    ) dram_bus();
    
    MemoryMaster mm(
        .clock(clock),
        .reset(reset),
        .in(gpio_in),
        .out(gpio_out),
        .bus(ps));
    Crossbar xbar (
        .clk(clock),
        .rst(reset),
        .ray_m(ray_m),
        .ps(ps),
        .ray_s(ray_s),
        .bram(bram_bus),
        .dram(dram_bus)
    );
    
    RayTracer#(
        .POSITION_WIDTH(16),
        .DATA_WIDTH(24),
        .ADDRESS_WIDTH(32),
        .CONFIG_ADDRESS(0),
        .MASTER_ID_BASE(10)
    ) rt(
        .clock(clock),
        .reset(reset),
        .configPort(ray_s),
        .memoryPort(ray_m)
    );
    
    BusToAxiLite bram(
    .clock(clock),
    .reset(reset),
    
    .bus(bram_bus),
    
    .arready(b_arready),
    .awready(b_awready),
    .bvalid(b_bvalid),
    .rvalid(b_rvalid),
    .wready(b_wready),
    .bresp(b_bresp),
    .rresp(b_rresp),
    .rdata(b_rdata),
    
    .arvalid(b_arvalid),
    .awvalid(b_awvalid),
    .bready(b_bready),
    .rready(b_rready),
    .wvalid(b_wvalid),
    .arprot(b_arprot),
    .awprot(b_awprot),
    .araddr(b_araddr),
    .awaddr(b_awaddr),
    .wdata(b_wdata),
    .wstrb(b_wstrb)
    );
    
    BusToAxi dram(
    .bus(dram_bus),
    
    .arready(arready),
    .awready(awready),
    .bvalid(bvalid),
    .rlast(rlast),
    .rvalid(rvalid),
    .wready(wready),
    .bresp(bresp),
    .rresp(rresp),
    .bid(bid),
    .rid(rid),
    .rdata(rdata),
    
    .arvalid(arvalid),
    .awvalid(awvalid),
    .bready(bready),
    .rready(rready),
    .wlast(wlast),
    .wvalid(wvalid),
    .arburst(arburst),
    .arlock(arlock),
    .arsize(arsize),
    .awburst(awburst),
    .awlock(awlock),
    .awsize(awsize),
    .arprot(arprot),
    .awprot(awprot),
    .araddr(araddr),
    .awaddr(awaddr),
    .arcache(arcache),
    .arlen(arlen),
    .arqos(arqos),
    .awcache(awcache),
    .awlen(awlen),
    .awqos(awqos),
    .arid(arid),
    .awid(awid),
    .wid(wid),
    .wdata(wdata),
    .wstrb(wstrb)
    );


endmodule
