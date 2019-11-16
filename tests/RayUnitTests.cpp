#define CATCH_CONFIG_RUNNER
#include <catch2/catch.hpp>

#include <verilated.h>
#include <iostream>
#include <tuple>
#include <vector>
#include <optional>
#include <math.h>
#include "Memory.h"
#include "RayUnit.h"
#include "Ray.h"

using namespace std;

int main(int argc, char** argv) {
    // Setup
    Verilated::commandArgs(argc, argv);
    
    // Run tests
    int result = Catch::Session().run( argc, argv );
 
    return result;
}

TEST_CASE("test RayUnit operation") {
    const int timeout = 256;
    const int pixelAddress = 4096;
    const int materialAddress = 0;
    const int treeAddress = 256;

    RayUnit dut = RayUnit(timeout);
    
    // material map gives the material index as its
    // properety
    MemoryArray material = MemoryArray(materialAddress, 256);
    for (int i = 0; i < 256; i++) {
        material.write(i, i);
    }

    MemoryArray tree = MemoryArray(treeAddress, 1024);
    tree.loadFile("tests/cube.oc");

    MemoryArray frame = MemoryArray(pixelAddress, 512);

    dut.attach(&tree);
    dut.attach(&material);
    dut.attach(&frame);
    
    dut.setRender(materialAddress, pixelAddress);

    SECTION("Test straight") {
        vector<int> q = {0, 0, 0};
        vector<int> v = Ray::normalize({1, 1, 0}, 16);
        
        dut.render(q, v, pixelAddress + 0);

        REQUIRE( frame.read(0) == 0xFFFFFF );
    }
}
