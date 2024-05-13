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
    output logic [9:0] packet_addr = 10'b0, // the address in cmem for the first chunk of the packet
	output logic [9:0] next_read = 10'b0
);
	
	
    // Registers
    /* verilator lint_off UNOPTFLAT */ 
    logic[9:0]	curr_write;
	logic[9:0]	next_write = 10'b1;
	logic[5:0]	empty_blocks = 6'b111111;
	/* verilator lint_on UNOPTFLAT */
	logic[`D_WIDTH-1:0]	ctrl_in_a  = `D_WIDTH'b0;
	logic[`D_WIDTH-1:0]	ctrl_in_b  = `D_WIDTH'b0;
	/* verilator lint_off UNUSED */
	logic[`D_WIDTH-1:0]	ctrl_out_a, ctrl_out_b;
	/* verilator lint_on UNUSED */
	logic		ctrl_wen_a, ctrl_wen_b;
	logic		new_block 	= 0;
	logic		read_next 	= 0;
	logic		update_next = 1;
//	logic		return_chain= 1;

	logic[9:0] next_ctrl = 10'b0;

	logic[9:0]	addr_a, addr_b;
	
    always @(posedge clk) begin
		if (wen) begin
			if (remaining_packet_length < empty_blocks) begin
				new_block <= 1'b1;
				empty_blocks <= empty_blocks - 1;
			end else begin
				new_block <= 1'b0;
			end
			
			$display("new_block %b\n", new_block);
 
		end

		if (new_block) begin
			/* verilator lint_on ALWCOMBORDER */
			/* Formatting ctrl data  */
			ctrl_in_a[10] <= 1'b1;
			
			if (remaining_packet_length > 1) begin
				ctrl_in_a[9:0] <= next_write;
			end else begin
				ctrl_in_a[9:0] <= 10'b0;
			end
	
			/* verilator lint_off ALWCOMBORDER */
			/* verilator lint_on ALWCOMBORDER */
		
			addr_a 		<= 	curr_write;
			ctrl_wen_a 	<=	1'b1;
			new_block	<=	1'b0;
			read_next	<=	1'b1;
		end
		
		/* Read the next free block */
		if (read_next == 1'b1) begin
			ctrl_wen_a	<=	1'b0;
			addr_a		<=  next_write;

			read_next	<=	1'b0;
			update_next <=  1'b1;
		end	

		/* Determine if the next free block is in a chain */
		if (update_next == 1'b1) begin
			/* verilator lint_off ALWCOMBORDER */
			curr_write <= next_write;
			$display("curr_write %b\n", curr_write);
			if (next_ctrl == 10'b0) begin
				next_write <= next_write + 1;
			end else begin
				next_write <= next_ctrl;
			end
			$display("next_write %b\n", next_write);

			update_next <= 1'b0;
		end	

		if (ctrl_out_a != ctrl_in_a) begin
			next_ctrl 		<= 	ctrl_out_a[9:0];
		end
		
		if (free_en) begin
			ctrl_wen_b 		<=	1'b1; 		    
			empty_blocks	<=	empty_blocks + 1;
			next_write		<=  raddr;
		end

		if (ctrl_wen_b == 1'b1) begin
			ctrl_wen_b	<=	1'b0;
		end

		packet_addr		<=	curr_write;
		next_read		<=  ctrl_out_b[9:0];
		ctrl_in_b		<= 	{1'b0, next_write};	
		addr_b	 		<= 	raddr;
    end

    true_dual_port_mem #(.MEM_SIZE(1024), .DATA_WIDTH(`D_WIDTH)) cmem
	(	
		.clk(clk), 
		.aa(addr_a), 		.ab(addr_b),
		.da(ctrl_in_a),		.db(ctrl_in_b),
		.wa(ctrl_wen_a),	.wb(ctrl_wen_b),
		.qa(ctrl_out_a),	.qb(ctrl_out_b)
	);
endmodule


