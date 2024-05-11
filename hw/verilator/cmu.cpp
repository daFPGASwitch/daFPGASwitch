#include <iostream>
#include "Vcmu.h"     // What is this??
#include <verilated.h>
#include <verilated_vcd_c.h>

using namespace std;

unsigned short remaining_packet_length[] = {0b000100, 0b000011, 0b000010, 0b000001};
unsigned short raddr[] = {0b0000000000, 0b0000000001, 0b0000000010, 0b0000000011};

int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  // Treat the argument on the command-line as the place to start
  int n;
  if (argc > 1 && argv[1][0] != '+') n = atoi(argv[1]);
  else n = 4; // Default

  Vcmu * dut = new Vcmu;  // Instantiate the sched module

  // Enable dumping a VCD file
  
  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99); // Verilator should trace signals up to 99 levels deep
  tfp->open("cmu.vcd");

  dut->wen = 0;
  dut->remaining_packet_length = 0;
  dut->free_en = 0;
  dut->raddr = 0;

  // std::cout << dut->n; // Print the starting value of the sequence

  bool last_clk = true;
  int time;
  int iter = 0;
  for (time = 0 ; time < 1000; time += 10) {
    std::cout << "time: " << time << std::endl; 
    dut->clk = ((time % 20) >= 10) ? 0 : 1; // Simulate a 50 MHz clock
    if (time > 80) {
	if ((time % 160) == 0) {
		dut->wen = 1;
        dut->remaining_packet_length = remaining_packet_length[iter];
        //dut->free_en = 0;
        dut->raddr = raddr[iter];

		iter++;
    } else if (time % 160 == 20) {
		dut->wen = 0;
    } else if (time % 160 == 40) {
		dut->free_en = 0;
	} else if (time % 160 == 60) {
		dut->free_en = 0;
	}
	}

	iter = (iter == 4) ? 0 : iter;
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
