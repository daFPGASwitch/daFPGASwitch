#include <iostream>
#include "Vsimple_switch.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

using namespace std;

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  // Treat the argument on the command-line as the place to start
  int n;
  if (argc > 1 && argv[1][0] != '+') n = atoi(argv[1]);
  else n = 4; // Default

  Vsimple_switch * dut = new Vsimple_switch;  // Instantiate the packet_gen module

  // Enable dumping a VCD file
  
  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99); // Verilator should trace signals up to 99 levels deep
  tfp->open("simple_switch.vcd");

  // std::cout << dut->n; // Print the starting value of the sequence

  bool last_clk = true;
  int time;
  int iter = 0;
  dut->reset = 0;

  for (time = 0 ; time < 10000; time += 10) {
    std::cout << "time: " << time << std::endl; 
    dut->clk = ((time % 20) >= 10) ? 0 : 1; // Simulate a 50 MHz clock
    if (time == 40) {
      dut->chipselect = 1;
      dut->address = 2;
      dut -> write = 1;
      dut -> read  = 0;
      dut->writedata  = 0b01010000010000000000000000000000;
    }
    if (time == 60) {
      dut -> chipselect = 0;
    }

  if (time == 540) {
      dut->chipselect = 1;
      dut->address = 2;
      dut -> write = 1;
      dut -> read  = 0;
      dut->writedata  = 0b01010000100000000000000000000000;
    }
    if (time == 560) {
      dut -> chipselect = 0;
    }


    if(time == 1000) {
      dut -> write = 1;
      dut -> chipselect = 1;
      dut -> read = 0;
      dut -> address = 0;
      dut->writedata = 2;
    }
    if(time == 1020) {
      dut -> chipselect = 0;
    }
  
    if(time == 2000) {
      dut -> write = 0;
      dut -> chipselect = 1;
      dut -> read = 1;
      dut -> address = 2;
    }
    if(time == 2020) {
      dut -> chipselect = 0;
    }

    if(time == 3000) {
      dut -> write = 0;
      dut -> chipselect = 1;
      dut -> read = 1;
      dut -> address = 2;
    }
    if(time == 3020) {
      dut -> chipselect = 0;
    }

    dut->eval();     // Run the simulation for a cycle
    tfp->dump(time); // Write the VCD file for this cycle
  }

  std::cout << std::endl;

  // Once "done" is received, run a few more clock cycles
  
  // for (int k = 0 ; k < 4 ; k++, time += 10) {
  //   dut->clk = ((time % 20) >= 10) ? 1 : 0;
  //     dut->eval();
  //     tfp->dump(time);
  // }
  
  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  return 0;
}
