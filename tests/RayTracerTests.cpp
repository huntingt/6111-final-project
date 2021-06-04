#define CATCH_CONFIG_RUNNER
#include <catch2/catch.hpp>

#include <verilated.h>
#include <iostream>
#include <tuple>
#include <vector>
#include <optional>
#include <math.h>
#include "Memory.h"
#include "RayTracer.h"

using namespace std;

int main(int argc, char** argv) {
    // Setup
    Verilated::commandArgs(argc, argv);
    
    // Run tests
    int result = Catch::Session().run( argc, argv );
 
    return result;
}

TEST_CASE("test config port"){
    const int base = 0x26 << 5;
    const int write = 1;
    const int read = 0;
    
    RayTracer dut = RayTracer(0);

    SECTION("try to read config register") {
        const int from = 10;
        const int to = base + 0x0;

        dut.makeRequest({from, to, 0, read});
        dut.step();
        dut.step();
        auto result = dut.readResponse();

        REQUIRE( result.has_value() );

        auto value = result.value();

        REQUIRE( value.from == from );
        REQUIRE( value.data == 0b10 );
    }
    SECTION("try to write to address port") {
        const int from = 0;
        const int to = base + 0x1;

        const int magic = 0x214365;

        dut.makeRequest({from, to, magic, write});
        dut.makeRequest({from, to, magic, read});

        dut.step();
        dut.step();
        dut.step();
        dut.step();

        auto result = dut.readResponse();

        REQUIRE( result.has_value() );

        auto value = result.value();

        REQUIRE( value.from == from );
        REQUIRE( value.data == magic );
    }
    SECTION("use the wrapper methods") {
        dut.writeRegister(RayTracer::HEIGHT, 234);
        REQUIRE( dut.readRegister(RayTracer::HEIGHT) == 234 );
    }
}

TEST_CASE("test small size") {
    RayTracer dut = RayTracer(256);

    const int materialAddress = 0;
    const int treeAddress = 256;
    const int frameAddress = 1024;

    const int width = 3;
    const int height = 3;

    MemoryArray material = MemoryArray(materialAddress, 256);
    for (int i = 0; i < 256; i++) {
        int color = 0xFFFFFF;
        material.write(i, color);
    }

    MemoryArray tree = MemoryArray(treeAddress, 256);
    for (int i = 0; i < 8; i++) {
        tree.write(i, 0xFFFF00);
    }
    
    MemoryArray frame = MemoryArray(frameAddress, 512);
    for (int i = 0; i < 10; i++) {
        frame.write(i, 1);
    }

    dut.attach(&material);
    dut.attach(&tree);
    dut.attach(&frame);

    Ray q = Ray(0, 0, 0);
    Ray v = Ray(0, 0, 15*(1<<12));
    Ray x = Ray(0, 0, 0);
    Ray y = Ray(0, 0, 0);
    
    dut.setCamera(q, v, x, y);
    dut.setScene(materialAddress, treeAddress);
    dut.setFrame(width, height, frameAddress);

    dut.start();

    dut.waitForInterrupt();

    bool allZeros = true;
    for (int i = 0; i < 9; i++) {
        allZeros &= frame.read(i) != 1;
    }
    REQUIRE( allZeros );
    REQUIRE( frame.read(9) == 1 );
}
