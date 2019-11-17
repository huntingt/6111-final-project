#include "RayGenerator.h"

RayGenerator::RayGenerator(int timeout) {
    this->timeout = timeout;
    dut = new VRayGenerator();

    dut->start = 0;
    dut->rayReady = 0;
    dut->rayBusy = 0;
    dut->normalize = 1;
    cycles = 0;

    reset();
}

void RayGenerator::setCamera(Ray v, Ray x, Ray y) {
    dut->cameraV[0] = v.X();
    dut->cameraV[1] = v.Y();
    dut->cameraV[2] = v.Z();

    dut->cameraX[0] = x.X();
    dut->cameraX[1] = x.Y();
    dut->cameraX[2] = x.Z();

    dut->cameraY[0] = y.X();
    dut->cameraY[1] = y.Y();
    dut->cameraY[2] = y.Z();
}

void RayGenerator::setFrame(int width, int height, int frameAddress) {
    dut->width = width;
    dut->height = height;
    dut->frameAddress = frameAddress;
}

void RayGenerator::start() {
    while(!dut->ready) {
        step();
    }

    dut->start = 1;
    step();
    dut->start = 0;
}

tuple<int, Ray> RayGenerator::getRay() {
    dut->rayReady = 1;
    for (int i = 0; i < timeout; i++) {
        if (dut->rayStart) {
            tuple<int, Ray> result =
                {dut->rayAddress, Ray(dut->rayV[0], dut->rayV[1], dut->rayV[2])};
            
            step();
            dut->rayReady = 0;

            return result;
        }

        step();
    }

    throw runtime_error("getRay() timeout after " + to_string(timeout) + " cycles");
}

vector<tuple<int, Ray>> RayGenerator::getRays() {
    vector<tuple<int, Ray>> result;
    while(busy()) {
        result.push_back(getRay());
    }
    return result;
}

bool RayGenerator::ready() {
    return dut->ready;
}
bool RayGenerator::busy() {
    return dut->busy;
}

void RayGenerator::reset() {
    dut->reset = 1;
    step();
    dut->reset = 0;
}

void RayGenerator::step() {
    dut->clock = 0;
    dut->eval();
    dut->clock = 1;
    dut->eval();

    cycles += 1;
}

long RayGenerator::getCycles() {
    return cycles;
}

RayGenerator::~RayGenerator() {
    delete dut;
}
