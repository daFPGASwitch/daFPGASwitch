module true_dual_port_mem #(
    parameter MEM_SIZE = 1024  /* How many bits of memory in total, 512 by default */
    parameter DATA_WIDTH = 16  /* How many bit of data per cycle, 20 by default */
) (
    input logic clk,
    input logic [$clog2(MEM_SIZE) - 1:0] aa, ab, /* Address */
    input logic [DATA_WIDTH - 1:0] da, db, 		 /* input data */
    input logic wa, wb, 						 /* Write enable */
    output logic [DATA_WIDTH - 1:0] qa, qb 		 /* output data */
);
  logic [DATA_WIDTH-1:0] mem[MEM_SIZE - 1:0];

  // First port
  always_ff @(posedge clk) begin
    if (wa) begin
      mem[aa] <= da;
      qa <= da;
    end else qa <= mem[aa];
  end

  // Second port
  always_ff @(posedge clk) begin
    if (wb) begin
      mem[ab] <= db;
      qb <= db;
    end else qb <= mem[ab];
  end
endmodule
