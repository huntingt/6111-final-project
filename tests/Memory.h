#ifndef _MEMORY
#define _MEMORY

#include <queue>
#include <optional>
#include <vector>
#include <exception>
#include <string>
#include <tuple>
#include <fstream>
#include <algorithm>

using namespace std;

struct MemoryInterface {
    int  *msID;
    int  *msAddress;
    int  *msData;
    bool *msWrite;
    bool *msTaken;
    bool *msValid;

    int  *smID;
    int  *smData;
    bool *smTaken;
    bool *smValid;
};

struct MemoryRequest {
    int from;
    int to;
    int data;
    int write;
};

struct MemoryResponse {
    int from;
    int data;
};

class MemoryMaster {
    public:
    MemoryMaster(MemoryInterface* bus) {
        this->bus = bus;
        *bus->smTaken = false;
        *bus->msValid = false;
    }

    void makeRequest(MemoryRequest request) {
        requests.push(request);
    }

    optional<MemoryResponse> readResponse() {
        if (responses.size() == 0) return {};

        auto response = responses.front();
        responses.pop();

        return response;
    }

    void step() {
        // see if a transaction finished
        if (*bus->msValid && *bus->msTaken) {
            requests.pop();
        }

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

    private:
    queue<MemoryRequest> requests;
    queue<MemoryResponse> responses;

    MemoryInterface* bus;
};

class MemorySlave {
    public:
    virtual bool claim(int address) = 0;
    virtual optional<int> step(int address, int data, bool write) = 0;
};

class MemoryArray : public MemorySlave {
    public:
    MemoryArray(int base, int size) {
        this->base = base;
        this->size = size;
        memory.resize(size);
    }

    bool claim(int address) {
        int relative = address - base;
        return relative >= 0 && relative < size;
    }

    optional<int> step(int address, int data, bool write) {
        int relative = address - base;
        
        if (write) {
            memory.at(relative) = data;
        } else {
            return memory.at(relative);
        }

        return {};
    }

    void loadFile(string filename) {
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

    void write(int i, int value) {
        memory.at(i) = value;
    }

    int read(int i) {
        return memory.at(i);
    }

    private:
    int base;
    int size;
    vector<int> memory;
};

class MemorySlaveController {
    public:
    MemorySlaveController(MemoryInterface* bus) {
        this->bus = bus;
        *bus->msTaken = false;
        *bus->smValid = false;
    }
    
    void attach(MemorySlave* slave) {
        slaves.push_back(slave);
    }

    void step() {
        // handle requests
        if (*bus->msValid) {
            MemoryRequest request =
                {*bus->msID, *bus->msAddress, *bus->msData, *bus->msWrite};

            bool taken = false;
            for (MemorySlave* slave : slaves) {
                if (slave->claim(request.to)) {
                    auto response = slave->step(request.to, request.data, request.write);
                    
                    if (response.has_value()) {
                        responses.push({request.from, response.value()});
                    }

                    taken = true;
                }
            }
            *bus->msTaken = taken;
        } else {
            *bus->msTaken = false;
        }

        // handle sending responses
        if (*bus->smValid && *bus->smTaken) {
            responses.pop();
        }

        if (responses.size() > 0) {
            auto response = responses.front();

            *bus->smID = response.from;
            *bus->smData = response.data;
            *bus->smValid = true;
        } else {
            *bus->smValid = false;
        }
    }
    
    private:
    vector<MemorySlave*> slaves;
    queue<MemoryResponse> responses;

    MemoryInterface* bus;
};

#endif
