.PHONY: sched lint

SVFILES = sched.sv, pick_voq.sv

# Run Verilator simulations

default:
	@echo "No target given. Try:"
	@echo ""
	@echo "make pick_voq"
	@echo "make sched.vcd"
	@echo "make lint"
	@echo "make output_files/lab1.sof"
	@echo "make program"

pick_voq : obj_dir/Vpick_voq
	(obj_dir/Vpick_voq && echo "SUCCESS") || echo "FAILED"

sched.vcd : obj_dir/Vsched
	obj_dir/Vsched

obj_dir/Vpick_voq : pick_voq.sv verilator/pick_voq.cpp
	verilator -Wall -cc pick_voq.sv -exe verilator/pick_voq.cpp \
		-top-module pick_voq
	cd obj_dir && make -j -f Vpick_voq.mk

obj_dir/Vsched : sched.sv pick_voq.sv verilator/sched.cpp
	verilator -trace -Wall -cc sched.sv pick_voq.sv -exe verilator/sched.cpp \
		-top-module sched
	cd obj_dir && make -j -f Vsched.mk

lint :
	for file in $(SVFILES); do \
	verilator --lint-only -Wall $$file; done

clean :
	rm -rf obj_dir db incremental_db output_files \
	lab1.qpf lab1.qsf lab1.sdc lab1.qws c5_pin_model_dump.txt