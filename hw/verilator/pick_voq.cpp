#include <iostream>
#include <iomanip>
#include "Vpick_voq.h"
#include <verilated.h>
#include <bitset>

unsigned char input_voq_empty[] = {0b1110, 0b0001, 0b0011, 0b1111, 0b0000, 0b1110, 0b0111, 0b0100, 0b0110, 0b0000};

unsigned char input_voq_picked[] = {0b1110, 0b0001, 0b0011, 0b1111, 0b0000, 0b1110, 0b0111, 0b1000, 0b1001, 0b1111};

unsigned char input_start_voq_num[] = {3, 3, 1, 2, 1, 1, 0, 2, 0, 0};

unsigned char output_no_available_voq[] = {0, 0, 0, 1, 0, 0, 0, 0, 1, 1};

unsigned char output_voq_to_pick[] = {0, 3, 2, 3, 1, 0, 3, 0, 0, 0};


int main(int argc, const char ** argv, const char ** env) {
  int exitcode = 0;
  
  Verilated::commandArgs(argc, argv);

  Vpick_voq * dut = new Vpick_voq;  // Instantiate the collatz module

  for (int i = 0 ; i < 8; i++) {
    dut->voq_empty = input_voq_empty[i];
    dut->start_voq_num = input_start_voq_num[i];
    dut->voq_picked = input_voq_picked[i];
    dut->eval();
    std::bitset<4> x(dut->voq_empty);
    std::cout << "voq_empty: " << x << '\n';
    std::bitset<4> y(dut->voq_picked);
    std::cout << "voq_picked: " << y << '\n';

    std::cout << "start_voq_num: " << (int) dut->start_voq_num << '\n';
    
    if (dut->no_available_voq == output_no_available_voq[i] && (dut->voq_to_pick == output_voq_to_pick[i] || dut->no_available_voq == 1))
        std::cout << " OK" << '\n';
    else {
        std::cout << " INCORRECT expected no_available_voq and voq_to_pick " << std::endl;
        exitcode = 1;
    }
    std::cout << "no_available_voq: " << (int) dut->no_available_voq << '\n';
    std::cout << "voq_to_pick: " << (int) dut->voq_to_pick << '\n';
    std::cout << std::endl;
  }
  
  dut->final(); // Stop the simulation
  delete dut;

  return exitcode;
}
