module crossbar #(
    parameter DATA_WIDTH = 2, // For testing
    parameter EGRESS_CNT = 4
) (
    input logic [$clog2(EGRESS_CNT)*EGRESS_CNT-1:0] sched_sel,
    input logic [EGRESS_CNT-1:0] crossbar_in_en,
    input logic [DATA_WIDTH*EGRESS_CNT-1:0] crossbar_in,

    output logic [EGRESS_CNT-1:0] crossbar_out_en,
    output logic [DATA_WIDTH*EGRESS_CNT-1:0] crossbar_out
);

logic [$clog2(EGRESS_CNT):0] i;
logic [$clog2(EGRESS_CNT)-1:0] _i;

always_comb begin
    for (i = 0; i < EGRESS_CNT; i = i + 1) begin
        _i = i[$clog2(EGRESS_CNT)-1:0];
        crossbar_out_en[sched_sel[i * $clog2(EGRESS_CNT) +: $clog2(EGRESS_CNT)]] = crossbar_in_en[_i];
        crossbar_out[(sched_sel[i * $clog2(EGRESS_CNT) +: $clog2(EGRESS_CNT)]) * DATA_WIDTH +: DATA_WIDTH] = crossbar_in[_i * DATA_WIDTH +: DATA_WIDTH];
    end
end

endmodule