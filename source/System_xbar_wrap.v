`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2019 06:07:02 PM
// Design Name: 
// Module Name: System_xbar_wrap
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


module System_xbar_wrap(
    input wire clock,
    input wire reset,

    input wire [31:0] gpio_in,
    output wire [31:0] gpio_out,

    input wire d_arready,
    input wire d_awready,
    input wire d_bvalid,
    input wire d_rlast,
    input wire d_rvalid,
    input wire d_wready,
    input wire [1:0] d_bresp,
    input wire [1:0] d_rresp,
    input wire [5:0] d_bid,
    input wire [5:0] d_rid,
    input wire [31:0] d_rdata,
    
    output wire d_arvalid,
    output wire d_awvalid,
    output wire d_bready,
    output wire d_rready,
    output wire d_wlast,
    output wire d_wvalid,
    output wire [1:0] d_arburst,
    output wire [1:0] d_arlock,
    output wire [2:0] d_arsize,
    output wire [1:0] d_awburst,
    output wire [1:0] d_awlock,
    output wire [2:0] d_awsize,
    output wire [2:0] d_arprot,
    output wire [2:0] d_awprot,
    output wire [31:0] d_araddr,
    output wire [31:0] d_awaddr,
    output wire [3:0] d_arcache,
    output wire [3:0] d_arlen,
    output wire [3:0] d_arqos,
    output wire [3:0] d_awcache,
    output wire [3:0] d_awlen,
    output wire [3:0] d_awqos,
    output wire [5:0] d_arid,
    output wire [5:0] d_awid,
    output wire [5:0] d_wid,
    output wire [31:0] d_wdata,
    output wire [3:0] d_wstrb,
    
    input wire b_arready,
    input wire b_awready,
    input wire b_bvalid,
    input wire b_rvalid,
    input wire b_wready,
    input wire [1:0] b_bresp,
    input wire [1:0] b_rresp,
    input wire [31:0] b_rdata,
    
    output wire b_arvalid,
    output wire b_awvalid,
    output wire b_bready,
    output wire b_rready,
    output wire b_wvalid,
    output wire [2:0] b_arprot,
    output wire [2:0] b_awprot,
    output wire [31:0] b_araddr,
    output wire [31:0] b_awaddr,
    output wire [31:0] b_wdata,
    output wire [3:0] b_wstrb
    );
    System_xbar dut(
    .clock(clock),
    .reset(reset),
    
    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    
    .arready(d_arready),
    .awready(d_awready),
    .bvalid(d_bvalid),
    .rlast(d_rlast),
    .rvalid(d_rvalid),
    .wready(d_wready),
    .bresp(d_bresp),
    .rresp(d_rresp),
    .bid(d_bid),
    .rid(d_rid),
    .rdata(d_rdata),
    
    .arvalid(d_arvalid),
    .awvalid(d_awvalid),
    .bready(d_bready),
    .rready(d_rready),
    .wlast(d_wlast),
    .wvalid(d_wvalid),
    .arburst(d_arburst),
    .arlock(d_arlock),
    .arsize(d_arsize),
    .awburst(d_awburst),
    .awlock(d_awlock),
    .awsize(d_awsize),
    .arprot(d_arprot),
    .awprot(d_awprot),
    .araddr(d_araddr),
    .awaddr(d_awaddr),
    .arcache(d_arcache),
    .arlen(d_arlen),
    .arqos(d_arqos),
    .awcache(d_awcache),
    .awlen(d_awlen),
    .awqos(d_awqos),
    .arid(d_arid),
    .awid(d_awid),
    .wid(d_wid),
    .wdata(d_wdata),
    .wstrb(d_wstrb),
    
    .b_arready(b_arready),
    .b_awready(b_awready),
    .b_bvalid(b_bvalid),
    .b_rvalid(b_rvalid),
    .b_wready(b_wready),
    .b_bresp(b_bresp),
    .b_rresp(b_rresp),
    .b_rdata(b_rdata),
    
    .b_arvalid(b_arvalid),
    .b_awvalid(b_awvalid),
    .b_bready(b_bready),
    .b_rready(b_rready),
    .b_wvalid(b_wvalid),
    .b_arprot(b_arprot),
    .b_awprot(b_awprot),
    .b_araddr(b_araddr),
    .b_awaddr(b_awaddr),
    .b_wdata(b_wdata),
    .b_wstrb(b_wstrb)
    );
endmodule
