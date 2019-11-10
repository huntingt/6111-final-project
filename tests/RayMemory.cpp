#include "RayMemory.h"

RayMemory::RayMemory(int timeout, int materialAddress, int treeAddress) {
    this->timeout = timeout;
    cycles = 0;

    // setup system
    dut = new VRayMemoryTB();
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

    dut->reset = 0;
    dut->flush = 0;
    dut->traverse = 0;
    dut->writePixel = 0;

    dut->materialAddress = materialAddress;
    dut->treeAddress = treeAddress;

    reset();
    flush();
}

void RayMemory::reset() {
    dut->reset = 1;
    step();
    dut->reset = 0;
}

void RayMemory::attach(MemorySlave* slave) {
    controller->attach(slave);
}

void RayMemory::step() {
    dut->clock = 0;
    dut->eval();
    dut->clock = 1;
    dut->eval();
}

void RayMemory::flush() {
    dut->flush = 1;
    step();
    dut->flush = 0;
}

tuple<int, int> RayMemory::traverse(vector<int> position) {
    dut->position[0] = position.at(0);
    dut->position[1] = position.at(1);
    dut->position[2] = position.at(2);
    dut->traverse = 1;

    step();

    dut->traverse = 0;

    for(int i = 0; i < timeout; i++) {
        if (dut->ready) return {dut->depth, dut->material};
        step();
    }

    throw runtime_error("traverse timed out after " + to_string(timeout));
}

void RayMemory::writePixel(int pixelAddress, int pixel) {
    dut->pixelAddress = pixelAddress;
    dut->pixel = pixel;
    dut->writePixel = 1;

    step();

    dut->writePixel = 0;

    for(int i = 0; i < timeout; i++) {
        if (dut->ready) return;
        step();
    }

    throw runtime_error("writePixel timed out after " + to_string(timeout));
}

long RayMemory::getCycles() {
    return cycles;
}

RayMemory::~RayMemory() {
    delete dut;
    delete controller;
}
