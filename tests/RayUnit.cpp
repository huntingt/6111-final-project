#include "RayUnit.h"

RayUnit::RayUnit(int timeout) {
    this->timeout = timeout;
    cycles = 0;

    dut = new VRayUnitTB();
    interface = { 
        reinterpret_cast<int*>(&dut->msID),
        reinterpret_cast<int*>(&dut->msAddress),
        reinterpret_cast<int*>(&dut->msData),
        reinterpret_cast<bool*>(&dut->msWrite),
        reinterpret_cast<bool*>(&dut->msTaken),
        reinterpret_cast<bool*>(&dut->msValid),

        reinterpret_cast<int*>(&dut->smID),
        reinterpret_cast<int*>(&dut->smData),
        reinterpret_cast<bool*>(&dut->smTaken),
        reinterpret_cast<bool*>(&dut->smValid)
    };
    controller = new MemorySlaveController(&interface);
    
    dut->start = 0;
    dut->flush = 0;

    reset();
}

void RayUnit::reset() {
    dut->reset = 1;
    step();
    dut->reset = 0;
}

void RayUnit::attach(MemorySlave* slave) {
    controller->attach(slave);
}

void RayUnit::step() {
    dut->clock = 0;
    dut->eval();
     
    dut->clock = 1;
    dut->eval();

    controller->step1();
    dut->eval();
    controller->step2();
}

void RayUnit::flush() {
    dut->flush = 1;
    step();
    dut->flush = 0;
}

void RayUnit::setRender(int materialAddress, int treeAddress) {
    dut->materialAddress = materialAddress;
    dut->treeAddress = treeAddress;
}

void RayUnit::render(vector<int> position, vector<int> direction, int address) {
    dut->rayQ[0] = position.at(0);
    dut->rayQ[1] = position.at(1);
    dut->rayQ[2] = position.at(2);

    dut->rayV[0] = direction.at(0);
    dut->rayV[1] = direction.at(1);
    dut->rayV[2] = direction.ad(2);

    dut->pixelAddress = address;

    dut->start = 1;
    step();
    dut->start = 0;

    for(int step = 0; step < timeout; step++) {
        if (dut->!busy) return;
        step();
    }

    throw runtime_error("render timed out after " + to_string(timeout) + " cycles");
}

long RayUnit::getCycles() {
    return cycles;
}

RayUnit::~RayUnit() {
    delete dut;
    delete controller;
}
