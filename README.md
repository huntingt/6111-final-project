# 6.111 Final Project

## Setup

In order to run the tests you must install:
- verilator
- catch2 (testing library)
- opencv2

In order to run code that requires opencv2, you may need to set the
path for pkg\_config. ``brew info opencv@2`` can be used to find the
required command.

The "source" directory contains the hdl, "bench" contains the hdl
testbenches used to wrap interfaces, and "tests" contains the cpp
tests.

The root verilator directory sets the c++ version to c++14. Since this project
needs c++17, this needs to be modified in the included verilator file in the
root. (TODO) do this through environment variables.

## Conventions

The system verilog files must always start with `` `default\_nettype
none``. Module names are PascalCase, variable names are camelCase, and
parameters and define statements are UPPER\_CASE. Clock pins and reset
pins are named either "clock" or "reset".


