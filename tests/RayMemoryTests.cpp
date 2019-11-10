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

TEST_CASE("test Memory.h"){
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

    MemoryArray bram = MemoryArray(0, 1024);
    controller.attach(&bram);

    SECTION("test simple read") {
        master.makeRequest({0, 0, 0, 0});

        // send to controller
        master.step();
        controller.step();

        // no request yet
        REQUIRE( !master.readResponse().has_value() );

        // send back master
        master.step();
        controller.step();
        
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

        master.step();
        controller.step();

        // no request yet
        REQUIRE( !master.readResponse().has_value() );

        master.step();
        controller.step();
        
        // still no request yet (write has no response)
        REQUIRE( !master.readResponse().has_value() );
        
        master.step();
        controller.step();
        
        // expect request
        auto response = master.readResponse();
        REQUIRE( response.has_value() );
        auto value = response.value();
        REQUIRE( value.from == 11 );
        REQUIRE( value.data == 23 );
    }
}

TEST_CASE("test RayMemory operation") {
    RayMemory dut = RayMemory(124);
    MemoryArray bram = MemoryArray(0, 1024);

    dut.attach(bram);
}
