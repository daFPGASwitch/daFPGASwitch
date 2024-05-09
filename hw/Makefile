.PHONY: sched lint

SVFILES = cmu.sv
TOPMOD  = cmu

# Run Verilator simulations

default:
	@echo "No target given. Try:"
	@echo ""
	@echo "make pick_voq"
	@echo "make sched.vcd"
	@echo "make lint"
	@echo "make output_files/lab1.sof"
	@echo "make program"

cmu.vcd : obj_dir/Vcmu
	obj_dir/Vcmu

obj_dir/Vcmu : $(svfiles) verilator/cmu.cpp
	verilator -trace -Wall -cc $(SVFILES) -exe verilator/cmu.cpp \
		-top-module cmu
	cd obj_dir && make -j -f Vcmu.mk

lint :
	for file in $(SVFILES); do \
	verilator --lint-only -Wall $$file; done

clean :
	rm -rf obj_dir db incremental_db output_files \
	lab1.qpf lab1.qsf lab1.sdc lab1.qws c5_pin_model_dump.txt
