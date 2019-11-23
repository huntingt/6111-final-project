module MemorySlave(
    input clock,
    input reset,

    input logic [31:0] in,
    output logic [31:0] out,

    MemoryBus.Slave bus
    );

    logic [23:0] field;
    enum logic [7:0] {
        NONE,
        DATA,
        MASTER_ID,
        TRY_SEND,
        READ_ADDRESS,
        READ_DATA,
        READ_MASTER_ID,
        READ_WRITE,
        TRY_TAKE
    } command;
    assign {command, field} = in;

    enum logic[1:0] {
        IDLE,
        SEND,
        TAKE,
        WAIT
    } state;

    always_comb begin
        case (command) inside
            TRY_SEND, TRY_TAKE: out = 32'(state == WAIT);
            READ_ADDRESS: out = bus.msAddress;
            READ_DATA: out = 32'(bus.msData);
            READ_MASTER_ID: out = 32'(bus.msID);
            READ_WRITE: out = 32'(bus.msWrite);
            default: out = 32'hxxxxxxxx;
        endcase

        bus.smValid = state == SEND;
        bus.msTaken = state == TAKE;
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
        end else if (state == IDLE) begin
            case (command)
                DATA: bus.smData <= field;
                MASTER_ID: bus.smID <= field[7:0];
                TRY_SEND: state <= SEND;
                TRY_TAKE: state <= TAKE;
                default: ;
            endcase
        end else if (state == SEND) begin
            if (bus.smValid && bus.smTaken) begin
                state <= WAIT;
            end
        end else if (state == TAKE) begin
            if (bus.msValid && bus.msTaken) begin
                state <= WAIT;
            end
        end else if (state == WAIT) begin
            if (command == NONE) begin
                state <= IDLE;
            end
        end
    end

endmodule: MemorySlave
