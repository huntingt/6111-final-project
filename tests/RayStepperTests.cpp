#define CATCH_CONFIG_RUNNER
#include <catch2/catch.hpp>

#include <verilated.h>
#include <iostream>
#include <tuple>
#include <vector>
#include <optional>
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
        vector<int> v = RayStepper::normalize({1, 0, 0}, dut.bitWidth);
        
        auto result = dut.propagate(q, v, dut.bitWidth);
        REQUIRE( result.has_value() );

        vector<int> expected = {11, 20, 30};
        REQUIRE( result.value() == expected );
    }
    SECTION("test out of bounds across large cube"){
        vector<int> q0 = {32768, 32768, 32768};
        vector<int> q1 = {32769, 32769, 32769};
        vector<int> v = RayStepper::normalize({1, 1, 1}, dut.bitWidth);
        
        REQUIRE( !dut.propagate(q0, v, 1).has_value() );
        REQUIRE( !dut.propagate(q1, v, 1).has_value() );
    }
    SECTION("test normal operation from zero across large section"){
        vector<int> q = {0, 0, 0};
        vector<int> v = RayStepper::normalize({1, 1, 1}, dut.bitWidth);

        REQUIRE( dut.propagate(q, v, 1).has_value() );
    }
    SECTION("regression tests for look bug"){
        vector<int> q = {0, 0, 0};
        vector<int> v = {13533, 20447, 16384};
        vector<int> zeros = {0, 0, 0};

        auto result = dut.propagate(q, v, 1);

        REQUIRE( result.has_value() );
        REQUIRE( result.value() != zeros );
    }
    SECTION("test back to zero"){
        vector<int> v = {-1,-1,-1};
        vector<int> q = {0, 0, 0};
        
        auto result = dut.propagate(q, v, 1);
        
        REQUIRE( !result.has_value() );
    }
}
