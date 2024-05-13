`define IN_0 4'b0000
`define IN_1 4'b0001
`define IN_2 4'b0010
`define IN_3 4'b0011
`define IN_4 4'b0100
`define IN_5 4'b0101
`define IN_6 4'b0110
`define IN_7 4'b0111
`define IN_IDLE 4'b1000


`define OUT_0 4'b0000
`define OUT_1 4'b0001
`define OUT_2 4'b0010
`define OUT_3 4'b0011
`define OUT_4 4'b0100
`define OUT_5 4'b0101
`define OUT_6 4'b0110
`define OUT_7 4'b0111
`define OUT_IDLE 4'b1000

module ingress (
	input logic 		clk,

	input logic	[31:0]	packet_in, // From packet gen, getting packet
	input logic 		packet_en, // From packet gen, meaning that we should start recving a packet segment
	input logic 		new_packet_en, // From packet gen, meaning that we should start recving a new packet

	input logic [1:0]	sched_sel, // From scheduler, the voq to dequeue the packet
	input logic			sched_done, // From scheduler, meaning that we should start sending a packet segment
	
	output logic		sched_en, // To sch
	output logic[31:0]	packet_out, // To crossbar
	output logic		packet_out_en // To crossbar
);

	logic [2:0] input_counter;
	logic [2:0] output_counter;
	
	logic [5:0]  next_remaining_packet_length, remaining_packet_length;
	logic [31:0] temp_packet_in;
	logic 		 alloc_en;
	logic [47:0] d_mac, next_d_mac;
	logic [31:0] packet_start_time_logic;
	logic [3:0]  in_state, next_in_state;
	logic [12:0] curr_d_write, curr_d_read;
	logic        voq_enqueue_en;
	logic [1:0]  voq_enqueue_sel, port_number;
	logic        first_packet;
	




	/* States */

	logic [3:0] out_state, next_out_state;

	/* time */
	logic [31:0] curr_time;


	logic free_en;
	logic [12:0] free_addr, next_free_addr;
	logic is_empty, is_full;
	logic [31:0] meta_out;
	logic        voq_dequeue_en;
	logic [1:0]  voq_dequeue_sel;


	always_comb begin
		case (in_state)
			`IN_IDLE: begin
				next_remaining_packet_length = packet_in[26:21];
				next_d_mac[47:32] 			 = packet_in[15:0];
				next_d_mac[31:0] 			 = 0;
				temp_packet_in 			     = packet_in;
				alloc_en 					 = 1;
				packet_start_time_logic      = curr_time;
				next_in_state 				 = `IN_0;
				curr_d_write				 = (first_packet == 1) ? 1 : alloc_addr;
				voq_enqueue_en               = 0;
				voq_enqueue_sel              = port_number;
			end
			`IN_0: begin
				next_remaining_packet_length = remaining_packet_length;
				next_d_mac[47:32] 			 = d_mac[47:32];
				next_d_mac[31:0] 			 = packet_in;
				temp_packet_in 				 = packet_in;
				alloc_en 					 = 0;
				next_in_state 				 = `IN_1;
				curr_d_write				 = alloc_addr+1;
				voq_enqueue_en               = 0;
				voq_enqueue_sel              = port_number;
			end
			`IN_1: begin
				next_remaining_packet_length = remaining_packet_length;
				next_d_mac                   = d_mac;
				temp_packet_in 				 = curr_time;
				alloc_en 					 = 0;
				next_in_state				 = `IN_2;
				curr_d_write				 = alloc_addr+2;
				voq_enqueue_en               = 1;
				voq_enqueue_sel              = port_number;
				
			end
			`IN_2: begin
				next_remaining_packet_length = remaining_packet_length;
				next_d_mac                   = d_mac;
				temp_packet_in				 = packet_in;
				alloc_en 					 = 0;
				next_in_state				 = `IN_3;
				curr_d_write				 = alloc_addr+3;
				voq_enqueue_en               = 0;
				voq_enqueue_sel              = port_number;
			end
			`IN_3: begin
				next_remaining_packet_length = remaining_packet_length;
				next_d_mac 					 = d_mac;
				temp_packet_in 				 = packet_in;
				alloc_en 					 = 0;
				next_in_state				 = `IN_4;
				curr_d_write				 = alloc_addr+4;
				voq_enqueue_en               = 0;
				voq_enqueue_sel              = port_number;
			end
			`IN_4: begin
				next_remaining_packet_length = remaining_packet_length;
				next_d_mac 					 = d_mac;
				temp_packet_in 				 = packet_in;
				alloc_en 					 = 0;
				next_in_state				 = `IN_5;
				curr_d_write				 = alloc_addr+5;
				voq_enqueue_en               = 0;
				voq_enqueue_sel              = port_number;
			end
			`IN_5: begin
				next_remaining_packet_length = remaining_packet_length;
				next_d_mac 					 = d_mac;
				temp_packet_in 				 = packet_in;
				alloc_en 					 = 0;
				next_in_state				 = `IN_6;
				curr_d_write				 = alloc_addr+6;
				voq_enqueue_en               = 0;
				voq_enqueue_sel              = port_number;
			end
			`IN_6: begin
				voq_enqueue_en               = 0;
				voq_enqueue_sel              = port_number;
				if(remaining_packet_length > 1) begin	
					next_in_state                   = `IN_6;
				end else begin
					next_in_state 					= `IN_IDLE;
				end

				next_remaining_packet_length = remaining_packet_length - 1;
				next_d_mac 					 = d_mac;
				temp_packet_in 				 = packet_in;

				if((curr_time - packet_start_time_logic) % 8 == 0) begin
					alloc_en 					 = 1;
					curr_d_write				 = alloc_addr;
				end else begin
					alloc_en = 0;
					curr_d_write				 = alloc_addr + ((curr_time - packet_start_time_logic) % 8);
				end
				

			end
			default: begin end
			
		endcase
/*
		case (out_state)
			`OUT_0: begin
			end
			`OUT_1: begin
			end
			`OUT_2: begin
			end
			`OUT_3: begin
			end
			`OUT_4: begin
			end
			`OUT_5: begin
			end
			`OUT_6: begin
			end
			`OUT_7: begin
			end
		endcase
*/
	end



	always_ff @(posedge clk) begin
		if (reset) begin
			in_state <= `IN_IDLE;
			curr_time <= 0;
			remaining_packet_length <= 0;
			first_packet            <= 1;
		end // if reset
		else begin
			/* Time driver*/
			curr_time <= curr_time + 1;

			/* Input */
			if (packet_en) begin
				first_packet <= 0;
				in_state <= next_in_state;
				d_mac <= next_d_mac;
				remaining_packet_length <= next_remaining_packet_length;
			end
