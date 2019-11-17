#ifndef _RAY_TRACER
#define _RAY_TRACER

#include <verilated.h>
#include <tuple>
#include <vector>
#include <exception>
#include "Memory.h"
#include "VRayTracerTB.h"

using namespace std;

class RayTracer {
    public:
    /*
     * Make a new ray tracer.
     *
     * @param timeout used when waiting for an interrupt
     */
    RayTracer(int timeout);

    /*
     * Performs the module reset sequence.
     */
    void reset();

    /*
     * Make a request to the config port.
     */
    void makeRequest(MemoryRequest request);

    /*
     * Read a response from the config port if available.
     */
    optional<MemoryResponse> readResponse();
    /*
     * Run the system until the interrupt is triggered or it times out.
     */
    void waitForInterrupt();

    /*
     * Attach a new memory slave to the slave memory controller.
     */
    void attach(MemorySlave* slave);
    
    /*
     * Step the simulation forwards by a single step. Mostly called
     * by other coordination methods.
     */
    void step();

    /*
     * Number of cycles the module has completed since instantiation.
     */
    long getCycles();

    ~RayTracer();

    private:
    long timeout;
    long cycles;

    VRayTracerTB* dut;

    MemoryInterface memoryInterface;
    MemoryInterface configInterface;
    
    MemorySlaveController* slave;
    MemoryMaster* master;
};

#endif
