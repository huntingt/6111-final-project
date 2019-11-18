#include "RayTracer.h"

RayTracer::RayTracer(long timeout) {
    this->timeout = timeout;
    cycles = 0;

    dut = new VRayTracerTB(); 
    memoryPort = { 
        reinterpret_cast<int*>(&dut->mmsID),
        reinterpret_cast<int*>(&dut->mmsAddress),
        reinterpret_cast<int*>(&dut->mmsData),
        reinterpret_cast<bool*>(&dut->mmsWrite),
        reinterpret_cast<bool*>(&dut->mmsTaken),
        reinterpret_cast<bool*>(&dut->mmsValid),

        reinterpret_cast<int*>(&dut->msmID),
        reinterpret_cast<int*>(&dut->msmData),
        reinterpret_cast<bool*>(&dut->msmTaken),
        reinterpret_cast<bool*>(&dut->msmValid)
    };
    slave = new MemorySlaveController(&memoryPort);

    configPort = { 
        reinterpret_cast<int*>(&dut->cmsID),
        reinterpret_cast<int*>(&dut->cmsAddress),
        reinterpret_cast<int*>(&dut->cmsData),
        reinterpret_cast<bool*>(&dut->cmsWrite),
        reinterpret_cast<bool*>(&dut->cmsTaken),
        reinterpret_cast<bool*>(&dut->cmsValid),

        reinterpret_cast<int*>(&dut->csmID),
        reinterpret_cast<int*>(&dut->csmData),
        reinterpret_cast<bool*>(&dut->csmTaken),
        reinterpret_cast<bool*>(&dut->csmValid)
    };
    master = new MemoryMaster(&configPort);

    reset();
}

void RayTracer::step() {
    dut->clock = 0;
    dut->eval();

    dut->clock = 1;
    dut->eval();

    slave->step1();
    master->step1();

    dut->eval();
    
    slave->step2();
    master->step2();

    cycles += 1;
}

void RayTracer::reset() {
    dut->reset = 1;
    step();
    dut->reset = 0;
}

void RayTracer::makeRequest(MemoryRequest request) {
    master->makeRequest(request);
}

optional<MemoryResponse> RayTracer::readResponse() {
    return master->readResponse();
}

void RayTracer::waitForInterrupt() {
    for (long i = 0; i < timeout; i++) {
        if (dut->doneInterrupt) {
            return;
        }
        step();
    }

    throw runtime_error("timed out after " + to_string(timeout) + " cycles");
}

void RayTracer::attach(MemorySlave* slave) {
    this->slave->attach(slave);
}

long RayTracer::getCycles() {
    return cycles;
}

void RayTracer::start() {
    int value = readRegister(CONFIG);
    writeRegister(CONFIG, value | 1);
}

void RayTracer::setCamera(Ray q, Ray v, Ray x, Ray y) {
    writeRegister(QX, q.X());
    writeRegister(QY, q.Y());
    writeRegister(QZ, q.Z());

    writeRegister(VX, v.X());
    writeRegister(VY, v.Y());
    writeRegister(VZ, v.Z());

    writeRegister(XX, x.X());
    writeRegister(XY, x.Y());
    writeRegister(XZ, x.Z());
    
    writeRegister(YX, y.X());
    writeRegister(YY, y.Y());
    writeRegister(YZ, y.Z());
}

void RayTracer::setScene(int materialAddress, int treeAddress) {
    if (treeAddress & 0xFF || materialAddress & 0xFF) {
        throw runtime_error("address must be aligned properly");
    }

    writeRegister(MATERIAL, materialAddress >> 8);
    writeRegister(TREE, treeAddress >> 8);
}

void RayTracer::setFrame(int width, int height, int frameAddress) {
    if (frameAddress & 0xFF) {
        throw runtime_error("address must be aligned properly");
    }

    writeRegister(WIDTH, width);
    writeRegister(HEIGHT, height);
    writeRegister(FRAME, frameAddress >> 8);
}

void RayTracer::writeRegister(Register reg, int value) {
    makeRequest({255, base + reg, value, 1});
    step();
}

int RayTracer::readRegister(Register reg) {
    makeRequest({255, base + reg, 0, 0});
    step();

    for (int i = 0; i < 16; i++) {
        step();
        auto response = readResponse();
    
        if (response.has_value()) {
            auto value = response.value();

            if (value.from != 255) {
                throw runtime_error("may have intercepted a message from "
                        + to_string(value.from) + " while trying to read " + to_string(reg));
            }

            return value.data;
        }
    }

    throw runtime_error("timed out while trying to read " + to_string(reg));
}

RayTracer::~RayTracer() {
    delete dut;
    delete slave;
    delete master;
}
