module sched (
    input logic clk,
    // input logic [1:0] policy, // We have doubly RR, or no RR, or sth else, can be controlled by software
    input logic sched_en,
    input logic [3:0] is_busy,
    input logic [7:0] busy_voq_num,
    input logic [15:0] voq_empty,
    output logic [4:0] sched_sel_en, // passed by to ingress, to know which ingress should dequeue
    output logic [7:0] sched_sel // passed by to ingress, to know which voq to dequeue
);

  /*
  Some design choices: 
  * Do we want the time to return a scheduling decision to be deterministic or random (btw 1 and 4)
  * Should each busy port to just start transmitting without waiting for the scheduling decision
  * Should the schduler decision the scheduling decision for this cycle or next cycle
  * RR on the ingress or egress side, or both
  * Should we try to do all combinator?
  * Do we use 1 voq_to_pick or 4 voq_to_pick? (1 since it's going to take 4 cycles anyway)
  */

  /*
  Some principles:
  * We don't want egress 1 to always recv packet from ingress 0; we don't want ingress 0 to always send to egress 2
  * nested loop fully in combinator logic is too expensive; instead, we do the outer for loop sequentially, and the inner 4 loop in comb logic
  RR policy:
    * ingress RR: Start_ingress_idx proceed in each cycle of ASSIGN_NEW (or one pass who-ever gets to select first in this cycle)
    * egress RR: Each start_voq_num is first_non_empty_num of this cycle + 1;
    * fewer first: Prioritze queue with only one non-empty voq.
  */

  /*
  Notice: Beware of the possiblity of input (voq_empty for example) change during the process. 
  */

  logic assigning_new; // If the scheduler is in the process of assigning new packet
  logic [3:0] ingress_done; // Whether each ingress is done
  logic [3:0] ingress_enable; // the enable signal ready to be passed to sched_sel_en when ingress_done = 4'b1111
  // logic [3:0] egress_done; // Whether each egress is done
  
  // For RR
  logic [1:0] start_ingress_idx; // Which ingress has the highest priority in this cycle
  logic [7:0] start_voq_num; // Which egress has the highest priority in this cycle, for each ingress.

  logic [1:0] curr_ingress_idx; // Current ingress
  logic [2:0] curr_in_2;
  logic [3:0] curr_in_4;
  logic [3:0] voq_picked; // is the voq/egress picked?
  logic no_available_voq; // Is the voqs/egress of the current ingress all empty/occupied by other?
  logic [1:0] voq_to_pick; // What is the voq_to_pick for the current ingress

  logic [2:0] i; // For for loop

  always_comb begin
    // Every busy ingress will continue to send out whatever's currently in the middle of the transit.
    for (i = 0; i < 4; i = i + 1) begin
        if (is_busy[i]) begin
          logic [1:0] busy_port = busy_voq_num[(i + 1) << 1 : i << 1];
          sched_sel[(i + 1) << 1 : i << 1] << (i * 2) = busy_port;
          voq_picked[busy_port] = 1'b1;
          ingress_done[i] = 1'b1;
          ingress_enable[i] = 1'b1;
        end
    end
    curr_in_2 = curr_ingress_idx << 1;
    curr_in_4 = curr_ingress_idx << 2; // * 4 is << 2
  end

  always_ff @(posedge clk) begin

    if (sched_en) begin
      // If we begin to schedule
      // reset sched_sel_en
      sched_sel_en <= 0;
      // all the busy ingress ports are automatically assigned.
      // ingress_done <= is_busy; // redundant
      // start to assign ports for non-empty 
      assigning_new <= 1'b1;
      curr_ingress_idx <= start_ingress_idx; // Start with start_ingress_idx
    end else if (ingress_done == 4'b1111) begin // alternatively, if we manage to go back to start_ingress_idx
      // If all are assigned, we're going start enabling
      sched_sel_en <= ingress_enable;
      // Nex time it should start with another index.
      start_ingress_idx <= (start_ingress_idx == 3) ? 0 : start_ingress_idx + 1;
      assigning_new <= 1'b0;
    end else if (assigning_new) begin
      curr_ingress_idx <= (curr_ingress_idx == 3) ? 0 : curr_ingress_idx + 1;
      ingress_done[curr_ingress_idx] <= 1'b1;
      if (!is_busy[curr_ingress_idx]) begin
        ingress_enable[curr_ingress_idx] <= !no_available_voq;
        sched_sel[curr_in_2 + 2 : curr_in_2] <= voq_to_pick;
        voq_picked[voq_to_pick] <= 1'b1;
        start_voq_num[curr_in_2 + 2 : curr_in_2] <= 
          (start_voq_num[curr_in_2 + 2 : curr_in_2] == 3) ? 0 : start_voq_num[curr_in_2 + 2 : curr_in_2] + 1; // Alternatively, we can choose not to move forward when no_available_voq.
      end
    end
  end

  // pick_voq will pick return the current ingress's first non empty voq to dequeue from.
  pick_voq pv (
    .start_voq_num(start_voq_num[(curr_in_2 + 2): curr_in_2]),
    .voq_empty(voq_empty[(curr_in_4 + 4): curr_in_4]),
    .voq_picked(voq_picked),
    .no_available_voq(no_available_voq),
    .voq_to_pick(voq_to_pick)
  );
endmodule