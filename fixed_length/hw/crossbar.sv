module crossbar #(
    parameter DATA_WIDTH = 32, // For testing
    parameter EGRESS_CNT = 4
) (
    input clk,
    input logic [$clog2(EGRESS_CNT)*EGRESS_CNT-1:0] sched_sel,
    input logic [EGRESS_CNT-1:0] crossbar_in_en,
    input logic [DATA_WIDTH*EGRESS_CNT-1:0] crossbar_in,

    output logic [EGRESS_CNT-1:0] crossbar_out_en,
    output logic [DATA_WIDTH*EGRESS_CNT-1:0] crossbar_out
);

  always_ff @(posedge clk) begin

    crossbar_out_en[sched_sel[0 * $clog2(EGRESS_CNT) +: $clog2(EGRESS_CNT)]] <= crossbar_in_en[0];
    crossbar_out[(sched_sel[0 * $clog2(EGRESS_CNT) +: $clog2(EGRESS_CNT)]) * DATA_WIDTH +: DATA_WIDTH] <= crossbar_in[0 * DATA_WIDTH +: DATA_WIDTH];
    crossbar_out_en[sched_sel[1 * $clog2(EGRESS_CNT) +: $clog2(EGRESS_CNT)]] <= crossbar_in_en[1];
    crossbar_out[(sched_sel[1 * $clog2(EGRESS_CNT) +: $clog2(EGRESS_CNT)]) * DATA_WIDTH +: DATA_WIDTH] <= crossbar_in[1 * DATA_WIDTH +: DATA_WIDTH];
    crossbar_out_en[sched_sel[2 * $clog2(EGRESS_CNT) +: $clog2(EGRESS_CNT)]] <= crossbar_in_en[2];
    crossbar_out[(sched_sel[2 * $clog2(EGRESS_CNT) +: $clog2(EGRESS_CNT)]) * DATA_WIDTH +: DATA_WIDTH] <= crossbar_in[2 * DATA_WIDTH +: DATA_WIDTH];
    crossbar_out_en[sched_sel[3 * $clog2(EGRESS_CNT) +: $clog2(EGRESS_CNT)]] <= crossbar_in_en[3];
    crossbar_out[(sched_sel[3 * $clog2(EGRESS_CNT) +: $clog2(EGRESS_CNT)]) * DATA_WIDTH +: DATA_WIDTH] <= crossbar_in[3 * DATA_WIDTH +: DATA_WIDTH];

end

endmodule