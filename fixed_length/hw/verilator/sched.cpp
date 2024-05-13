#include <iostream>
#include "Vsched.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

using namespace std;

unsigned short is_busy[] = {0b1110, 0b1110, 0b1110, 0b0000};

unsigned short busy_voq_num[] = {0b11100111, 0b11100111, 0b11100111, 0b00000000};

unsigned short voq_empty[] = {0b0000000000001110, 0b0000000000000000, 0b0000000000001111, 0b1011011111101101};


int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  // Treat the argument on the command-line as the place to start
  int n;
  if (argc > 1 && argv[1][0] != '+') n = atoi(argv[1]);
  else n = 4; // Default

  Vsched * dut = new Vsched;  // Instantiate the sched module

  // Enable dumping a VCD file
  
  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99); // Verilator should trace signals up to 99 levels deep
  tfp->open("sched.vcd");

  dut->sched_en = 0;
  dut->is_busy = 0;
  dut->busy_voq_num = 0;
  dut->voq_empty = 0;

  // std::cout << dut->n; // Print the starting value of the sequence

  bool last_clk = true;
  int time;
  int iter = 0;
  for (time = 0 ; time < 1000; time += 10) {
    std::cout << "time: " << time << std::endl; 
    dut->clk = ((time % 20) >= 10) ? 1 : 0; // Simulate a 50 MHz clock
    if ((time % 160) == 20) {
      if (iter < n) {
        dut->sched_en = 0;
        dut->is_busy = is_busy[iter];
        dut->busy_voq_num = busy_voq_num[iter];
        dut->voq_empty = voq_empty[iter];
      }
    } else if ((time % 160) == 30 || (time % 160) == 40) {
      if (iter < n) {
        dut->sched_en = 1;
      }
    } else {
      dut->sched_en = 0;
      if ((time % 160) == 50) {
          iter += 1;
          cout << iter << endl;
      }
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
