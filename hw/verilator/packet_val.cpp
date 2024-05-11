#include <iostream>
#include "Vpacket_val.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

using namespace std;
unsigned char meta_en[] = {0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b0};

unsigned char send_en[] = {0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b0, 0b1};

unsigned int meta_in[] = {0b00000000010000000000000000000000, 0b00000000000000000000000000000011, 0b00000000000000000000000000000000, 0b00000000000000000000000000000000, 0b00000000000000000000000000000001, 0b00000000000000000000000000000001, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111, 0b11111111111111111111111111111111};


int main(int argc, const char ** argv, const char ** env) {
  Verilated::commandArgs(argc, argv);

  // Treat the argument on the command-line as the place to start
  int n;
  if (argc > 1 && argv[1][0] != '+') n = atoi(argv[1]);
  else n = 4; // Default

  Vpacket_val * dut = new Vpacket_val;  // Instantiate the packet_gen module

  // Enable dumping a VCD file
  
  Verilated::traceEverOn(true);
  VerilatedVcdC * tfp = new VerilatedVcdC;
  dut->trace(tfp, 99); // Verilator should trace signals up to 99 levels deep
  tfp->open("packet_val.vcd");

  // std::cout << dut->n; // Print the starting value of the sequence

  bool last_clk = true;
  int time;
  int iter = 0;
  for (time = 0 ; time < 1000; time += 10) {
    std::cout << "time: " << time << std::endl; 
    dut->clk = ((time % 20) >= 10) ? 0 : 1; // Simulate a 50 MHz clock
    if ((time % 20) >= 10) {
      if(time < 320) {
        dut->data_en = meta_en[iter];
        dut->send_en = send_en[iter];
        dut->data_in = meta_in[iter];
      } else {
	dut -> send_en = send_en[16];
	dut -> data_en = 0b0; 
      }

	iter++;
    }
    
    iter = (iter == 20) ? 0 : iter;
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
