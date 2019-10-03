#include <verilated.h>
#include <iostream>
#include "VSimple.h"

#define CATCH_CONFIG_RUNNER
#include <catch2/catch.hpp>

int main(int argc, char** argv) {
    // Setup
    Verilated::commandArgs(argc, argv);
    
    // Run tests
    int result = Catch::Session().run( argc, argv );
 
    return result;
}

TEST_CASE("Test the simple module", "[Simple]"){
    VSimple* simple = new VSimple;

    simple->reset = 1;
    simple->clock = 0;
    simple->eval();
    simple->clock = 1;
    simple->eval();
    simple->clock = 0;
    simple->reset = 0;
    simple->a = 1;
    simple->b = 1;
    simple->eval();
    simple->clock = 1;
    simple->eval();

    REQUIRE( simple->result == 2 );
    simple->final();
    delete simple;
}
