#include <iostream>
#include "VdaFPGASwitch.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

using namespace std;
unsigned char meta_en[] = {0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1};

unsigned char send_en[] = {0b0, 0b0, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1};

unsigned int meta_in[] = {0b01110000010000000000000000000000, 0b01110000100000000000000000000000, 0b01110000110000000000000000000000, 0b01110001000000000000000000000000, 0b01110001010000000000000000000000, 0b0111000000001000, 0b0111000000001001, 0b0111000000001010};


int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  // Treat the argument on the command-line as the place to start
  int n;
  if (argc > 1 && argv[1][0] != '+') n = atoi(argv[1]);
  else n = 4; // Default

  VdaFPGASwitch * dut = new VdaFPGASwitch;  // Instantiate the packet_gen module

  // Enable dumping a VCD file
  
  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99); // Verilator should trace signals up to 99 levels deep
  tfp->open("daFPGASwitch.vcd");

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
      dut->address = 1;
      dut -> write = 1;
      dut -> read  = 0;
      dut->writedata  = 0b01110000010000000000000000000000;
    }
    if (time == 60) {
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
      dut -> address = 1;
    }
    if(time == 2020) {
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
