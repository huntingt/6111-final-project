/*
 * Used to interface between out custom bus and a standard
 * 32 bit axi4 bus.
*/
module BusToAxi(
    MemoryBus.Slave bus,

    // axi32 master interface
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
    output logic [3:0] wstrb
    );

    // convert from axi to bus
    assign bus.smID = 8'(rid);
    assign bus.smData = rdata[23:0];
    assign bus.smValid = rvalid;
    logic rx_read_ready = bus.smTaken;

    // convert from bus to axi
    logic write = bus.msWrite;
    logic valid = bus.msValid;
    logic ready = write ? awready && wready : arready;
    assign bus.msTaken = valid && ready;

    logic [5:0] id = bus.msID[5:0];
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
        wlast = write && valid; // same as wvalid
        wvalid = write && valid;
        arburst = 2'b01;
        arlock = 0;
        arsize = 'b010;
        awburst = 2'b01;
        awlock = 0;
        awsize = 'b010;
        arprot = protection;
        awprot = protection;
        araddr = address;
        awaddr = address;
        arcache = cache;
        arlen = 0;
        arqos = 0;
        awcache = cache;
        awlen = 0; //burst length of 0
        awqos = 0;
        arid = id;
        awid = id;
        wid = id;
        wdata = data;
        wstrb = 4'b1111;
    end

endmodule: BusToAxi
