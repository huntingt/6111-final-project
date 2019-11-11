#define CATCH_CONFIG_RUNNER
#include <catch2/catch.hpp>

#include <verilated.h>
#include <iostream>
#include <tuple>
#include <vector>
#include <optional>
#include <math.h>
#include "Memory.h"
#include "RayMemory.h"

using namespace std;

int main(int argc, char** argv) {
    // Setup
    Verilated::commandArgs(argc, argv);
    
    // Run tests
    int result = Catch::Session().run( argc, argv );
 
    return result;
}

TEST_CASE("test Memory.h with 0 latency memory"){
    int msID;
    int msAddress;
    int msData;
    bool msWrite;
    bool msTaken;
    bool msValid;

    int smID;
    int smData;
    bool smTaken;
    bool smValid;

    MemoryInterface interface = {
        &msID,
        &msAddress,
        &msData,
        &msWrite,
        &msTaken,
        &msValid,

        &smID,
        &smData,
        &smTaken,
        &smValid
    };
    
    MemoryMaster master = MemoryMaster(&interface);
    MemorySlaveController controller = MemorySlaveController(&interface);

    MemoryArray bram = MemoryArray(0, 1024, 0);
    controller.attach(&bram);

    SECTION("test simple read") {
        master.makeRequest({0, 0, 0, 0});

        // send to controller
        master.step1();
        controller.step1();
        master.step2();
        controller.step2();

        // no request yet
        REQUIRE( !master.readResponse().has_value() );

        // send back master
        master.step1();
        controller.step1();
        master.step2();
        controller.step2();
        
        // expect request
        auto response = master.readResponse();
        REQUIRE( response.has_value() );
        REQUIRE( response.value().data == 0 );
    }

    SECTION("test simple write and read") {
        // master 10 write 23 to 50
        // master 11 read from 50
        master.makeRequest({10, 50, 23, 1});
        master.makeRequest({11, 50, 0, 0});

        master.step1();
        controller.step1();
        master.step2();
        controller.step2();

        // no request yet
        REQUIRE( !master.readResponse().has_value() );

        master.step1();
        controller.step1();
        master.step2();
        controller.step2();
        
        // still no request yet (write has no response)
        REQUIRE( !master.readResponse().has_value() );
        
        master.step1();
        controller.step1();
        master.step2();
        controller.step2();
        
        // expect request
        auto response = master.readResponse();
        REQUIRE( response.has_value() );
        auto value = response.value();
        REQUIRE( value.from == 11 );
        REQUIRE( value.data == 23 );
    }
}

TEST_CASE("test RayMemory operation") {
    RayMemory dut = RayMemory(124, 0, 1024);
    
    // material map gives the material index as its
    // properety
    MemoryArray material = MemoryArray(0, 256);
    for (int i = 0; i < 256; i++) {
        material.write(i, i);
    }

    MemoryArray tree = MemoryArray(1024, 1024);
    tree.loadFile("tests/simple.oc");

    MemoryArray frame = MemoryArray(512, 512);

    REQUIRE( tree.read(0) == 0xFFFF00 );

    dut.attach(&tree);
    dut.attach(&material);
    dut.attach(&frame);
    
    SECTION("write a pixel to the frame") {
        dut.writePixel(512, 0x123456);
        REQUIRE( frame.read(0) == 0x123456 );
    }
    SECTION("get the material of zero vector") {
        auto [depth, material] = dut.traverse({0, 0, 0});
        REQUIRE( depth == 1 );
        REQUIRE( material == 0 );
    }
    SECTION("test nozero material") {
        auto [depth, material] = dut.traverse({40000, 0, 40000});
        REQUIRE( depth == 1 );
        REQUIRE( material == 5 );
    }
    SECTION("test double node traversal"){
        auto [depth, material] = dut.traverse({31000, 0, 33000});
        REQUIRE( depth == 2 );
        REQUIRE( material == 0x11 );
    }
}
