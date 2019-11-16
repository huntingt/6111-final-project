#ifndef _RAY_MEMORY
#define _RAY_MEMORY

#include <verilated.h>
#include <tuple>
#include <vector>
#include <exception>
#include "Memory.h"
#include "VRayMemoryTB.h"

using namespace std;

class RayMemory {
    public:
    /*
     * Make a new RayMemory module. Mostly for testing purposes.
     *
     * @param timeout sets the timeout for transactions
     * @param materialAddress address of the materials table in memory
     * @param treeAddress address of the tree in memory
     */
    RayMemory(int timeout, int materialAddress, int treeAddress);

    /*
     * Performs the module reset sequence.
     */
    void reset();

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
     * Flush out any cached data in the memory unit.
     */
    void flush();

    /*
     * Perform a traverse operation with the given timeout. If it fails
     * then a runtime_exception will be thrown.
     *
     * @param position position to traverse the octree at
     * @return {depth, material} at 'position' in the octree
     */
    tuple<int, int> traverse(vector<int> position);
    
    /*
     * Writes a pixel into memory with the specified timeout.
     *
     * @param pixelAddress address to save pixel to
     * @param pixel pixel to save
     */
    void writePixel(int pixelAddress, int pixel);

    /*
     * Number of cycles the module has completed since instantiation.
     */
    long getCycles();

    ~RayMemory();

    private:
    int timeout;
    long cycles;

    VRayMemoryTB* dut;

    MemoryInterface interface;
    MemorySlaveController* controller;
};

#endif
