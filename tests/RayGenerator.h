#ifndef _GENERATOR
#define _GENERATOR

#include <verilated.h>
#include <math.h>
#include <vector>
#include <tuple>
#include <exception>
#include <string>
#include <optional>
#include "VRayGenerator.h"
#include "Ray.h"

using namespace std;

/*
 * RayGenerator wrapper for testing.
 */
class RayGenerator{
    public:
    /*
     * Make a new ray generator.
     *
     * @param timeout timeout on getRay operations
     */
    RayGenerator(int timeout=16);

    /*
     * Sets the camera directions.
     * 
     * @param v camera direction
     * @param x step direction for a pixel in the
     *          camera's x axis
     * @param y step direction for a pixel in the
     *          camera's y axis
     */
    void setCamera(Ray v, Ray x, Ray y);
    /*
     * Set the frame information.
     *
     * @param width frame width
     * @param height frame height
     * @param frameAddress base address of the frame
     */
    void setFrame(int width, int height, int frameAddress);
    
    /*
     * Starts the system.
     */
    void start();
    /*
     * Get a single ray from the generator. Fails with runtime
     * exception after the timeout interval.
     *
     * @throws runtime_error on timeout
     * @return address, ray
     */
    tuple<int, Ray> getRay();
    /*
     * Gets all of the rays in a frame.
     */
    vector<tuple<int, Ray>> getRays();
    
    bool ready();
    bool busy();

    void reset();
    void step();
    
    /*
     * Total number of cycles that the module has run.
     */
    long getCycles();

    ~RayGenerator();

    private:
    VRayGenerator* dut;

    int timeout;
    long cycles;
};

#endif
