#define CATCH_CONFIG_RUNNER
#include <catch2/catch.hpp>

#include <verilated.h>
#include <iostream>
#include <tuple>
#include <vector>
#include <math.h>
#include "RayStepper.h"

using namespace std;

int main(int argc, char** argv) {
    // Setup
    Verilated::commandArgs(argc, argv);
    
    // Run tests
    int result = Catch::Session().run( argc, argv );
 
    return result;
}

TEST_CASE("try bound finding algorithm"){
    REQUIRE(RayStepper::getBounds({0, 0, 0}, 16, 16) ==
            make_tuple<vector<int>, vector<int>>
            ({0, 0, 0}, {0, 0, 0}));
    
    const int upperBound = pow(2, 16) - 1;
    REQUIRE(RayStepper::getBounds({37043, 2001, 50000}, 0, 16) ==
            make_tuple<vector<int>, vector<int>>
            ({0, 0, 0}, {upperBound, upperBound, upperBound}));

    REQUIRE(RayStepper::getBounds({37043, 2001, 50000}, 8, 16) ==
            make_tuple<vector<int>, vector<int>>
            ({36864, 1792, 49920}, {37119, 2047, 50175}));
    
    vector<int> exact = {50000, 0, 15931};
    REQUIRE(RayStepper::getBounds(exact, 16, 16) ==
            make_tuple(exact, exact));
}

TEST_CASE("test the actual ray stepper module"){
    RayStepper dut;

    SECTION("test a small cube"){
        vector<int> q = {10, 20, 30};
        vector<int> v = {1, 0, 0};
        
        auto result = dut.propogate(q, v, dut.bitWidth);
        
        vector<int> expected = {11, 20, 30};
        REQUIRE( get<0>(result) == expected );
    }
    SECTION("test out of bounds across large cube"){
        vector<int> q0 = {0, 0, 0};
        vector<int> q1 = {1, 1, 1};
        vector<int> v = {1, 1, 1};
        
        dut.propogate(q0, v, 0);
        dut.propogate(q1, v, 0);
    }
}
