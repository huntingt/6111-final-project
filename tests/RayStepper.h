#ifndef _STEPPER_WRAPPER
#define _STEPPER_WRAPPER

#include <verilated.h>
#include <math.h>
#include <vector>
#include <tuple>
#include <exception>
#include <string>
#include "VRayStepper.h"

using namespace std;

class RayStepper{
    public:
    RayStepper();

    void setLower(vector<int> lower);
    void setUpper(vector<int> upper);

    void setPosition(vector<int> q);
    void setDirection(vector<int> v);

    /*
     * Propogate a ray inside an AABB
     *
     * @param q initial position vector
     * @param n depth
     * @return (new position, number of cycles)
     */
    tuple<vector<int>, int>
        propogate(vector<int> q, vector<int> v, int n);
    
    /*
     * Generate bounds for an octree of side length 2**bitDepth
     * 
     * @param q position vector with components 0 <= q_i < 2**bitDepth
     * @param n number of divisions where 0 <= n <= bitDepth
     * @param bitDepth number of bits for position
     * @return (lower, upper) bounds, same number of dimensions as q
     */
    static tuple<vector<int>, vector<int>>
        getBounds(vector<int> q, int n, int bitWidth);

    void reset();
    void step();
    
    /*
     * Total number of cycles that the function has run for.
     */
    long getCycles();

    ~RayStepper();

    int bitWidth = 16;
    private:
    VRayStepper* dut;

    long cycles;

};

#endif
