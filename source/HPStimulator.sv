/*
 * Used to provide simple axi commands as an axi master then inspect
 * the returned contents to test different axi settings. This module
 * may also be used as the base module for developing dma like modules
 * to acces the high performance dma ports on the fpga.
 */
module HPStimulator(
    input logic clock,
    input logic reset,

    // interface used to configure the module
    // command = gpio_in[31:24] - a command representing either
    //      some action to carry out or a field to get or set. Commands
    //      are listed in the commands enumeration
    // field = gpio_in[23:0] - field to set if a field is specified
    input logic [31:0] gpio_in,
    output logic [31:0] gpio_out,

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

    typedef enum logic [7:0] {
        // set the upper 24 bits of the data field used in writes with the
        // lower 8 bits set to 0
        DATA,

        // set either the lower 24 bits of the address field or the upper
        // 8 bits for both reads and writes
        ADDRESS_LOWER,
        ADDRESS_UPPER,

        // set the cache field for writes and reads
        // field[0]: bufferable - transaction can be delayed
        // field[1]: modifiable - transaction can be modified (ie. merged with
        //      others)
        // field[2]: read allocation
        // field[3]: write allocation
        CACHE,

        // set the protection field for writes and reads
        // field[0]: 1 - privileged access; 0 - unprivileged access
        // field[1]: 1 - non-secure access; 0 - secure access
        // field[2]: 1 - instruction access; 0 - data access
        PROTECTION,

        // set the id field field for writes and reads
        // field[5:0]: id
        ID,

        // set the write state
        // field[0]: 1 - write; 0 - read
        WRITE,

        // set the burst field
        BURST,

        // send a single transction with the specified fields
        //
        // in order to send a second transaction, a different command
        // value musts be selected or the module reset
        SEND,

        // check if the transaction is ready to send
        // gpio_out[0]: read address channel ready
        // gpio_out[1]: write data channel ready
        // gpio_out[2]: write address channel ready
        GET_READY,

        // check the response data for reads
        // gpio_out: data
        GET_DATA,

        // check if the response is for a read or write
        // gpio_out: write - 1; read - 0
        GET_WRITE,

        // check if there is a valid response
        // gpio_out: valid - 1; invalid - 0
        GET_VALID,

        // check the response field for both reads and writes
        // gpio_out: response
        GET_RESPONSE,

        // check the id field
        // gpio_out: id
        GET_ID,

        // check the last signal for the transaction
        // gpio_out[0]: last
        //
        // this signal should always be 1 for valid responses
        GET_LAST,

        // clear the buffered response to allow a new response
        CLEAR
    } Command;

    // module input
    Command command;
    logic [23:0] field;

    // used to send only one transaction at a time
    logic waitSend;

    // send fields
    logic [31:0] data;
    logic [31:0] address;
    logic [3:0] cache;
    logic [1:0] burst;
    logic [2:0] protection;
    logic [5:0] id;
    logic write;

    // represents whether or not the current field contains valid
    // data
    logic valid;

    // helper used to merge the transmition handshakes into a single
    // handshake
    logic ready;
    
    // recieved fields
    logic [1:0] rx_response;
    logic [31:0] rx_data;
    logic rx_write;
    logic rx_valid;
    logic [5:0] rx_id;
    logic rx_last;

    // read the fields from the input and set the output based
    // off of the command value
    always_comb begin
        command = Command'(gpio_in[31:24]);
        field = gpio_in[23:0];

        case (command)
            GET_READY: gpio_out = 32'({awready, wready, arready});
            GET_DATA: gpio_out = rx_data;
            GET_WRITE: gpio_out = 32'(rx_write);
            GET_VALID: gpio_out = 32'(rx_valid);
            GET_RESPONSE: gpio_out = 32'(rx_response);
            GET_ID: gpio_out = 32'(rx_id);
            GET_LAST: gpio_out = 32'(rx_last);
            default: gpio_out = 32'hXXXXXXXX;
        endcase
    end

    // set field commands
    always_ff @(posedge clock) begin
        case (command)
            DATA: data <= {field, 8'b0};
            ADDRESS_LOWER: address <= {address[31:24], field};
            ADDRESS_UPPER: address <= {field[7:0], address[23:0]};
            CACHE: cache <= field[3:0];
            PROTECTION: protection <= field[2:0];
            BURST: burst <= field[1:0];
            ID: id <= field[5:0];
            WRITE: write <= field[0];
            default: ;
        endcase
    end

    // reciever handshake helpers
    logic rx_write_ready;
    logic rx_read_ready;
    logic rx_write_valid;
    logic rx_read_valid;

    // set helper variables
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
            waitSend <= 0;
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
                if (command == SEND && !waitSend) begin
                    valid <= 1;
                    waitSend <= 1;
                end else if (command == CLEAR) begin
                    valid <= 0;
                end
            end

            if (command != SEND) begin
                waitSend <= 0;
            end
        end
    end

    // populate all of the axi outputs
    always_comb begin
        arvalid = !write && valid;
        awvalid = write && valid;
        bready = rx_write_ready;
        rready = rx_read_ready;
        wlast = write && valid; // same as wvalid
        wvalid = write && valid;
        arburst = burst;
        arlock = 0;
        arsize = 'b010;
        awburst = burst;
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
