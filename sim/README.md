# Specifications
Default to 4 ingress ports, and 4 egress ports. This specification is only for simulation and does not apply to the hardware design.

# Design

Assumption: The software's packet comes in at a lower rate than the hardware clk cycle.

### Register
Previously, we were thinking about 2 32-bit registers for each ingress port, defining a packet segment.
But now for simplicity, we are maintaining just 1 32-bit register for each ingress port, defining a packet segment. We also have 1 32-bit register for each egress port.
We also need a register to send new_packet_enable and packet_enable. So we will need 2 * 4 + 1 = 9 registers between the hardware and the software.

### Packet Gen: (In software)
Send packets to Ingress ports at a rate that we control.

## Ingress

Ingress ports consist of 3 units: Packet Management Unit, MAC to Port Number Translation Unit (TODO), and Virtual Output Queue Unit.

### Inputs

* packet, new_packet_enable, packet_enable from packet_gen
* dequeue_idx, dequeue_en from scheduler

### Outputs

* read_enable to control_crossbar
* read_data to data_crossbar
* sched_info to the scheduler (4 bits of is_empty signal, 3 bits of busy_port (0, 1, 2, 3 means the corresponding port number, 4 means no port is busy right now))

## Packet Management Unit

Internally, PMU has a control logic (MMU) and 2 memories, Data Memory, and Control Memory.

### PMU inputs
* read_addr[10], read_en[1] just for testing purposes
* free_addr[10], free_en[1] from IngressQueue
* write_data[31:0], write_en[1] from Software

### PMU outputs
* read_data to the data cross bar
* read_en to the control cross bar
* voq_metadata and voq_metadata_en to IngressQueue (Another design is only output the address of the packet in memory, and let the ingress port construct the voq_metadata and send to the VOQ)
* busy_port_num/busy to the scheduler
* busy to VOQ

### Control logic: (MMU)

Ingress memory management unit

Has 2 separate memory: data_mem and control_mem

There are 1024 * 8 data mem blocks. Each has 32 bits of info
There are 1024 control blocks. Each is structured as follows

    |    1    |   10   |    10   |  3  |
    |allocated|data_mem|next_ctrl|empty|

0 is used as Null/none. the 0th index is not used for that reason


#### Inputs

* free_en from input (VOQ)
* free_addr from input (VOQ)
* write_data from input (software)
* write_en from input (software)
* ctrl_data_en from ControlMemory
* ctrl_data from ControlMemory

#### Outputs

* read_en to DataMemory
* read_addr to DataMemory
* write_en to DataMemory
* write_data to DataMemory
* write_addr to DataMemory
* read_ctrl_en to ControlMemory (enqueue case)
* read_ctrl_addr to ControlMemory (enqueue case)
* write_ctrl_en to ControlMemory (dequeue case)
* write_ctrl_data to ControlMemory (dequeue case)
* write_ctrl_addr to ControlMemory (dequeue aase)
* voq_metadata to interface (VOQ)
* voq_metadata_en to interface (VOQ)

### DataMemory

#### Inputs

* read_en from MMU
* read_addr from MMU
* write_en from MMU
* write_data from MMU
* write_addr from MMU

#### Outputs

* read_en to the control crossbar (interface)
* read_data to data crossbar (interface)

### ControlMemory

#### Inputs

* read_ctrl_en from MMU
* read_ctrl_addr from MMU
* write_ctrl_en from MMU
* write_ctrl_data from MMU
* write_ctrl_addr from MMU

#### Outputs

* ctrl_data to the MMU (this is the next free block or the ctrl block metadata)
* ctrl_data_en to the MMU (this is the next free block or the ctrl block metadata)

## Virtual Output Queue (actually a memory with some logic)

#### Inputs
* voq_metadata and voq_metadata_en from MMU (enqueue case, when a new packet comes in.)
* sched_sel from the scheduler
* busy_sending from the PMU (if we're busy sending, then don't dequeue the one that's currently selected. If we're not, then dequeue one packet from the VOQ that the scheduler selects.)

#### Outputs
* free_addr, free_en to MMU (dequeue case)
* is_empty * 4, busy_port_num, sched_info_en to the scheduler (upon every scheduling decision)



## Scheduler

The scheduler makes a scheduling decision according to the information that's sent from 4 ingress ports.

If there is no enabling, just send the sched_sel anywhere.

If there is enabling:
#### Outputs

* (dequeue_idx, dequeue_en) * 4 to each ingress_port's VOQ (IngressQueues), or just the sched_sel and a sched_ack
* sched_sel to both control crossbar and data crossbar
#### Inputs
* (is_empty * 4, busy_port_num, sched_info_en) * 4 from each ingress_port's VOQ (IngressQueues)

## Crossbar
We have both a data crossbar and a control crossbar. Data crossbar has a width of 32 Bytes, not 32 bits. Ctrl crossbar is just the read_enable signal. They are all combinational logic.

#### Output

* read_data/read_en that's selected to egress_port

#### Inputs

* read_data (for Data crossbar)/read_en (for Control Crossbar) from PMU (pulled from the memory)
* sched_sel from scheduler

<!-- For both the data/control crossbar

ControlCrossBar sends: (output goes to where)
* read_en that's selected to egress_port
ControlCrossBar receives: (input comes from where)
* read_en from MMU
* sched_sel from scheduler  -->

## Egress Port:
It sends back the packet in chunks to the software. It sends 1/2 registers to the software.
It has a control logic and an egress_buffer.

### Control logic:
#### input
* read_en from ctrl crossbar
* read_data from the data crossbar
#### output
* head_addr to egress_buffer's read_addr
* head_addr_en to egress_buffer read_en
* tail_addr to egress_buffer's write_addr
* tail_addr_en to egress_buffer's write_en

### Egress Buffer
#### Input
* head_addr from control logic
* head_addr_en from control logic
* tail_addr from control logic
* tail_addr_en from control logic
#### Output
* read_data to software
* read_en to software


# Notices:

## Heartbeat:
* Every 8 cycles, there's a scheduling decision. The scheduling decision changes the pattern of the active sel of the crossbar; each cycle we put 32 bits on the crossbar, so there will be 32-bit * 8 = 32 bytes of data per egress that gets sent to the output every cycle.


## All the state machines that we have:
The packet Management Unit has a lot of state machines because our system only operates at a rate of 32-bit at a time.
* When reading in the packets, we need to keep reading the packet until we have a complete dest MAC address, which needs to be managed by a state machine (or a counter).
* When we're sending a packet, we send the packet by chunk, so the progress of sending a packet to the crossbar should also be a state machine.
