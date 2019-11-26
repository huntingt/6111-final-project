module HPStimulator(
    input logic clock,
    input logic reset,

    input logic [31:0] in,
    output logic [31:0] out,

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

    enum logic [7:0] {
        DATA,
        ADDRESS,
        CACHE,
        PROTECTION,
        ID,
        WRITE,
        SEND,
        GET_READY,
        GET_DATA,
        GET_WRITE,
        GET_VALID,
        GET_RESPONSE,
        GET_ID,
        GET_LAST,
        CLEAR
    } command;
    logic [23:0] field;

    logic [31:0] data;
    logic [31:0] address;
    logic [3:0] cache;
    logic [2:0] protection;
    logic [5:0] id;

    logic write;
    logic valid;

    logic ready;

    always_comb begin
        command = in[31:24];
        field = in[23:0];

        ready = write ? (wready && awready) : arready;

        case (command)
            GET_READY: out = {29'b0, awready, arready, wready};
            GET_DATA: out = rx_data;
            GET_WRITE: out = 32'(rx_write);
            GET_VALID: out = 32'(rx_valid);
            GET_RESPONSE: out = 32'(rx_response);
            GET_ID: out = 32'(rx_id);
            GET_LAST: out = 32'(rx_last);
            default: out = 32'hXXXXXXXX;
        endcase
    end

    always_ff @(posedge clock) begin
        case (command)
            DATA: data <= {field, 8'b0};
            ADDRESS: address <= {field, 8'b0};
            CACHE: cache <= field[3:0];
            PROTECTION: protection <= field[2:0];
            ID: id <= field[5:0];
            WRITE: write <= field[0];
            default: ;
        endcase
    end

    logic [1:0] rx_response;
    logic [31:0] rx_data;
    logic rx_write;
    logic rx_valid;
    logic [5:0] rx_id;
    logic rx_last;

    logic rx_write_ready;
    logic rx_read_ready;
    logic rx_write_valid;
    logic rx_read_valid;

    always_comb begin
        rx_write_valid = bvalid;
        rx_read_valid = rvalid;

        rx_write_ready = !rx_valid;
        rx_read_ready = !rx_valid && !rx_write_valid;
    
        ready = arready && awready && wready;
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            rx_valid <= 0;
            valid <= 0;
        end else begin
            // recieve logic
            if (rx_valid) begin
                if (command == CLEAR) begin
                    rx_valid <= 0;
                end
            end else if (rx_write_ready && rx_write_valid) begin
                rx_write <= 1;
                rx_valid <= 1;
                rx_response <= bresp;
                rx_id <= bid;
            end else if (rx_read_ready && rx_read_valid) begin
                rx_write <= 0;
                rx_valid <= 1;
                rx_data <= rdata;
                rx_response <= rresp;
                rx_id <= rid;
                rx_last <= rlast;
            end

            // send logic
            if (valid && ready) begin
                valid <= 0;
            end else begin
                if (command == SEND) begin
                    valid <= 1;
                end else if (command == CLEAR) begin
                    valid <= 0;
                end
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

endmodule: HPStimulator
