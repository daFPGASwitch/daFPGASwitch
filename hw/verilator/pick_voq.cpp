#include <iostream>
#include <iomanip>
#include "Vpick_voq.h"
#include <verilated.h>
#include <bitset>

unsigned char input_voq_empty[] = {0b1110, 0b0001, 0b0011, 0b1111, 0b0000, 0b1110, 0b0111};

unsigned char input_start_voq_num[] = {3, 3, 1, 2, 1, 1, 0};

unsigned char output_all_empty[] = {0, 0, 0, 1, 0, 0, 0};

unsigned char output_first_non_empty_num[] = {0, 3, 2, 3, 1, 0, 3};


int main(int argc, const char ** argv, const char ** env) {
  int exitcode = 0;
  
  Verilated::commandArgs(argc, argv);

  Vpick_voq * dut = new Vpick_voq;  // Instantiate the collatz module

  for (int i = 0 ; i < 6 ; i++) {
    dut->voq_empty = input_voq_empty[i];
    dut->start_voq_num = input_start_voq_num[i];
    dut->eval();
    std::bitset<4> x(dut->voq_empty);
    std::cout << "voq_empty: " << x << '\n';
    std::cout << "start_voq_num: " << (int) dut->start_voq_num << '\n';
    
    if (dut->all_empty == output_all_empty[i] && (dut->first_non_empty_num == output_first_non_empty_num[i] || dut->all_empty == 1))
        std::cout << " OK" << '\n';
    else {
        std::cout << " INCORRECT expected all_empty and first_non_empty_num " << std::endl;
        std::cout << "all_empty: " << (int) dut->all_empty << '\n';
        std::cout << "first_non_empty_num: " << (int) dut->first_non_empty_num << '\n';
        exitcode = 1;
    }
    std::cout << std::endl;
  }
  
  dut->final(); // Stop the simulation
  delete dut;

  return exitcode;
}
