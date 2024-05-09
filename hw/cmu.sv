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

`define D_WIDTH 11
module cmu (
    input logic clk,
    input logic [5:0] remaining_packet_length, // in blocks
    input logic wen, free_en,
    input logic [9:0] raddr, 
    output logic [9:0] packet_addr // the address in cmem for the first chunk of the packet
);
	
	
    // Registers
    /* verilator lint_off UNOPTFLAT */ 
    reg[9:0]	curr_write, next_write;
	reg[5:0]	empty_blocks;
	/* verilator lint_on UNOPTFLAT */
	reg[`D_WIDTH-1:0]	ctrl_in  = `D_WIDTH'b0;
	/* verilator lint_off UNUSED */
	logic[`D_WIDTH-1:0]	ctrl_out;
	/* verilator lint_on UNUSED */
	logic		ctrl_wen_a, ctrl_wen_b;
	logic		new_block = 1;

	logic[9:0]	addr_a, addr_b;
	
	always_comb begin
		if (wen) begin 
			/* Format ctrl_in */
			if (remaining_packet_length < empty_blocks) begin
				new_block = 0;
			end

			if (new_block) begin
				/* verilator lint_off ALWCOMBORDER */
				curr_write = next_write;
				next_write = ctrl_out[10:1];
				/* verilator lint_on ALWCOMBORDER */
				ctrl_in[0] = 1'b1;
			
				if (remaining_packet_length > 1) begin
					ctrl_in[10:1] = next_write;
				end else begin
					ctrl_in[10:1] = 10'b0;
				end
				
				/* verilator lint_off ALWCOMBORDER */
				empty_blocks = empty_blocks - 1;
				/* verilator lint_on ALWCOMBORDER */
			end
		end

		if (free_en) begin
			ctrl_in[0] = 1'b0;
			ctrl_in[10:1] = next_write;
			next_write = raddr;
		end
    end


    always @(posedge clk) begin
    	if (wen) begin
			addr_a 		<= 	curr_write;
			ctrl_wen_a 	<=	wen;
		end else begin
			addr_a		<= next_write;
		end
	
		if (free_en) begin
			ctrl_wen_b 	<=	free_en;
		end
	
		addr_b	 		<= 	raddr;
		packet_addr 	<= 	ctrl_out[10:1];
    end

    true_dual_port_mem #(.MEM_SIZE(1024), .DATA_WIDTH(`D_WIDTH)) cmem
	(	
		.clk(clk), 
		.aa(addr_a), 		.ab(addr_b),
		.da(ctrl_in),		.db(ctrl_in),
		.wa(ctrl_wen_a),	.wb(ctrl_wen_b),
		.qa(ctrl_out),		.qb(ctrl_out)
	);
endmodule


