#include <iostream>
#include "Vvmu.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

using namespace std;

int main(int argc, const char ** argv, const char ** env) {
    Verilated::commandArgs(argc, argv);
    Vvmu * dut = new Vvmu;

    Verilated::traceEverOn(true);
    VerilatedVcdC * tfp = new VerilatedVcdC;
    dut->trace(tfp, 99); // Verilator should trace signals up to 99 levels deep
    tfp->open("vmu.vcd");


    tfp->close(); // Stop dumping the VCD file
    delete tfp;

    dut->final(); // Stop the simulation
    delete dut;
    return 0;
}