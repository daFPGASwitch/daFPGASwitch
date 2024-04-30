.PHONY: sched lint

SVFILES = sched.sv

# Run Verilator simulations

sched.vcd : obj_dir/Vsched
	obj_dir/Vsched

obj_dir/Vsched : sched.sv verilator/sched.cpp
	verilator -trace -Wall -cc sched.sv -exe verilator/sched.cpp \
		-top-module sched
	cd obj_dir && make -j -f Vsched.mk

lint :
	for file in $(SVFILES); do \
	verilator --lint-only -Wall $$file; done

clean :
	rm -rf obj_dir db incremental_db output_files \
	lab1.qpf lab1.qsf lab1.sdc lab1.qws c5_pin_model_dump.txt