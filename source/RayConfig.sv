module RayConfig #(
    parameter POSITION_WIDTH=16,

    parameter DATA_WIDTH=24,
    parameter ADDRESS_WIDTH=32,
    
    parameter ADDRESS=0,
    parameter BASE_WIDTH=5
    )(
    input logic clock,
    input logic reset,

    output logic [ADDRESS_WIDTH-1:0] materialAddress,
    output logic [ADDRESS_WIDTH-1:0] treeAddress,
    output logic [ADDRESS_WIDTH-1:0] frameAddress,

    output logic [POSITION_WIDTH-1:0] cameraQ [2:0],
    output logic [POSITION_WIDTH-1:0] cameraV [2:0],
    output logic [POSITION_WIDTH-1:0] cameraX [2:0],
    output logic [POSITION_WIDTH-1:0] cameraY [2:0],

    output logic [11:0] width,
    output logic [11:0] height,

    output logic start,
    input logic ready,
    input logic busy,
    
    output logic flush,
    output logic resetRT,
    output logic normalize,

    output logic interrupt,
 
    MemoryBus.Slave bus
    );

    logic lastReady;
    logic recieved;
    logic sent;
    logic queuedTransaction;

    always_comb begin
        bus.msTaken = bus.msAddress[ADDRESS_WIDTH-1:BASE_WIDTH] == ADDRESS
            && bus.msValid
            && !queuedTransaction;
        bus.smValid = queuedTransaction;

        recieved = bus.msValid && bus.msTaken;
        sent = bus.smValid && bus.smTaken;

        if (recieved && bus.msWrite && bus.msAddress[BASE_WIDTH-1:0] == 0) begin
            start = bus.msData[0];
            flush = bus.msData[3];
            resetRT = bus.msData[4];
        end else begin
            start = 0;
            flush = 0;
            resetRT = reset;
        end

        interrupt = ready && !lastReady;
    end

    always_ff @(posedge clock) begin
        lastReady <= ready;

        if (reset) begin
            queuedTransaction <= 0;
        end else if (queuedTransaction) begin
            if (sent) begin
                queuedTransaction <= 0;
            end
        end else if (recieved && bus.msWrite) begin
            case (bus.msAddress[BASE_WIDTH-1:0])
                'h0: normalize <= bus.msData[5];
                'h1: materialAddress <= {bus.msData, 8'b0};
                'h2: treeAddress <= {bus.msData, 8'b0};
                'h3: frameAddress <= {bus.msData, 8'b0};
                'h4: cameraQ[0] <= POSITION_WIDTH'(bus.msData);
                'h5: cameraQ[1] <= POSITION_WIDTH'(bus.msData);
                'h6: cameraQ[2] <= POSITION_WIDTH'(bus.msData);
                'h7: cameraV[0] <= POSITION_WIDTH'(bus.msData);
                'h8: cameraV[1] <= POSITION_WIDTH'(bus.msData);
                'h9: cameraV[2] <= POSITION_WIDTH'(bus.msData);
                'ha: cameraX[0] <= POSITION_WIDTH'(bus.msData);
                'hb: cameraX[1] <= POSITION_WIDTH'(bus.msData);
                'hc: cameraX[2] <= POSITION_WIDTH'(bus.msData);
                'hd: cameraY[0] <= POSITION_WIDTH'(bus.msData);
                'he: cameraY[1] <= POSITION_WIDTH'(bus.msData);
                'hf: cameraY[2] <= POSITION_WIDTH'(bus.msData);
                'h10: width <= 12'(bus.msData);
                'h11: height <= 12'(bus.msData);
            endcase
        end else if (recieved && !bus.msWrite) begin
            case (bus.msAddress[BASE_WIDTH-1:0])
                'h0: bus.smData <= DATA_WIDTH'({normalize, 2'b0, busy, ready, 1'b0});
                'h1: bus.smData <= materialAddress[31:8];
                'h2: bus.smData <= treeAddress[31:8];
                'h3: bus.smData <= frameAddress[31:8];
                'h4: bus.smData <= DATA_WIDTH'(cameraQ[0]);
                'h5: bus.smData <= DATA_WIDTH'(cameraQ[1]);
                'h6: bus.smData <= DATA_WIDTH'(cameraQ[2]);
                'h7: bus.smData <= DATA_WIDTH'(cameraV[0]);
                'h8: bus.smData <= DATA_WIDTH'(cameraV[1]);
                'h9: bus.smData <= DATA_WIDTH'(cameraV[2]);
                'ha: bus.smData <= DATA_WIDTH'(cameraX[0]);
                'hb: bus.smData <= DATA_WIDTH'(cameraX[1]);
                'hc: bus.smData <= DATA_WIDTH'(cameraX[2]);
                'hd: bus.smData <= DATA_WIDTH'(cameraY[0]);
                'he: bus.smData <= DATA_WIDTH'(cameraY[1]);
                'hf: bus.smData <= DATA_WIDTH'(cameraY[2]);
                'h10: bus.smData <= DATA_WIDTH'(width);
                'h11: bus.smData <= DATA_WIDTH'(height);
            endcase
            queuedTransaction <= 1;
            bus.smID <= bus.msID;
        end
    end

endmodule: RayConfig

