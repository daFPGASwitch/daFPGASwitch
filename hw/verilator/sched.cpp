
#include <iostream>
#include <iomanip>
#include "Vsched.h"
#include <verilated.h>

unsigned char expected[] = { 0x40, 0x79, 0x24, 0x30,   // 0 - 3
			     0x19, 0x12, 0x02, 0x78,   // 4 - 7
			     0x00, 0x10, 0x08, 0x03,   // 8 - B
			     0x46, 0x21, 0x06, 0x0e }; // C - F

int main(int argc, const char ** argv, const char ** env) {
  int exitcode = 0;
  
  Verilated::commandArgs(argc, argv);

  Vsched * dut = new Vsched;  // Instantiate the collatz module

  for (int i = 0 ; i < 16 ; i++) {
    dut->a = i;
    dut->eval();
    std::cout << std::hex << std::setfill('0') << std::setw(1) << (int) dut->a;
    std::cout << ' ' <<  std::setfill('0') << std::setw(2) << (int) dut->y;
    if (dut->y == expected[i])
      std::cout << " OK";
    else {
      std::cout << " INCORRECT expected " << std::setfill('0') << std::setw(2)
		<< (int) expected[i];
      exitcode = 1;
    }
    std::cout << std::endl;
  }
  
  dut->final(); // Stop the simulation
  delete dut;

  return exitcode;
}

