#define CATCH_CONFIG_RUNNER
#include <catch2/catch.hpp>

#include <verilated.h>
#include <iostream>
#include <tuple>
#include <vector>
#include <optional>
#include <math.h>
#include "RayGenerator.h"

using namespace std;

int main(int argc, char** argv) {
    // Setup
    Verilated::commandArgs(argc, argv);
    
    // Run tests
    int result = Catch::Session().run( argc, argv );
 
    return result;
}

TEST_CASE("test RayGenerator startup") {
    RayGenerator dut = RayGenerator();
    
    Ray cameraV = Ray(512, 0, 0);
    Ray cameraX = Ray(0, 0, 0);
    Ray cameraY = Ray(0, 0, 0);

    dut.setCamera(cameraV, cameraX, cameraY);
    dut.setFrame(3, 3, 7);
    
    REQUIRE( dut.ready() );
    REQUIRE( !dut.busy() );

    dut.start();

    REQUIRE( !dut.ready() );
    REQUIRE( dut.busy() );

    SECTION("get a generated ray") {
        auto [address, ray] = dut.getRay();

        REQUIRE( address == 7 );
        int norm = ray.norm();
        REQUIRE( norm > 1.7*(1<<15) );
        REQUIRE( norm < (1<<16) );
    }
    SECTION("check address incrementing") {
        auto [address1, r1] = dut.getRay();
        auto [address2, r2] = dut.getRay();

        REQUIRE( address1 == 7 );
        REQUIRE( address2 == 8 );
    }
}
