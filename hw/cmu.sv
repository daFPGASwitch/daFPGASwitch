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
    input logic alloc_en, free_en, reset,
    input logic [9:0] free_addr, 

    output logic [9:0] alloc_addr = 10'b0, // the address in cmem for the first chunk of the packet
	output logic [9:0] next_free_addr = 10'b0
);
	
	
    // Registers
    /* verilator lint_off UNOPTFLAT */ 
    logic[9:0]	curr_write;
	logic[9:0]	next_write;
	logic[5:0]	empty_blocks;
	/* verilator lint_on UNOPTFLAT */
	logic[`D_WIDTH-1:0]	ctrl_in_a  = `D_WIDTH'b0;
	logic[`D_WIDTH-1:0]	ctrl_in_b  = `D_WIDTH'b0;
	/* verilator lint_off UNUSED */
	logic[`D_WIDTH-1:0]	ctrl_out_a, ctrl_out_b;
	/* verilator lint_on UNUSED */
	logic		ctrl_wen_a, ctrl_wen_b;
	//logic[9:0]  next_ctrl;
	logic[9:0]	addr_a, addr_b;
	
	/* Create state control variables */
	logic[2:0]	input_state		 	= 3'b0;
	logic[2:0]	next_input_state 	= 3'b0;
	logic[1:0]	output_state	 	= 2'b0;
	logic[1:0]	next_output_state	= 2'b0;

	/* Temporary variables */
	logic[5:0]	temp_empty_blocks;
	logic[9:0]	temp_next_write;
	logic[9:0]	temp_curr_write;

	always_comb begin
		/* Create input state machine */
		case (input_state)
			/* Determine CMEM space availability  
 			 * Read the next control */
			3'b000:	begin
				ctrl_wen_a		  = 1'b0;
				if (alloc_en == 1'b1) begin
					if (remaining_packet_length < empty_blocks) begin
						temp_empty_blocks = empty_blocks - 1;
						addr_a	=	next_write;
												
						next_input_state	 = 3'b001;
					end else begin
						alloc_addr	 		= 10'b0;
						next_input_state	= 3'b000;
						temp_empty_blocks 	= empty_blocks;
					end
					
				end else begin
					next_input_state	= 3'b000;
					temp_empty_blocks 	= empty_blocks;
				end

			end

			/* Determine the next write */
			3'b001:	begin
				if (ctrl_out_a == 11'b0) begin
					temp_next_write = next_write + 1;
				end else begin
					temp_next_write = ctrl_out_a[9:0];
				end

				next_input_state =	3'b010;
			end

			3'b010: begin
				
				next_input_state	=	3'b011;
			end

			3'b011: begin
			
				next_input_state = 3'b100;
			end
 			
			3'b100: begin

				next_input_state =  3'b101;
			end

			3'b101:	begin

				next_input_state = 3'b110;
			end	
			
			3'b110:	begin   
					
				next_input_state = 3'b111;			
			end

			/* Format the control and write to cmem
 			 * Return the next free address */
			3'b111: begin
				ctrl_in_a[10] = 1'b1;
				
				if (remaining_packet_length > 1) begin
					ctrl_in_a[9:0] = next_write;
				end else begin
					ctrl_in_a[9:0] = 10'b0;
				end

				alloc_addr		 = next_write;
				temp_curr_write	 = next_write;
				
				ctrl_wen_a		 = 1'b1;
				addr_a			 = curr_write;

				next_input_state = 3'b0;
			end
		
			default: begin
			end

		endcase


		/* Create output state machine */
		case (output_state)
			/* Request to read control of the given address 
 			 * Format control to deallocate address*/
			2'b00:	begin
				if (free_en == 1'b1) begin
					ctrl_wen_b	 = 1'b0;
					
					addr_b		 = free_addr;
	
					ctrl_in_b    = {1'b0, next_write};
			
					next_output_state = 2'b01;
				end
			end

			/* Read the control of the given address 
 			 * Write to deallocate control memory */
			2'b01: begin
				next_free_addr  =  ctrl_out_b[9:0]; 
	
				ctrl_wen_b		=  1'b1;
				
				temp_empty_blocks	=  empty_blocks + 1;
				temp_next_write		=  free_addr;
				next_output_state	=  2'b10;
			end

			2'b10: begin
				ctrl_wen_b	= 1'b0;

				next_output_state  =  2'b00;
			end

			default: begin
			end
		endcase


	end
	   
	always @(posedge clk) begin
		if (reset == 1'b1) begin
			empty_blocks <= 6'b111111;
			next_write	 <= 10'h1;
			curr_write 	 <= 10'b1;

			input_state  <= 3'b0;
			output_state <= 2'b0;

		end else begin
			input_state  <= next_input_state;
			output_state <= next_output_state;
		
			empty_blocks <= temp_empty_blocks;	
			if (temp_next_write != 10'b0) begin
				next_write	 <= temp_next_write;
			end

			if (temp_curr_write != 10'b0) begin
				curr_write   <= temp_curr_write;
			end
			
		end
		

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

