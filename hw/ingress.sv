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
	
	logic [5:0] remaining_packet_length;
	logic 		alloc_en;
	logic [47:0] d_mac;
	logic [47:0] s_mac;

	/* Input for dmem */
	logic [12:0] curr_d_write, curr_d_read; 

	always @(posedge clk) begin
		input_counter <= (input_counter == 3'b111) ? 3'b000 : counter + 1;
		output_counter <= (input_counter == 3'b111) ? 3'b000 : counter + 1;
		case(input_counter)
			3'b000: begin
				if (packet_en) begin
					input_counter <= 3'b001;
					remaining_packet_length <= packet_in[31:16] >> 5;
					d_mac[47:32] <= packet_in[15:0];
					/* CMU, CMU already have the next empty block available, it's directly inside of alloc_addr */

					/* This is to tell CMU that we've already consumed alloc_addr -> get us a new one */
					alloc_en <= 1'b1;

					/* trigger to write the first segment of the packet at the current alloc_addr */
					write_en <= 

					curr_d_write <= alloc_addr;
				end

				/* DMem */
				/* Write to DMem (last segment of the previous packet) */
				// What if there's nothing in the prev cycle (so it shouldn't be inside packet_en)
										  
			end
			3'b001: begin
				/* enqueue to voq */
				voq_enqueue_en <= 1;
				voq_enqueue_sel <= d_mac[]

				/* CMU */
				alloc_en <= 1'b0;
				d_mac[31:0]	<=	packet_in;
			end
			3'b010: begin
			end
			3'b011: begin
			end
			3'b100: begin
			end
			3'b101: begin
			end
			3'b110: begin
			end
			3'b111: begin
			end
			default: input_counter <= 3'b000;	
		endcase

		case(output_counter)
			3'b000: begin
				if (sched_en) begin
					output_counter <= 3'b001;
				end		  
			end
			3'b001: begin
			end
			3'b010: begin
			end
			3'b011: begin
			end
			3'b100: begin
			end
			3'b101: begin
			end
			3'b110: begin
			end
			3'b111: begin
			end
			default: input_counter = 3'b000;	
		endcase
	end

	vmu #(.PACKET_CNT(1024), .EGRESS_CNT(4)) voq_mu
	(
		// Input
		.clk(clk), 
		.voq_enqueue_en(), .voq_enqueue_sel(),
		.voq_dequeue_en(), .voq_dequeue_sel(),
		.meta_in(alloc_addr),

		// Output
		.meta_out(),
		.is_empty(), .is_full()
	);

	cmu ctrl_mu
	(
		// Input when inputting
		.clk(clk), 

		// From input
    	.remaining_packet_length(remaining_packet_length), // in blocks
		.alloc_en(ctrl_wen), // writing data in

		// From output
		.free_addr(),
		.free_en(),

    	// To input
		.alloc_addr(alloc_addr),

		// To output
		.next_free_addr() // retrieve the "next" of the free_addr
	);

	simple_dual_port_mem #(.MEM_SIZE(1024*8), .DATA_WIDTH(32)) dmem
	(	
		.clk(clk), 
		.ra(curr_d_read), .wa(curr_d_write),
		.d(packet_in),	.q(packet_out),
		.write(write_en)
	);


endmodule
