# Specifications
Default to 4 ingress ports, and 4 egress ports.

# Software

Assumption: The software's packet comes in at a lower rate than the hardware clk cycle.

### Register
Previously, we were thinking about 2 32-bit registers for each ingress port, defining a packet segment.
But now for simplicity, we are maintaining just 1 32-bit register for each ingress port, defining a packet segment. We also have 1 32-bit register for each egress port.
We also need a register to send new_packet_enable and packet_enable. So we will need 2 * 4 + 1 = 9 registers between the hardware and the software.

### Packet Gen: (In software)
Send packets to Ingress ports at a rate that we control.

# Ingress

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

The scheduler makes a scheduling decision according to the information that's send from 4 ingress ports.

If there is not enabling, just send the sched_sel anywhere.

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

<!-- out:
* 
Software:
register:
* 2 registers to recv packets -->

<!-- tick of dataMemory:
read_data = if (self.read_en) then self.read_data else None
data_crossbar(read_data)
ctrl_crossbar(read_en)

Basic simulation principles
Every input wire is a local variable
memory blocks are local variable
every function that's in "send" calls the sendee's class-specific function in tick
every class should define all functions listed in recv
class.tick takes in class object that it send to. -->

## How are we gonna make the packet decoding robust? Given that we might have data loss (need checksum bit?)
Which packet makes it (packet id number, checksum on, store the checksum)
We probably don't want to store the entire packet, but just store the metadata, because half a MB will be pretty quick to fill up.

## Does the egress need to communicate with ingress (i.e. do we need control crossbar?)
Just let the crossbar output an enable bit.

## Egress: It can be not OTF, but let 
Dumb! Make them dumb and big, have them 
test the latency, record some metrics.
Add cycle cnt/time stamp, so that we know how long it takes to arraive (1 time stamp, 1 into the ingress time, 2 into the egress time) (attach it to the packet)

## Heartbeat:
* Every 8 cycles, there's a scheduling decision. The scheduling decision changes the pattern of the active sel of the crossbar; each cycle we put 32 bits on the crossbar, so there will be 32-bit * 8 = 32 bytes of data per egress that gets sent to the output every cycle.

## Packet generation problem
* Should we generate everything all at once, and let the hardware send it, or hw and sw interface communicate on the fly?

## Memory problem
* Can we assume the data's gonna be sent out after one cycle? I think yes

## All the state machines that we have:
The packet Management Unit has a lot of state machines because our system only operates at a rate of 32-bit at a time.
* When reading in the packets, we need to keep reading the packet until we have a complete dest MAC address, which needs to be managed by a state machine (or a counter).
* When we're sending a packet, we send the packet by chunk, so the progress of sending a packet to the crossbar should also be a state machine. 


<<<<<<< HEAD
## Rethink dequeue and "busy_sending"
The busy_sending signal should be set by the VOQ, since the VOQ initiates a dequeue->send packet.

The busy_sending signal should be unset by the PMU, since the PMU is the actual unit that sends out the packet.

Maybe we should combine the VOQ and the MMU.

## Scheduler should not have an enable I think
Because we need information on what should be active at any given cycle? If we were to do scheduler_enable, who should send it?

## Timing seems to be a little off.
What is a general approach to make sure the timing does not get messed up?


## Should we assume that the software is much slower than the hardware?
* If it is, then things does not get queued up, so what's the meaning of the switch?
* It might be better just to generate the packets in hardware, and the software makes the switch programmable (like control the MAC to Port table, control how many ports it supports...)
* If it's not, then we need finer granularity of state machines. Like I think we need to handle the case of when we're 

## Should we keep the packet generation in hardware, and let software control the programmability of the switch?
* For example, let the software control the mac-to-port table.
* This is because I think packet gen in software does not necessarily make sense.
  * If software speed >> hardware, then too many packets are going to be dropped
  * If software speed << hardware, then the crossbar does not even make sense anymore.
  * Find the right rate is hard, and I don't know which is more realistic.

## What's a general way to do hardware? en or en+ack?
Also, can we trust that memory have a "read_data_ready" output?

## Rethink dequeue
The busy_voq signal should come from the PMU, since the PMU is the actual unit that sends out the packet. (Set by PMU, unset by VOQ, but all output logic)

## Scheduler is all combinatory?
If it doesn't, then when do we do schedule_enable? (Yes, there's a heartbeat that drives the program)

## Timing seems to be a little off. What is a general approach to make sure the timing does not get messed up?
Just draw the timing diagram


The scheduler takes one cycle to generate a scheduling decision, do that takes a cycle (probably)

Most critical thing: The memory takes a cycle.

Does enable come in at the same cycle?
* If it's generated from the same source (like the packet gen), then it might need 2 cycles, if it's the crossbar then data comes from crossbar but the enable comes from scheduler, then you can do 1 cycle.

You're getting a new port

!!! 8 counters, because of what?

3 cases:
1. no new block
2. start new block
3. continue block
4. start new packet
5. end packet
6. packet should be dropped


3 block of the timing diagram
1. new packet, 1 middle block, 1 end of packet.

Using some time diagram softwares (Be discreet)

