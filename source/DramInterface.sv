module DramInterface(
    input logic clock,
    input logic reset,

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

    MemoryBus.Slave bus
    );

    logic [31:0] data;
    logic [31:0] address;
    logic [3:0] cache;
    logic [2:0] protection;
    logic [5:0] id;

    logic write;

    assign data = bus.msData;
    assign address = bus.msAddress;
    assign write = bus.msWrite;
    assign id = bus.msID[5:0];
    assign cache = 3;
    assign protection = 0;

    logic ready;
    logic valid;

    logic rx_write_ready;
    logic rx_read_ready;
    logic rx_write_valid;
    logic rx_read_valid;

    always_comb begin
        rx_write_valid = bvalid;
        rx_read_valid = rvalid;

        rx_write_ready = 1;
        rx_read_ready = !bus.smValid;
   
        valid = bus.msValid;
        ready = write ? awready && wready : arready;
        bus.msTaken = ready && valid;
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            bus.msValid <= 0;
        end else begin
            // recieve logic
            if (bus.smValid && bus.smTaken) begin
                bus.smValid <= 0;
            end else if (rx_read_ready && rx_read_valid) begin
                bus.smValid <= 1;
                bus.smData <= rdata;
                bus.smID <= rid;
            end
        end
    end

    always_comb begin
        arvalid = !write && valid;
        awvalid = write && valid;
        bready = rx_write_ready;
        rready = rx_read_ready;
        wlast = write && valid; // same as wvalid
        wvalid = write && valid;
        arburst = 0;
        arlock = 0;
        arsize = 'b010;
        awburst = 0;
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

endmodule: DramInterface
