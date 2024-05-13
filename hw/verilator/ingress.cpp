#include <iostream>
#include "Vingress.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

using namespace std;

unsigned int packet_in[] = {0b00000000001000000000000000000000, 0b00000000000000000000000000000001, 0b00000000000000000000000000000000, 0b00000000000000000000000000000000, 0b00000000000000000000000000000001, 0b00000000000000000000000000000001, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b00000000010000000000000000000000, 0b00000000000000000000000000000001, 0b00000000000000000000000000000000, 0b00000000000000000000000000000000, 0b00000000000000000000000000000001, 0b00000000000000000000000000000001, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111};


int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  // Treat the argument on the command-line as the place to start
  int n;
  if (argc > 1 && argv[1][0] != '+') n = atoi(argv[1]);
  else n = 4; // Default

  Vingress * dut = new Vingress;  // Instantiate the packet_gen module

  // Enable dumping a VCD file
  
  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99); // Verilator should trace signals up to 99 levels deep
  tfp->open("ingress.vcd");

  // std::cout << dut->n; // Print the starting value of the sequence

  bool last_clk = true;
  int time;
  int iter = 0;
  for (time = 0 ; time < 1000; time += 10) {
    std::cout << "time: " << time << std::endl; 
    dut->clk = ((time % 20) >= 10) ? 0 : 1; // Simulate a 50 MHz clock
    if ((time % 20) >= 10) {
      new_packet_en = 0;
      sched_sel = 0;
      sched_done = 0;
      sched_en = 0;
      if(time < 640) {
        dut->packet_en = 1;
        dut->packet_in = packet_in[iter];
      } else {
	dut -> packet_en = 0; 
      }

	iter++;
    }
    
    iter = (iter == 32) ? 0 : iter;
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
