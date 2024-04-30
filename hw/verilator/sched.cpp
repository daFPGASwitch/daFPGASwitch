#include <iostream>
#include "Vsched.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  // Treat the argument on the command-line as the place to start
  int n;
  if (argc > 1 && argv[1][0] != '+') n = atoi(argv[1]);
  else n = 7; // Default

  Vsched * dut = new Vsched;  // Instantiate the sched module

  // Enable dumping a VCD file
  
  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99); // Verilator should trace signals up to 99 levels deep
  tfp->open("sched.vcd");

  // Initial values
  
  dut->voq_empty_0 = 0;
  dut->voq_empty_1 = 1;
  dut->voq_empty_2 = 2;
  dut->voq_empty_3 = 3;

  // std::cout << dut->n; // Print the starting value of the sequence

  bool last_clk = true;
  int time;
  for (time = 0 ; time < 10000 ; time += 10) {
    dut->clk = ((time % 20) >= 10) ? 1 : 0; // Simulate a 50 MHz clock
    // if (time == 20) dut->go = 1; // Pulse "go" for two cycles
    // if (time == 30) dut->go = 0;

    dut->eval();     // Run the simulation for a cycle
    tfp->dump(time); // Write the VCD file for this cycle

    // if (dut->clk && !last_clk && !dut->go) {
    //   if (time >= 60) std::cout << ' ' << dut->dout; // Print the next value
    //   if (dut->done) break; // Stop once "done" appears
    // }
    last_clk = dut->clk;
  }

  std::cout << std::endl;

  // Once "done" is received, run a few more clock cycles
  
  for (int k = 0 ; k < 4 ; k++, time += 10) {
    dut->clk = ((time % 20) >= 10) ? 1 : 0;
      dut->eval();
      tfp->dump(time);
  }
  
  tfp->close(); // Stop dumping the VCD file
  delete tfp;

  dut->final(); // Stop the simulation
  delete dut;

  return 0;
}
