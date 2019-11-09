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
    SECTION("test rounding system"){
        vector<int> v = {0, 20252, 0};
        vector<int> q = {0, 32000, 0};
    
        auto result = dut.propagate(q, v, 1);
    }
    SECTION("test out of bounds"){
        vector<int> v = {16606, 22917, 8287};
        vector<int> q = {0, 0, 0};

        auto result = dut.propagate(q, v, 1);

        REQUIRE( result.has_value() );
    }
}

TEST_CASE("test octree"){ 
    vector<Octree<int>*> children = {
        new Leaf<int>(0),
        new Leaf<int>(1),
        new Leaf<int>(2),
        new Leaf<int>(3),

        new Leaf<int>(4),
        new Leaf<int>(5),
        new Leaf<int>(6),
        new Leaf<int>(7)
    };
    Octree<int>* tree = new Branch<int>(children);

    SECTION("test octant setup"){
        const int bits = 16;
        REQUIRE( tree->at({    0,     0,     0}, bits) == 0 );
        REQUIRE( tree->at({40000, 40000, 40000}, bits) == 7 );
        REQUIRE( tree->at({40000,     0,     0}, bits) == 1 );
        REQUIRE( tree->at({    0, 40000,     0}, bits) == 2 );
        REQUIRE( tree->at({    0,     0, 40000}, bits) == 4 );
        REQUIRE( tree->at({    0, 40000, 40000}, bits) == 6 );
        REQUIRE( tree->at({40000,     0, 40000}, bits) == 5 );
        REQUIRE( tree->at({40000, 40000,     0}, bits) == 3 );
    }
}
