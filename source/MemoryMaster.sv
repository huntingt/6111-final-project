module MemoryMaster(
    input clock,
    input reset,

    // first 24 bits are field, last 8 are control
    input logic [31:0] in,
    output logic [31:0] out,

    MemoryBus.master bus
    );
    
    logic [23:0] field;
    enum logic [7:0] {
        NONE,
        ADDRESS_LOWER,
        ADDRESS_UPPER,
        DATA,
        MASTER_ID,
        WRITE,
        TRY_SEND,
        READ_DATA,
        READ_MASTER_ID,
        TRY_TAKE
    } command;
    assign {command, field} = in;

    logic [23:0] lowerAddress;
    logic [7:0] upperAddress;
    assign bus.msAddress = {upperAddress, lowerAddress};

    enum logic[1:0] {
        IDLE,
        SEND,
        TAKE,
        WAIT,
    } status;

    always_comb begin
        case (command) inside
            TRY_SEND, TRY_TAKE: out = state == WAIT;
            READ_DATA: out = 32'(bus.smData);
            READ_MASTER_ID: out = 32'(bus.smID);
            default: out = 32'hxxxxxxxx;
        endcase

        bus.msValid = state == SEND;
        bus.smTake = state == TAKE;
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
        end else if (state == IDLE) begin
            case (command)
                ADDRESS_LOWER: lowerAddress <= field;
                ADDRESS_UPPER: upperAddress <= field[7:0];
                DATA: data <= field;
                MASTER_ID: bus.msID <= field[7:0];
                WRITE: bus.msWrite <= field[0];
                TRY_SEND: state <= SEND;
                TRY_TAKE: state <= TAKE;
            endcase
        end else if (state == SEND) begin
            if (bus.msValid && bus.msTaken) begin
                state <= WAIT;
            end
        end else if (state == TAKE) begin
            if (bus.smValid && bus.smTaken) begin
                state <= WAIT;
            end
        end else if (state == WAIT) begin
            if (command == NONE) begin
                state <= IDLE;
            end
        end
    end

endmodule: MemoryMaster
