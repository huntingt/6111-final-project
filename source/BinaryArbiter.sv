module BinaryArbiter #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=24
    )(
    input clk,
    MemoryBus.Slave sbus0,
    MemoryBus.Slave sbus1,
    MemoryBus.Master mbus
    );
    BinaryArbiter_MS ms(.clk(clk), .sbus0(sbus0), .sbus1(sbus1), .mbus(mbus));
    BinaryArbiter_SM sm(.sbus0(sbus0), .sbus1(sbus1), .mbus(mbus));
endmodule
/* verilator lint_off DECLFILENAME */
module BinaryArbiter_MS #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=24
    )(
    input clk,
    MemoryBus.Slave sbus0,
    MemoryBus.Slave sbus1,
    MemoryBus.Master mbus
    );
    logic lru;
    logic select;
    
    always_comb begin
        select = sbus1.msValid && !(lru && sbus0.msValid);

        if (select) begin
            //pass from sbus0 to mbus
            mbus.msID = sbus0.msID;
            mbus.msAddress = sbus0.msAddress;
            mbus.msData = sbus0.msData;
            mbus.msWrite = sbus0.msWrite;
            mbus.msValid = sbus0.msValid;
            sbus0.msTaken = mbus.msTaken;
            sbus1.msTaken = 0;
        end else begin
            //pass from sbus1 to mbus
            mbus.msID = sbus1.msID;
            mbus.msAddress = sbus1.msAddress;
            mbus.msData = sbus1.msData;
            mbus.msWrite = sbus1.msWrite;
            mbus.msValid = sbus1.msValid;
            sbus1.msTaken = mbus.msTaken;
            sbus0.msTaken = 0;
        end
    end

    always_ff @ (posedge clk) begin
        if (mbus.msValid && mbus.msTaken) begin
            lru <= select;
        end
    end
endmodule

module BinaryArbiter_SM #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=24
    )(
    MemoryBus.Slave sbus0,
    MemoryBus.Slave sbus1,
    MemoryBus.Master mbus
    );
    always_comb begin
        sbus0.smID = mbus.smID;
        sbus0.smData = mbus.smData;
        sbus0.smValid = mbus.smValid;
                
        sbus1.smID = mbus.smID;
        sbus1.smData = mbus.smData;
        sbus1.smValid = mbus.smValid;
                
        mbus.smTaken = sbus0.smTaken || sbus1.smTaken;
    end
endmodule
/* verilator lint_on DECLFILENAME */
