module sched (
    input logic clk,
    input logic [1:0] policy, // We have doubly RR, or no RR, or sth else, can be controlled by software
    input logic sched_en,
    input logic [3:0] is_busy,
    input logic [7:0] busy_voq_num;
    // input logic [1:0] busy_voq_num_0,
    // input logic [1:0] busy_voq_num_1,
    // input logic [1:0] busy_voq_num_2,
    // input logic [1:0] busy_voq_num_3,
    input logic [15:0] voq_empty,
    // input logic [3:0] voq_empty_0,
    // input logic [3:0] voq_empty_1,
    // input logic [3:0] voq_empty_2,
    // input logic [3:0] voq_empty_3,
    output logic sched_sel_en,
    output logic[7:0] sched_sel,
    // output logic[1:0] sched_sel_0,
    // output logic[1:0] sched_sel_1,
    // output logic[1:0] sched_sel_2,
    // output logic[1:0] sched_sel_3
);
  /*  
      START: get sched_en signal;
      ASSIGN_CONT: Assign for port in the middle of transmitting a packet;
      ASSIGN_NEW: Assign port for new packets: The new egress can start transmitting at any free port;
      DONE: finished, and send sched_sel_en;
  */

  /*
  Some design choices: 
  * Do we want the time to return a scheduling decision to be deterministic or random (btw 1 and 4)
  * Should each busy port to just start transmitting without waiting for the scheduling decision
  * Should the schduler decision the scheduling decision for this cycle or next cycle
  * RR on the ingress or egress side, or both
  * Should we try to do all combinator?
  * Do we use 1 find_first_non_empty or 4 find_first_non_empty? (1 since it's going to take 4 cycles anyway)
  */

  /*
  Some principles:
  * We don't want egress 1 to always recv packet from ingress 0; we don't want ingress 0 to always send to egress 2
  * nested loop fully in combinator logic is too expensive; instead, we do the outer for loop sequentially, and the inner 4 loop in comb logic
  RR policy:
  
    * ingress RR: Start_ingress_idx proceed in each cycle of ASSIGN_NEW (or one pass who-ever gets to select first in this cycle)
    * egress RR: Each start_voq_num is first_non_empty_num of this cycle + 1;
  */

  
  enum logic [3:0] {ASSIGN_CONT, ASSIGN_NEW, DONE} state;
  logic  assigning_new; // If the scheduler is in the process of assigning new packet
  logic [3:0] assigned; // Whether each egress_port_num has been assigned to each ingress_port_num
  logic start_ingress_idx[1:0]; // Which ingress has the highest priority in this cycle
  logic start_voq_num[7:0]: // Which egress has the highest priority in this cycle, for each ingress.

  logic curr_ingress_idx[1:0]; // Current ingress
  logic all_empty; // Is the voqs of the current ingress all empty
  logic first_non_empty_num; // What is the first_non_voq_num for the current ingress

  pick_voq  (
      .voq_empty(voq_empty[(curr_ingress_idx * 4 + 3): (curr_ingress_idx * 4)]),
      .start_voq_num(start_voq_num[(curr_ingress_idx * 2 + 3): (curr_ingress_idx * 2)]),
      .all_empty(all_empty),
      .first_non_empty_num(first_non_empty_num)
    );

  alway_comb begin
    for (i = 0; i < 4; i = i + 1) begin
        if is_busy[i] begin
          sched_sel[2*i : 2*(i+1)] = is_busy[2*i: 2*(i+1)]
        end
    end
  end

  always_ff @(posedge clk) begin

    if (sched_en) begin
      // If we begin to schedule
      // reset sched_sel_en
      sched_sel_en <= 0;
      // all the busy ports are automatically assigned.
      assigned <= is_busy;
      // start to assign ports for non-empty 
      assigning_new <= 1;
      current_ingress_idx <= start_ingress_idx;
      // Nex time it should be next 
      start_ingress_idx <= (start_ingress_idx +  1) % 4;
    end else if (assigned == 4'b1111) begin
      // If all are assigned, we're going start enabling
      sched_sel_en <= 1;
      assigning_new <= 1'b0;
    end else if (assigning_new) begin
      // TODO
    end
    // sched_sel_en <= 1;
    // sched_sel_0 <= voq_empty_0;
    // sched_sel_1 <= voq_empty_1;
    // sched_sel_2 <= voq_empty_2;
    // sched_sel_3 <= voq_empty_3;
  end
endmodule