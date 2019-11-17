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
}

void RayTracer::reset() {
    dut->reset = 1;
    dut->step();
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
    }

    throw runtime_error("timed out after " + to_string(timeout) + " cycles");
}

void RayTracer::attach(MemorySlave* slave) {
    this->slave->attach(slave);
}

long RayTracer::getCycles() {
    return cycles;
}

RayTracer::~RayTracer() {
    delete dut;
    delete slave;
    delete master;
}
