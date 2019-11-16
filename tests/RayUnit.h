#ifndef _RAY_MEMORY
#define _RAY_MEMORY

#include <verilated.h>
#include <tuple>
#include <vector>
#include <exception>
#include "Memory.h"
#include "VRayUnitTB.h"

using namespace std;

class RayUnit {
    public:
    RayUnit(int timeout);

    /*
     * Performs the module reset sequence.
     */
    void reset();

    /*
     * Attach a new memory slave.
     *
     * @param slave slave to attach
     */
    void attach(MemorySlave* slave);
    
    /*
     * Step the simulation forwards by a single step. Mostly called
     * by other coordination methods.
     */
    void step();

    /*
     * Flush out any cached data in the memory unit.
     */
    void flush();

    /*
     * Setup the rendering address locations.
     */
    void setRender(int materialAddress, int treeAddress);

    /*
     * Carry out a single render operation.
     */
    void render(vector<int> position, vector<int> direction, int address);

    /*
     * Number of cycles the module has completed since instantiation.
     */
    long getCycles();

    ~RayUnit();

    private:
    int timeout;
    long cycles;

    VRayUnitTB* dut;

    MemoryInterface interface;
    MemorySlaveController* controller;
};

#endif
