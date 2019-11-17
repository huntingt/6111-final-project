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
}
