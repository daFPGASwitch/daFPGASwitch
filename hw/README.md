# Hardware

## Verilator

### Scheduler

To run the simulation for the scheduler:
```bash
make sched.vcd # dump vcd file
gtkwave --save=sched.gtkw sched.vcd # draw the timing diagram with gtkwave
```
