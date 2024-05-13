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

	// To crossbar
    // output logic                  ingress_out_en,
    output logic [31:0]           ingress_out,

  // To sched
    output logic [3:0]            is_empty
);
  logic [1:0] port_num;
  logic [3:0] is_full;
  assign port_num = ingress_in[29:28];

  // always @(posedge clk) begin
  //   if (sched_en)
  //     ingress_out_en <= 1;
  //   else if (ingress_out_en)
  //     ingress_out_en <= 0;
  // end

	vmu #(.PACKET_CNT(1024), .EGRESS_CNT(4)) voq_mu
	(
		// Input
		.clk(clk), 
		.voq_enqueue_en(ingress_in_en && !is_full[port_num]), .voq_enqueue_sel(port_num),
		.voq_dequeue_en(sched_en), .voq_dequeue_sel(sched_sel),
		.meta_in(ingress_in),

		// Output
		.meta_out(ingress_out),
		.is_empty(is_empty), .is_full(is_full)
	);

endmodule
