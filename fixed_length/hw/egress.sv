/* verilator lint_off UNUSED */
module egress #(
    parameter PACKET_CNT = 1024,
    BLOCK_SIZE = 32,
    META_WIDTH = 32
) (
    input logic clk,
    input logic reset,

    // From crossbar
    input logic [META_WIDTH-1:0] egress_in,
    input logic                  egress_in_en,

    // From interface
    input logic egress_in_ack,

    // To interface
    output logic [31:0] egress_out
);

  logic [$clog2(PACKET_CNT)-1:0] start_idx;  // The first element
  logic [$clog2(PACKET_CNT)-1:0] end_idx;  // One pass the last element

    always @(posedge clk) begin
        if (egress_in_en) begin
            end_idx <= (end_idx != 1023) ? end_idx + 1 : 0;
        end
        
        if (egress_in_ack) begin
            start_idx <=  (start_idx != 0) ? start_idx - 1 :1023;
        end
    end

  simple_dual_port_mem #(
      .MEM_SIZE  (PACKET_CNT),
      .DATA_WIDTH(32)
  ) meta_mem (
      .clk(clk),
      .ra(start_idx),
      .wa(end_idx),
      .d(egress_in),
      .q(egress_out),
      .write(egress_in_en)
  );

endmodule
