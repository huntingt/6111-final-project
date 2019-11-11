#ifndef _MEMORY
#define _MEMORY

#include <queue>
#include <optional>
#include <vector>
#include <exception>
#include <string>
#include <tuple>
#include <fstream>
#include <algorithm>

using namespace std;

/*
 * Struct serves as an interface between verilated
 * modules and the classes present in this code. Because
 * the structure of verilated classes can't be controlled
 * (ie. we can't make them inherit some abstract class),
 * the relevant pointers are instead handed to this
 * interface to provide a generic memory bus handling
 * implementation.
 */
struct MemoryInterface {
    int  *msID;
    int  *msAddress;
    int  *msData;
    bool *msWrite;
    bool *msTaken;
    bool *msValid;

    int  *smID;
    int  *smData;
    bool *smTaken;
    bool *smValid;
};

/*
 * A memory request from a master to a slave.
 */
struct MemoryRequest {
    int from;
    int to;
    int data;
    int write;
};

/*
 * A memory response from a slave to a master.
 */
struct MemoryResponse {
    int from;
    int data;
};

/*
 * The memory master abstracts away the bus protocol
 * for a master. Cpp code can simply queue a request
 * into the master, and it will handle the interface with
 * verilator.
 */
class MemoryMaster {
    public:
    MemoryMaster(MemoryInterface* bus);

    /*
     * Queue a request into the master.
     *
     * @param request request to be queued.
     */
    void makeRequest(MemoryRequest request);

    /*
     * Read out any queued reseponses
     *
     * @return a response if available, otherwise none
     */
    optional<MemoryResponse> readResponse();

    /*
     * This function iterates the memory master. Due to the
     * protocol having a combinational dependence on taken,
     * the master must initiate a communication with the slave
     * then the slave must be updated in order for the system
     * to properly work.
     *
     * This function should be called after the rising edge
     * update of the verilated module.
     */
    void step1();
    /*
     * This function is completes transactions initiated in
     * step1().
     *
     * This function should be called after calling step1() and
     * then updating the verilated module.
     */
    void step2();

    private:
    queue<MemoryRequest> requests;
    queue<MemoryResponse> responses;

    MemoryInterface* bus;
};

/*
 * Interface for classes that want to replicate slave
 * devices.
 */
class MemorySlave {
    public:
    /*
     * Checks to see if a slave will "take" a request.
     *
     * @param address address of the request
     * @return whether or not the slave is taking the request
     */
    virtual bool claim(int address) = 0;
    /*
     * Gets the response from a slave that has taken a request.
     *
     * @param address address of the request
     * @param data data of the request
     * @param write true if a write request, false if read
     * @return nothing if there is no response, or (latency, data)
     *      where data is the response data and latency is how many
     *      cycles the response should be delayed by.
     *      0 <= latency
     */
    virtual optional<tuple<int, int>> step(int address, int data, bool write) = 0;
};

/*
 * Slave that replicates memory
 */
class MemoryArray : public MemorySlave {
    public:
    /*
     * Create a new memory array
     *
     * @param base base address to map the memory to
     * @param size size of the memory block
     * @param latency latency of the memory in cycles
     */
    MemoryArray(int base, int size, int latency=1);

    bool claim(int address);
    optional<tuple<int, int>> step(int address, int data, bool write);

    /*
     * Copy a file into the memory
     *
     * @param filename filename of the file to copy where
     *      the file has the given format.
     *
     * Each line specifies the value of a memory address where
     * the first line corresponds to address 0, the second -> 1, 
     * and so on. Values are given in plain text with base 10 as
     * default, although hex can be specified by prepending '0x'.
     * Number characters can be seperated by '_' for readability
     * and lines that start with '#' or are empry are ignored.
     */
    void loadFile(string filename);

    /*
     * Write a value into the memory
     *
     * @param i location to write to in memory relative to the
     *      base address
     * @param value value to write at location i
     */
    void write(int i, int value);
    /*
     * Read a value from memory
     *
     * @param i location to read from relative to the base address
     * @return value at location i
     */
    int read(int i);

    private:
    int base;
    int size;
    int latency;
    vector<int> memory;
};

/*
 * Adapter between a master interface and any number of slaves.
 */
class MemorySlaveController {
    public:
    /*
     * Creates a new memory slave controller on the interface bus
     * 
     * @param bus master interface to connect to slaves
     */
    MemorySlaveController(MemoryInterface* bus);
    
    /*
     * Attaches a MemorySlave to the master interface.
     *
     * @param slave slave to attach
     */
    void attach(MemorySlave* slave);

    /*
     * The first update step of the memory slave controller.
     * Slaves are executed during this step.
     *
     * This function should be called after the rising edge
     * update of the verilated module.
     */
    void step1();
    /*
     * This function is completes transactions initiated in
     * step1().
     *
     * This function should be called after calling step1() and
     * then updating the verilated module.
     */
    void step2();

    private:
    vector<MemorySlave*> slaves;
    vector<tuple<int, MemoryResponse>> responses;
    
    int currentResponse;

    MemoryInterface* bus;
};

#endif
