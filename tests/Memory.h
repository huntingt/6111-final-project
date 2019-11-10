#ifndef _MEMORY
#define _MEMORY

#include <queue>
#include <optional>
#include <vector>
#include <exception>
#include <string>

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
        bus->smTaken 
    }

    void makeRequest(MemoryRequest request) {
        requests.push(request);
    }

    optional<MemoryResponse> readResponse() {
        if (responses.size() == 0) return {};

        auto response = responses.front();
        ressponses.pop();

        return response;
    }

    void step() {
        // see if a transaction finished
        if (bus->smValid && bus->smTaken) {
            requests.pop();
        }

        // put next request on bus
        if (requests.size() > 0) {
            auto request = requests.front();

            bus->msID = request.from;
            bus->msAddress = request.to;
            bus->msWrite = request.write;
            bus->msData = request.data;
            bus->msValid = true;
        } else {
            bus->smValid = false;
        }

        // now check the read channel
        if (bus->smValid) {
            bus->smTaken = true;
            queue.push({bus->smID, bus->smData});
        } else {
            bus->smTaken = false;
        }
    }

    private:
    queue<MemoryRequest> requests;
    queue<MemoryResponse> responses;

    MemoryInterface* bus;
};

typedef optional<MemoryResponse> (* Slave)(MemoryRequest);

class MemorySlave {
    public:
    MemorySlave(MemoryInterface* bus) {
        this->bus = bus;
        bus->msTaken = false;
        bus->smValid = false;
    }
    
    void attach(Slave slave) {
        slaves.push_back(slave);
    }

    void step() {
        // handle requests
        if (bus->msValid) {
            MemoryRequest request =
                {bus->msID, bus->msAddress, bus->msData, bus->msWrite};

            MemoryResponse response;
            bool taken = false;
            for (Slave slave : slaves) {
                auto result = slave(request);

                if (result.has_value()) {
                    if (taken) {
                        throw runtime_error("multiple responses to: " +
                                to_string(request.to));
                    } else {
                        taken = true;
                        response = result.value();
                    }
                }
            }

            if (taken) {
                responses.push(response);
            } else {
                throw runtime_error("invalid request to: " +
                        to_string(request.to));
            }
        } else {
            bus->msTaken = false;
        }

        // handle sending responses
        if (bus->smValid && bus->smTaken) {
            responses.pop();
        }

        if (responses.size() > 0) {
            auto response = responses.front();

            bus->smID = response.from;
            bus->smData = response.data;
            bus->smValid = true;
        } else {
            bus->smValid = false;
        }
    }
    
    private:
    vector<Slave> slaves;
    queue<MemoryResponse> responses;

    MemoryInterface* bus;
};

#endif
