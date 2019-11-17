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
    
    Ray cameraV = Ray(0, 0, 0);
    Ray cameraX = Ray(0, 0, 0);
    Ray cameraY = Ray(0, 0, 0);

    dut.setCamera(cameraV, cameraX, cameraY);
    dut.setFrame(500, 500, 0);
    
    REQUIRE( dut.ready() );
    REQUIRE( !dut.busy() );

    dut.start();

    REQUIRE( !dut.ready() );
    REQUIRE( dut.busy() );
}
