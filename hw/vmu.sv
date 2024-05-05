/* 
The virtual output queue management unit: 

*/

/*
voq memory is divided into 16-bit chunks
and each of them represents a whole packet

Inside each chunk:
* an 10-bit address, which is the ctrl address of the first segment of the packet

The same packet in cmu (that needs 2 block) would be:
Address 0: 10'b1
*/


module vmu (
    input logic clk;
    input logic voq_enqueue_en,
    input logic [1:0] voq_enqueue_sel,
    input logic voq_dequeue_en,
    input logic [1:0] voq_dequeue_sel,
    
    output logic meta_out, // The content (first addr of the packet) saved for the dequeue packet
    output logic [3:0] is_empty, // For scheduler
    
);

    always_comb begin

    end


    always @(posedge clk) begin

    end

	true_dual_port_mem #(.MEM_SIZE(1024*8), .DATA_WIDTH(16)) vmem
	(	
		.clk(clk), 
		.ra(), .wa(),
		.d(),	.q(),
		.write()
	);

endmodule


