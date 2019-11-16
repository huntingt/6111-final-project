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
    const int timeout = 128;
    const int pixelAddress = 4096;
    const int materialAddress = 0;
    const int treeAddress = 256;

    RayUnit dut = RayUnit(timeout);
    
    // Maps material index to greyscale color
    MemoryArray material = MemoryArray(materialAddress, 256);
    for (int i = 0; i < 256; i++) {
        int color = i + (i << 8) + (i << 16);
        material.write(i, color);
    }

    MemoryArray tree = MemoryArray(treeAddress, 1024);
    tree.loadFile("tests/cube.oc");

    MemoryArray frame = MemoryArray(pixelAddress, 512);
    
    dut.attach(&tree);
    dut.attach(&material);
    dut.attach(&frame);
    
    dut.setRender(materialAddress, treeAddress);

    SECTION("Test straight") {
        vector<int> q = {0, 0, 0};
        vector<int> v = Ray::normalize({1, 1, 1}, 16);
        
        dut.render(q, v, pixelAddress + 0);

        REQUIRE( frame.read(0) == 0xFFFFFF );
    }
}

TEST_CASE("test RayUnit on diagonal scene") {
    const int timeout = 128;
    const int pixelAddress = 4096;
    const int materialAddress = 0;
    const int treeAddress = 256;

    RayUnit dut = RayUnit(timeout);
    
    // Maps material index to greyscale color
    MemoryArray material = MemoryArray(materialAddress, 256);
    for (int i = 0; i < 256; i++) {
        int color = i + (i << 8) + (i << 16);
        material.write(i, color);
    }

    MemoryArray tree = MemoryArray(treeAddress, 1024);
    tree.loadFile("tests/diagonal.oc");

    MemoryArray frame = MemoryArray(pixelAddress, 512);
    
    dut.attach(&tree);
    dut.attach(&material);
    dut.attach(&frame);
    
    dut.setRender(materialAddress, treeAddress);

    vector<int> q = {40000, 40000, 0};
    
    SECTION("test top right") {
        vector<int> v = Ray::normalize({250, -250, 400}, 16);
        dut.render(q, v, pixelAddress + 0);

        REQUIRE( frame.read(0) == 0 );
    }
    
    SECTION("test bottom left") {
        vector<int> v = Ray::normalize({250, 250, 400}, 16);
        dut.render(q, v, pixelAddress + 0);

        REQUIRE( frame.read(0) == 0xffffff );
    }
}
