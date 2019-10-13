#include "RayStepper.h"

RayStepper::RayStepper(){
    dut = new VRayStepper();
    cycles = 0;

    // setup device
    vector<int> empty = {0, 0, 0};
    setLower(empty);
    setUpper(empty);
    setPosition(empty);

    dut->clock = 0;
    dut->reset = 0;
    dut->start = 0;

    dut->eval();

    reset();
}

void RayStepper::setLower(vector<int> lower){
    dut->l[0] = lower.at(0);
    dut->l[1] = lower.at(1);
    dut->l[2] = lower.at(2);
}
void RayStepper::setUpper(vector<int> upper){
    dut->u[0] = upper.at(0);
    dut->u[1] = upper.at(1);
    dut->u[1] = upper.at(2);
}

void RayStepper::setPosition(vector<int> q){
    dut->q[0] = q.at(0);
    dut->q[1] = q.at(1);
    dut->q[2] = q.at(2);
}
void RayStepper::setDirection(vector<int> v){
    dut->v[0] = v.at(0);
    dut->v[1] = v.at(1);
    dut->v[2] = v.at(2);
}

bool RayStepper::propagate(vector<int> q, vector<int> v, Octree<bool>* tree){
    const int timeout = 64;

    for(int i = 0; i < timeout; i++){
        if (tree->at(q, bitWidth)){
            return true;
        }

        auto depth = tree->depth(q);
        auto maybeQ = propagate(q, v, depth);

        if (!maybeQ.has_value()) {
            return false;
        }

        q = maybeQ.value();
    }
    throw runtime_error("timed out after " +
                        to_string(timeout) + " cycles");
}

optional<vector<int>>
RayStepper::propagate(vector<int> q, vector<int> v, int n){
    auto bounds = getBounds(q, n, bitWidth);

    setLower(get<0>(bounds));
    setUpper(get<1>(bounds));
    setPosition(q);
    setDirection(v);
    
    // give the start pulse
    dut->start = 1;
    step();
    dut->start = 0;

    const int timeout = 64;
    for (int i = 0; i < timeout; i++) {
        if (dut->done) {
            if(dut->outOfBounds) {
                return {};
            } else {
                return vector<int>{dut->qp[0], dut->qp[1], dut->qp[2]};
            }
        }
        step();
    }

    throw runtime_error("timed out after " +
            to_string(timeout) + " cycles");
    
}

tuple<vector<int>, vector<int>>
RayStepper::getBounds(vector<int> q, int n, int bitWidth){
    const int mask = ~(int)(pow(2, bitWidth - n) - 1);

    vector<int> lower;
    vector<int> upper;

    for (int position : q) {
        lower.push_back(position &  mask);
        upper.push_back(position | ~mask);
    }

    return make_tuple(lower, upper);
}

vector<int> RayStepper::normalize(vector<int> v, int bitWidth){
    const int unit = 0.9 * pow(2, bitWidth) - 1;
    
    double norm = 0;
    for(int vi : v){
        norm += pow(vi, 2);
    }

    vector<int> result;
    for(int vi : v){
        result.push_back(vi / norm * unit);
    }

    return result;
}

void RayStepper::reset(){
    dut->reset = 1;
    step();
    dut->reset = 0;
}
void RayStepper::step(){
    dut->clock = 1;
    dut->eval();
    dut->clock = 0;
    cycles += 1;
}
    
long RayStepper::getCycles(){ return cycles; }

RayStepper::~RayStepper(){
    dut->final();
    delete dut;
}
