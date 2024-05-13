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
      dut->writedata  = 0b01110000010000000000000000000000;
    }
    if (time == 60) {
      dut -> chipselect = 0;
    }

  if (time == 1540) {
      dut->chipselect = 1;
      dut->address = 1;
      dut -> write = 1;
      dut -> read  = 0;
      dut->writedata  = 0b00110000100000000000000000000000;
    }
    if (time == 1560) {
      dut -> chipselect = 0;
    }

  
    if (time == 2440) {
      dut->chipselect = 1;
      dut->address = 3;
      dut -> write = 1;
      dut -> read  = 0;
      dut->writedata  = 0b10110000100000000000000000000000;
    }
    if (time == 2460) {
      dut -> chipselect = 0;
      dut -> write = 0;
    }

    if (time == 3040) {
      dut->chipselect = 1;
      dut->address = 1;
      dut -> write = 1;
      dut -> read  = 0;
      dut->writedata  = 0b00100000100000000000000000000000;
    }

    if (time == 3060) {
      dut -> chipselect = 0;
    }

        if (time == 3040) {
      dut->chipselect = 1;
      dut->address = 1;
      dut -> write = 1;
      dut -> read  = 0;
      dut->writedata  = 0b00100000100000000000000000000000;
    }

    if (time == 3560) {
      dut -> chipselect = 0;
    }
            if (time == 3040) {
      dut->chipselect = 1;
      dut->address = 2;
      dut -> write = 1;
      dut -> read  = 0;
      dut->writedata  = 0b01100000100000000000000000000000;
    }
    if (time == 3060) {
      dut -> chipselect = 0;
      dut -> write = 0;
    }



    if(time == 4000) {
      dut -> write = 1;
      dut -> chipselect = 1;
      dut -> read = 0;
      dut -> address = 0;
      dut->writedata = 2;
    }
    if(time == 4020) {
      dut -> chipselect = 0;
    }
  
    if(time == 5000) {
      dut -> write = 0;
      dut -> chipselect = 1;
      dut -> read = 1;
      dut -> address = 4;
    }
    if(time == 5020) {
      dut -> chipselect = 0;
    }

    if(time == 7000) {
      dut -> write = 0;
      dut -> chipselect = 1;
      dut -> read = 1;
      dut -> address = 4;
    }
    if(time == 7020) {
      dut -> chipselect = 0;
    }

    if(time == 8000) {
      dut -> write = 0;
      dut -> chipselect = 1;
      dut -> read = 1;
      dut -> address = 3;
    }
    if(time == 8020) {
      dut -> chipselect = 0;
    }
    if(time == 9000) {
      dut -> write = 0;
      dut -> chipselect = 1;
      dut -> read = 1;
      dut -> address = 3;
    }
    if(time == 9020) {
      dut -> chipselect = 0;
      dut -> read = 0;
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