/*
			//Output 
			if (sched_en) begin
				out_state <= next_out_state;
			end
*/
		end
	end


	vmu #(.PACKET_CNT(1024), .EGRESS_CNT(4)) voq_mu
	(
		// Input
		.clk(clk), 
		.voq_enqueue_en(voq_enqueue_en), .voq_enqueue_sel(voq_enqueue_sel),
		.voq_dequeue_en(voq_dequeue_en), .voq_dequeue_sel(voq_dequeue_sel),
		.meta_in(alloc_addr),

		// Output
		.meta_out(meta_out),
		.is_empty(is_empty), .is_full(is_full)
	);

	cmu ctrl_mu
	(
		// Input when inputting
		.clk(clk), 
		.reset(reset),

		// From input
    	.remaining_packet_length(remaining_packet_length), // in blocks
		.alloc_en(alloc_en), // writing data in

		// From output
		.free_addr(free_addr),
		.free_en(free_en),

    	// To input
		.alloc_addr(alloc_addr),

		// To output
		.next_free_addr(next_free_addr) // retrieve the "next" of the free_addr
	);

	simple_dual_port_mem #(.MEM_SIZE(1024*8), .DATA_WIDTH(32)) dmem
	(	
		.clk(clk), 
		.ra(curr_d_read), .wa(curr_d_write),
		.d(temp_packet_in),	.q(packet_out),
		.write(packet_en)
	);

	mac_to_port mac_to_port_2(.DMAC(dmac), .port_number(port_number));


