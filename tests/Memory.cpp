#include "Memory.h"

MemoryMaster::MemoryMaster(MemoryInterface* bus) {
    this->bus = bus;
    *bus->smTaken = false;
    *bus->msValid = false;
}

void MemoryMaster::makeRequest(MemoryRequest request) {
    requests.push(request);
}

optional<MemoryResponse> MemoryMaster::readResponse() {
    if (responses.size() == 0) return {};

    auto response = responses.front();
    responses.pop();

    return response;
}

void MemoryMaster::step1() {
    // put next request on bus
    if (requests.size() > 0) {
        auto request = requests.front();

        *bus->msID = request.from;
        *bus->msAddress = request.to;
        *bus->msWrite = request.write;
        *bus->msData = request.data;
        *bus->msValid = true;
    } else {
        *bus->msValid = false;
    }

    // now check the read channel
    if (*bus->smValid) {
        *bus->smTaken = true;
        responses.push({*bus->smID, *bus->smData});
    } else {
        *bus->smTaken = false;
    }
}

void MemoryMaster::step2() {
    // see if a transaction finished
    if (*bus->msValid && *bus->msTaken) {
        requests.pop();
    }
}

MemoryArray::MemoryArray(int base, int size, int latency) {
    this->base = base;
    this->size = size;
    this->latency = latency;
    memory.resize(size);
}

bool MemoryArray::claim(int address) {
    int relative = address - base;
    return relative >= 0 && relative < size;
}

optional<tuple<int, int>> MemoryArray::step(int address, int data, bool write) {
    int relative = address - base;
    
    if (write) {
        memory.at(relative) = data;
    } else {
        return tuple<int, int>(latency, memory.at(relative));
    }

    return {};
}

void MemoryArray::loadFile(string filename) {
    const int size = memory.size();

    ifstream file(filename);
    
    string line;
    int i = 0;
    while(getline(file, line)){
        if (line == "" || line.at(0) == '#') continue;
        
        //remove underscores
        line.erase(remove(line.begin(), line.end(), '_'), line.end());

        memory.at(i) = stoi(line, nullptr, 0);
        i++;
    }
}

void MemoryArray::write(int i, int value) {
    memory.at(i) = value;
}

int MemoryArray::read(int i) {
    return memory.at(i);
}

MemorySlaveController::MemorySlaveController(MemoryInterface* bus) {
    this->bus = bus;
    *bus->msTaken = false;
    *bus->smValid = false;
    currentResponse = -1;
}

void MemorySlaveController::attach(MemorySlave* slave) {
    slaves.push_back(slave);
}

void MemorySlaveController::step1() {
    // handle requests
    if (*bus->msValid) {
        MemoryRequest request =
            {*bus->msID, *bus->msAddress, *bus->msData, *bus->msWrite};

        bool taken = false;
        for (MemorySlave* slave : slaves) {
            if (slave->claim(request.to)) {
                auto result = slave->step(request.to, request.data, request.write);
                
                if (result.has_value()) {
                    auto [latency, response] = result.value();

                    responses.push_back({latency, {request.from, response}});
                }

                taken = true;
            }
        }
        *bus->msTaken = taken;
    } else {
        *bus->msTaken = false;
    }

    // decrement latency counter on each response
    for (int i = 0; i < responses.size(); i++) {
        auto [latency, response] = responses.at(i);
        
        if (currentResponse == -1 && latency == 0) {
            currentResponse = i;
        }

        if (latency > 0) {
            responses.at(i) = {latency - 1, response};
        }
    }

    // start transaction on slave
    if (currentResponse >= 0) {
        auto [latency, response] = responses.at(currentResponse);

        *bus->smID = response.from;
        *bus->smData = response.data;
        *bus->smValid = true;
    } else {
        *bus->smValid = false;
    }
}

void MemorySlaveController::step2() {
    // attempt to finish transaction
    if (*bus->smValid && *bus->smTaken) {
        responses.erase(responses.begin() + currentResponse);
        currentResponse = -1;
    }
}
