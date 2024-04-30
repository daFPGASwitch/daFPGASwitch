module sched (
    input logic clk,
    // input logic sched_en,
    // input logic [3:0] is_busy,
    // input logic [1:0] busy_voq_num_0,
    // input logic [1:0] busy_voq_num_1,
    // input logic [1:0] busy_voq_num_2,
    // input logic [1:0] busy_voq_num_3,
    input logic [3:0] voq_empty_0,
    input logic [3:0] voq_empty_1,
    input logic [3:0] voq_empty_2,
    input logic [3:0] voq_empty_3,
    output logic sched_sel_en,
    output logic[3:0] sched_sel_0,
    output logic[3:0] sched_sel_1,
    output logic[3:0] sched_sel_2,
    output logic[3:0] sched_sel_3
);
  always_ff @(posedge clk) begin
    sched_sel_en <= 1;
    sched_sel_0 <= voq_empty_0;
    sched_sel_1 <= voq_empty_1;
    sched_sel_2 <= voq_empty_2;
    sched_sel_3 <= voq_empty_3;
  end
endmodule