/* 
The packet management unit: 

*/

/*
ctrl memory is divided into 16-bit chunks
and each of them represents a packet segment (32 bytes) inside the data memory

Inside each chunk:
* 1-bit of is_allocated
* 10-bit of next_addr (of ctrl memory, basically a linked list) / 10'b0 which is the end of packet chain.

A packet comes in that needs 2 block
Address 0: Null
Address 1: 1, 0000000002
Address 2: 1, 0000000000
*/


module cmu (
    input logic clk,
    input logic [5:0] remaining_packet_length, // in blocks
    input logic wen,
    input logic [9:0] raddr, 
    output logic [9:0] packet_addr, // the address in cmem for the first chunk of the packet
);

    always_comb begin

    end


    always @(posedge clk) begin
    
    end

    true_dual_port_mem #(.MEM_SIZE(1024), .DATA_WIDTH(16)) cmem
	(	
		.clk(clk), 
		.aa(), 	.ab(),
		.da(),	.db(),
		.wa(),	.wb(),
		.qa(),	.qb()
	);
endmodule


