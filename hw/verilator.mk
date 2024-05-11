.PHONY: lint

PACKET_VAL_FILES = packet_val.sv simple_dual_port_mem.sv port_to_mac.sv mac_to_port.sv
TOP_FILES = da_fpga_switch.sv packet_gen.sv hw_sw_interface.sv simple_dual_port_mem.sv port_to_mac.sv packet_val.sv mac_to_port.sv
CMU_FILES = cmu.sv true_dual_port_mem.sv
PACKET_GEN_FILES = packet_gen.sv simple_dual_port_mem.sv port_to_mac.sv
SVFILES = cmu.sv sched.sv pick_voq.sv vmu.sv simple_dual_port_mem.sv true_dual_port_mem.sv crossbar.sv
SCHED_FILES = sched.sv pick_voq.sv

# Run Verilator simulations

default:
	@echo "No target given. Try:"
	@echo ""
	@echo "make pick_voq"
	@echo "make crossbar"
	@echo "make sched.vcd"
	@echo "make vmu.vcd"
	@echo "make cmu.vcd"
	@echo "make lint"
	@echo "make packet_gen.vcd"

packet_val.vcd : obj_dir/Vpacket_val
		obj_dir/Vpacket_val

da_fpga_switch.vcd : obj_dir/Vda_fpga_switch
		obj_dir/Vda_fpga_switch

packet_gen.vcd : obj_dir/Vpacket_gen
		obj_dir/Vpacket_gen

pick_voq : obj_dir/Vpick_voq
	(obj_dir/Vpick_voq && echo "SUCCESS") || echo "FAILED"

crossbar: obj_dir/Vcrossbar
	(obj_dir/Vcrossbar && echo "SUCCESS") || echo "FAILED"

cmu.vcd : obj_dir/Vcmu
	obj_dir/Vcmu

sched.vcd : obj_dir/Vsched
	obj_dir/Vsched

vmu.vcd : obj_dir/Vvmu
	obj_dir/Vvmu

obj_dir/Vda_fpga_switch : $(TOP_FILES) verilator/da_fpga_switch.cpp
	verilator -trace -Wall -cc $(TOP_FILES) -exe verilator/da_fpga_switch.cpp \
		-top-module da_fpga_switch
	cd obj_dir && make -j -f Vda_fpga_switch.mk


obj_dir/Vpacket_val : $(PACKET_VAL_FILES) verilator/packet_val.cpp
	verilator -trace -Wall -cc $(PACKET_VAL_FILES) -exe verilator/packet_val.cpp \
		-top-module packet_val
	cd obj_dir && make -j -f Vpacket_val.mk

obj_dir/Vpacket_gen : $(PACKET_GEN_FILES) verilator/packet_gen.cpp
	verilator -trace -Wall -cc $(PACKET_GEN_FILES) -exe verilator/packet_gen.cpp \
		-top-module packet_gen
	cd obj_dir && make -j -f Vpacket_gen.mk

obj_dir/Vcmu : $(CMU_FILES) verilator/cmu.cpp
	verilator -trace -Wall -cc $(CMU_FILES) -exe verilator/cmu.cpp \
		-top-module cmu
	cd obj_dir && make -j -f Vcmu.mk

obj_dir/Vpick_voq : pick_voq.sv verilator/pick_voq.cpp
	verilator -Wall -cc pick_voq.sv -exe verilator/pick_voq.cpp \
		-top-module pick_voq
	cd obj_dir && make -j -f Vpick_voq.mk

obj_dir/Vcrossbar : crossbar.sv verilator/crossbar.cpp
	verilator -Wall -cc crossbar.sv -exe verilator/crossbar.cpp \
		-top-module crossbar
	cd obj_dir && make -j -f Vcrossbar.mk

obj_dir/Vsched : $(SCHED_FILES) verilator/sched.cpp
	verilator -trace -Wall -cc sched.sv pick_voq.sv -exe verilator/sched.cpp \
		-top-module sched
	cd obj_dir && make -j -f Vsched.mk

obj_dir/Vvmu : vmu.sv simple_dual_port_mem.sv verilator/vmu.cpp
	verilator -trace -Wall -cc vmu.sv simple_dual_port_mem.sv -exe verilator/vmu.cpp \
		-top-module vmu
	cd obj_dir && make -j -f Vvmu.mk

lint :
	for file in $(SVFILES); do \
	verilator --lint-only -Wall $$file; done

clean :
	rm -rf obj_dir db incremental_db output_files \
	lab1.qpf lab1.qsf lab1.sdc lab1.qws c5_pin_model_dump.txt
