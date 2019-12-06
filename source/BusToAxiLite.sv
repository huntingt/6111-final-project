`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2019 04:14:43 PM
// Design Name: 
// Module Name: BusToAxiLite
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


module BusToAxiLite(
    input logic clock,
    input logic reset,

    MemoryBus.Slave bus,

    // axi4lite master interface
    input logic arready,
    input logic awready,
    input logic bvalid,
    input logic rvalid,
    input logic wready,
    input logic [1:0] bresp,
    input logic [1:0] rresp,
    input logic [31:0] rdata,
    
    output logic arvalid,
    output logic awvalid,
    output logic bready,
    output logic rready,
    output logic wvalid,

    output logic [2:0] arprot,
    output logic [2:0] awprot,
    output logic [31:0] araddr,
    output logic [31:0] awaddr,


    output logic [31:0] wdata,
    output logic [3:0] wstrb
    );
    logic [5:0] id;
    // convert from axi to bus
    assign bus.smID = 8'(id);
    assign bus.smData = rdata[23:0];
    assign bus.smValid = rvalid;
    logic rx_read_ready = bus.smTaken;

    // convert from bus to axi
    logic write = bus.msWrite;
    logic valid = bus.msValid;
    logic ready = write ? awready && wready : arready;
    assign bus.msTaken = valid && ready;
    
    logic [31:0] data = 32'(bus.msData);
    logic [31:0] address = {bus.msAddress[29:0], 2'b0};

    // static settings
    logic rx_write_ready = 1;
    logic protection = 0;
    logic cache = 0;

    // populate all of the axi outputs
 always_comb begin
        arvalid = !write && valid;
        awvalid = write && valid;
        bready = rx_write_ready;
        rready = rx_read_ready;
        wvalid = write && valid;



        arprot = protection;
        awprot = protection;
        araddr = address;
        awaddr = address;


        wdata = data;
        wstrb = 4'b1111;
    end
    
 always_ff @ (posedge clock) begin
    if (reset) begin
        id <= 0;
    end else begin
        if (bus.msValid && !bus.msWrite && bus.msTaken) begin
            id <= bus.msID[5:0];
        end
    end
 end
endmodule
