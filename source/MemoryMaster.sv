module MemoryMaster(
    input clock,
    input reset,

    // first 24 bits are field, last 8 are control
    input logic [31:0] in,
    output logic [31:0] out,

    MemoryBus.Master bus
    );
    
    logic [23:0] field;
    enum logic [7:0] {
        NONE,
        ADDRESS_LOWER,
        ADDRESS_UPPER,
        DATA,
        ID,
        WRITE,
        SEND,
        GET_PENDING,
        GET_DATA,
        GET_ID,
        GET_VALID,
        CLEAR
    } command;
    assign {command, field} = in;

    logic [23:0] lowerAddress;
    logic [7:0] upperAddress;
    assign bus.msAddress = {upperAddress, lowerAddress};
    logic sent;

    logic [23:0] rx_data;
    logic [7:0] rx_id;
    logic rx_valid;

    always_comb begin
        case (command) inside
            GET_PENDING: out = 32'(bus.msValid);
            GET_DATA: out = 32'(rx_data);
            GET_ID: out = 32'(rx_id);
            GET_VALID: out = 32'(rx_valid);
            default: out = 32'hxxxxxxxx;
        endcase

        bus.smTaken = !rx_valid && (bus.smID == bus.msID);
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            bus.msValid <= 0;
            rx_valid <= 0;
            sent <= 0;
        end else begin
            if (bus.msValid && bus.msTaken) begin
                bus.msValid <= 0;
                sent <= 1;
            end else if (command == SEND && !sent) begin
                bus.msValid <= 1;
            end

            if (command != SEND) begin
                sent <= 0;
            end

            if (bus.smValid && bus.smTaken) begin
                rx_data <= bus.smData;
                rx_id <= bus.smID;
                rx_valid <= 1;
            end else if (command == CLEAR) begin
                rx_valid <= 0;
            end

            case (command)
                ADDRESS_LOWER: lowerAddress <= field;
                ADDRESS_UPPER: upperAddress <= field[7:0];
                DATA: bus.msData <= field;
                ID: bus.msID <= field[7:0];
                WRITE: bus.msWrite <= field[0];
                default: ;
            endcase
        end
    end
endmodule: MemoryMaster