endmodule



// 	always @(posedge clk) begin
// 		input_counter <= (input_counter == 3'b111) ? 3'b000 : counter + 1;
// 		output_counter <= (input_counter == 3'b111) ? 3'b000 : counter + 1;
// 		case(input_counter)
// 			3'b000: begin
// 				if (packet_en) begin
// 					input_counter <= 3'b001;
// 					remaining_packet_length <= packet_in[31:16] >> 5;
// 					d_mac[47:32] <= packet_in[15:0];
// 					/* CMU, CMU already have the next empty block available, it's directly inside of alloc_addr */

// 					/* This is to tell CMU that we've already consumed alloc_addr -> get us a new one */
// 					alloc_en <= 1'b1;

// 					/* trigger to write the first segment of the packet at the current alloc_addr */
// 					write_en <= 

// 					curr_d_write <= alloc_addr;
// 				end

// 				/* DMem */
// 				/* Write to DMem (last segment of the previous packet) */
// 				// What if there's nothing in the prev cycle (so it shouldn't be inside packet_en)
										  
// 			end
// 			3'b001: begin
// 				/* enqueue to voq */
// 				voq_enqueue_en <= 1;
// 				voq_enqueue_sel <= d_mac[]

// 				/* CMU */
// 				alloc_en <= 1'b0;
// 				d_mac[31:0]	<=	packet_in;
// 			end
// 			3'b010: begin
// 			end
// 			3'b011: begin
// 			end
// 			3'b100: begin
// 			end
// 			3'b101: begin
// 			end
// 			3'b110: begin
// 			end
// 			3'b111: begin
// 			end
// 			default: input_counter <= 3'b000;	
// 		endcase

// 		case(output_counter)
// 			3'b000: begin
// 				if (sched_en) begin
// 					output_counter <= 3'b001;
// 				end		  
// 			end
// 			3'b001: begin
// 			end
// 			3'b010: begin
// 			end
// 			3'b011: begin
// 			end
// 			3'b100: begin
// 			end
// 			3'b101: begin
// 			end
// 			3'b110: begin
// 			end
// 			3'b111: begin
// 			end
// 			default: input_counter = 3'b000;	
// 		endcase
// 	end

// 	vmu #(.PACKET_CNT(1024), .EGRESS_CNT(4)) voq_mu
// 	(
// 		// Input
// 		.clk(clk), 
// 		.voq_enqueue_en(), .voq_enqueue_sel(),
// 		.voq_dequeue_en(), .voq_dequeue_sel(),
// 		.meta_in(alloc_addr),

// 		// Output
// 		.meta_out(),
// 		.is_empty(), .is_full()
// 	);

// 	cmu ctrl_mu
// 	(
// 		// Input when inputting
// 		.clk(clk), 

// 		// From input
//     	.remaining_packet_length(remaining_packet_length), // in blocks
// 		.alloc_en(ctrl_wen), // writing data in

// 		// From output
// 		.free_addr(),
// 		.free_en(),

//     	// To input
// 		.alloc_addr(alloc_addr),

// 		// To output
// 		.next_free_addr() // retrieve the "next" of the free_addr
// 	);

// 	simple_dual_port_mem #(.MEM_SIZE(1024*8), .DATA_WIDTH(32)) dmem
// 	(	
// 		.clk(clk), 
// 		.ra(curr_d_read), .wa(curr_d_write),
// 		.d(packet_in),	.q(packet_out),
// 		.write(write_en)
// 	);


// endmodule
