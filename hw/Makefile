.PHONY: sched lint

CMU_FILES = cmu.sv
TOPMOD  = cmu
SVFILES = cmu.sv sched.sv pick_voq.sv vmu.sv simple_dual_port_mem.sv true_dual_port_mem.sv

# Run Verilator simulations

default:
	@echo "No target given. Try:"
	@echo ""
	@echo "make pick_voq"
	@echo "make sched.vcd"
	@echo "make vmu.vcd"
	@echo "make lint"

cmu.vcd : obj_dir/Vcmu
	obj_dir/Vcmu

obj_dir/Vcmu : $(CMU_FILES) verilator/cmu.cpp
	verilator -trace -Wall -cc $(CMU_FILES) -exe verilator/cmu.cpp \
		-top-module cmu
	cd obj_dir && make -j -f Vcmu.mk

sched.vcd : obj_dir/Vsched
	obj_dir/Vsched

vmu.vcd : obj_dir/Vvmu
	obj_dir/Vvmu

obj_dir/Vpick_voq : pick_voq.sv verilator/pick_voq.cpp
	verilator -Wall -cc pick_voq.sv -exe verilator/pick_voq.cpp \
		-top-module pick_voq
	cd obj_dir && make -j -f Vpick_voq.mk

obj_dir/Vsched : sched.sv pick_voq.sv verilator/sched.cpp
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
