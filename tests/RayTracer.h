#ifndef _RAY_TRACER
#define _RAY_TRACER

#include <verilated.h>
#include <tuple>
#include <vector>
#include <exception>
#include "Ray.h"
#include "Memory.h"
#include "VRayTracerTB.h"

using namespace std;

class RayTracer {
    public:
    enum Register {
        CONFIG=0x0,
        MATERIAL,
        TREE,
        FRAME,
        QX,
        QY,
        QZ,
        VX,
        VY,
        VZ,
        XX,
        XY,
        XZ,
        YX,
        YY,
        YZ,
        WIDTH,
        HEIGHT
    };
    
    /*
     * Make a new ray tracer.
     *
     * @param timeout used when waiting for an interrupt
     */
    RayTracer(long timeout);

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

    void start();
    void setCamera(Ray q, Ray v, Ray x, Ray y);
    void setScene(int materialAddress, int treeAddress);
    void setFrame(int width, int height, int frameAddress);

    void writeRegister(Register reg, int value);
    int readRegister(Register reg);

    ~RayTracer();

    private:
    const int base = 0x26 << 5;

    long timeout;
    long cycles;

    VRayTracerTB* dut;

    MemoryInterface memoryPort;
    MemoryInterface configPort;
    
    MemorySlaveController* slave;
    MemoryMaster* master;
};

#endif
