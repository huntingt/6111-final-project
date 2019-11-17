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

TEST_CASE("test all rays in an image") {
    RayGenerator dut = RayGenerator();
    
    const double right = -60;
    const double down = 35;
    Ray cameraV = Ray(0, 0, 8000).rotx(down).roty(right);
    Ray cameraX = Ray(200, 0, 0).rotx(down).roty(right);
    Ray cameraY = Ray(0, 200, 0).rotx(down).roty(right);

    dut.setCamera(cameraV, cameraX, cameraY);
    dut.setFrame(500, 500, 0);
    
    dut.start();
    SECTION("a single ray") {
        auto [address, ray] = dut.getRay();
        auto norm = ray.norm();
        
        REQUIRE( norm > 0.7*(1<<16) );
    }
    
    SECTION("check for right number and size") {
        for (int i = 0; i < 500*500; i++) {
            auto [address, ray] = dut.getRay();
            auto norm = ray.norm();

            REQUIRE( address == i );

            REQUIRE( norm > 1.7*(1<<14) );
        }

        REQUIRE( !dut.busy() );
    }
    
}
