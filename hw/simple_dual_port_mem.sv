module simple_dual_port_mem #(
    parameter MEM_SIZE = 1024,  /* How many addresses of memory in total, 1024 by default */
    parameter DATA_WIDTH = 32  /* How many bit of data per cycle, 32 by default */
) (
    input logic clk,
    input logic [$clog2(MEM_SIZE) - 1:0] ra, wa, /* Address */
    input logic [DATA_WIDTH - 1:0] d,	 		 /* input data */
    input logic write,	 						 /* Write enable */
    output logic [DATA_WIDTH - 1:0] q			 /* output data */
);
  logic [DATA_WIDTH-1:0] mem[MEM_SIZE - 1:0];

  always_ff @(posedge clk) begin
    if (write) begin
      mem[wa] <= d;
	  end
    q <= mem[ra];
  end 
	
endmodule
