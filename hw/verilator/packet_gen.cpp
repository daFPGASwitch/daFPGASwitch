#include <iostream>
#include "Vpacket_gen.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

using namespace std;
unsigned char meta_en[] = {0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1};

unsigned char send_en[] = {0b0, 0b0, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1};

unsigned int meta_in[] = {0b0111000000000001, 0b0111000000000010, 0b0111000000000011, 0b0111000000000100, 0b0111000000000101, 0b0111000000000110, 0b0111000000000111, 0b0111000000001000, 0b0111000000001001, 0b0111000000001010};


int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  // Treat the argument on the command-line as the place to start
  int n;
  if (argc > 1 && argv[1][0] != '+') n = atoi(argv[1]);
  else n = 4; // Default

  Vpacket_gen * dut = new Vpacket_gen;  // Instantiate the packet_gen module

  // Enable dumping a VCD file
  
  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99); // Verilator should trace signals up to 99 levels deep
  tfp->open("packet_gen.vcd");

  // std::cout << dut->n; // Print the starting value of the sequence

  bool last_clk = true;
  int time;
  int iter = 0;
  for (time = 0 ; time < 1000; time += 10) {
    std::cout << "time: " << time << std::endl; 
    dut->clk = ((time % 20) >= 10) ? 0 : 1; // Simulate a 50 MHz clock
    if ((time % 20) >= 10) {
      if(time < 100) {
        dut->meta_en = meta_en[iter];
        dut->send_en = send_en[iter];
        dut->meta_in = meta_in[iter];
      } else {
	dut -> send_en = send_en[5];
	dut -> meta_en = 0b0; 
      }

	iter++;
    }
    
    iter = (iter == 10) ? 0 : iter;
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
