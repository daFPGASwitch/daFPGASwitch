#include <iostream>
#include <iomanip>
#include "Vcrossbar.h"
#include <verilated.h>
#include <bitset>

unsigned char sched_sel[] = {0b11100001, 0b00011011};

unsigned char crossbar_in_en[] = {0b1101, 0b1110};

unsigned long crossbar_in[] = {0b11100100, 0b01100100};

unsigned char crossbar_out_en[] = {0b1110, 0b0111};

unsigned long crossbar_out[] = {0b11100001, 0b00011001};


int main(int argc, const char ** argv, const char ** env) {
  int exitcode = 0;
  
  Verilated::commandArgs(argc, argv);

  Vcrossbar * dut = new Vcrossbar;  // Instantiate the collatz module

  for (int i = 0 ; i < 2; i++) {
    dut->sched_sel = sched_sel[i];
    dut->crossbar_in_en = crossbar_in_en[i];
    dut->crossbar_in = crossbar_in[i];
    dut->eval();
    // std::bitset<4> x(dut->voq_empty);
    // std::cout << "voq_empty: " << x << '\n';
    // std::bitset<4> y(dut->voq_picked);
    // std::cout << "voq_picked: " << y << '\n';

    // std::cout << "start_voq_num: " << (int) dut->start_voq_num << '\n';
    
    if (dut->crossbar_out_en == crossbar_out_en[i] && dut->crossbar_out == crossbar_out[i])
        std::cout << " OK" << '\n';
    else {
        std::cout << " INCORRECT expected no_available_voq and voq_to_pick " << std::endl;
        exitcode = 1;
    }
    // std::cout << "no_available_voq: " << (int) dut->no_available_voq << '\n';
    // std::cout << "voq_to_pick: " << (int) dut->voq_to_pick << '\n';
    // std::cout << std::endl;
  }
  
  dut->final(); // Stop the simulation
  delete dut;

  return exitcode;
}
