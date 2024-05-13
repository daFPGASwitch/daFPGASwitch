/* verilator lint_off UNUSED */
module ingress #(
    parameter PACKET_CNT = 1024,
    BLOCK_SIZE = 32,
    META_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  reset,

    input  logic [META_WIDTH-1:0] ingress_in,
    input  logic                  ingress_in_en,
    input  logic                  experimenting,
    input  logic                  sched_en,
    input  logic [1:0]            sched_sel,
    input  logic [10:0]          time_stamp,

	// To crossbar
    // output logic                  ingress_out_en,
    output logic [31:0]           ingress_out,

  // To sched
    output logic [3:0]            is_empty
);
  logic [1:0] port_num;
  logic [3:0] is_full;
  logic [31:0] meta_out;
  assign port_num = ingress_in[29:28];
  assign ingress_out = {meta_out[31:11], time_stamp};

  // always @(posedge clk) begin
  //   if (sched_en)
  //     ingress_out_en <= 1;
  //   else if (ingress_out_en)
  //     ingress_out_en <= 0;
  // end

	vmu #(.PACKET_CNT(1024), .EGRESS_CNT(4)) voq_mu
	(
		// Input
		.clk(clk), .reset(reset),
		.voq_enqueue_en(ingress_in_en && !is_full[port_num]), .voq_enqueue_sel(port_num),
		.voq_dequeue_en(sched_en && !is_empty[sched_sel]), .voq_dequeue_sel(sched_sel),
		.meta_in({ingress_in[31:22],time_stamp,ingress_in[10:0]}),
    .time_stamp(time_stamp),

		// Output
		.meta_out(meta_out),
		.is_empty(is_empty), .is_full(is_full)
	);

endmodule
