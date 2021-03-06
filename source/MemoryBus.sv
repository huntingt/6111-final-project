/*
 * Packet like memory interface used within the ray
 * tracing system to allow for fast small transfers of data.
 */ 
interface MemoryBus #(
    parameter MASTER_ID_WIDTH=8,
    parameter ADDRESS_WIDTH=32,
    parameter DATA_WIDTH=16);
    
    /*
     * ms - master to slave
     *
     * msID - id of the master used by the slave to
     *      send back a read response
     *
     * msReady & msValid - form a ready valid pair to
     *      handshake the master to slave connection
     */
    logic [MASTER_ID_WIDTH-1:0] msID;
    logic [ADDRESS_WIDTH-1:0]   msAddress;
    logic [DATA_WIDTH-1:0]      msData;
    logic                       msWrite;
    logic                       msTaken;
    logic                       msValid;

    /*
     * sm - slave to master
     */
    logic [MASTER_ID_WIDTH-1:0] smID;
    logic [DATA_WIDTH-1:0]      smData;
    logic                       smTaken;
    logic                       smValid;

    modport Master(
        output  msID,
        output  msAddress,
        output  msData,
        output  msWrite,
        input   msTaken,
        output  msValid,

        input   smID,
        input   smData,
        output  smTaken,
        input   smValid
    );

    modport Slave(
        input   msID,
        input   msAddress,
        input   msData,
        input   msWrite,
        output  msTaken,
        input   msValid,

        output  smID,
        output  smData,
        input   smTaken,
        output  smValid
    );
endinterface: MemoryBus
