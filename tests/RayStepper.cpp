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

tuple<vector<int>, int> propogate(vector<int> q, int n){
    
}

tuple<vector<int>, vector<int>>
RayStepper::getBounds(vector<int> q, int n){
    const int mask = ~(int)(pow(2, bitWidth - n) - 1);

    vector<int> lower;
    vector<int> upper;

    for (int position : q) {
        lower.push_back(position &  mask);
        upper.push_back(position | ~mask);
    }

    return make_tuple(lower, upper);
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
}
    
long RayStepper::cycles(){ return cycle; }

RayStepper::~RayStepper(){
    dut->final();
    delete dut;
}
