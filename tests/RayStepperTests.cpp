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
    RayStepper dut;

    REQUIRE(dut.getBounds({0, 0, 0}, 16) ==
            make_tuple<vector<int>, vector<int>>
            ({0, 0, 0}, {0, 0, 0}));
    
    const int upperBound = pow(2, 16) - 1;
    REQUIRE(dut.getBounds({37043, 2001, 50000}, 0) ==
            make_tuple<vector<int>, vector<int>>
            ({0, 0, 0}, {upperBound, upperBound, upperBound}));

    REQUIRE(dut.getBounds({37043, 2001, 50000}, 8) ==
            make_tuple<vector<int>, vector<int>>
            ({36864, 1792, 49920}, {37119, 2047, 50175}));
    
    vector<int> exact = {50000, 0, 15931};
    REQUIRE(dut.getBounds(exact, 16) ==
            make_tuple(exact, exact));
}
