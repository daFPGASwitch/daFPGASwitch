module ingress (
	input logic 		clk,

	input logic	[31:0]	packet_in, // From packet gen, getting packet
	input logic 		packet_en, // From packet gen, meaning that we should start recving a packet segment

	input logic [1:0]	sched_sel, // From scheduler, the voq to dequeue the packet
	input logic			sched_done, // From scheduler, meaning that we should start sending a packet segment
	
	output logic		sched_en, // To sch
	output logic[31:0]	packet_out, // To crossbar
	output logic		packet_out_en // To crossbar
);

	logic [2:0] input_counter;
	logic [2:0] output_counter;
	
	always @(posedge clk) begin
		input_counter <= (input_counter == 3'b111) ? 3'b000 : counter + 1;
		output_counter <= (input_counter == 3'b111) ? 3'b000 : counter + 1;
		case(input_counter)
			3'b000: begin
				if (packet_en) begin
					input_counter <= 3'b001;
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
		.meta_in(),

		// Output
		.meta_out(),
		.is_empty(), .is_full()
	);

	cmu ctrl_mu
	(
		// Input when inputting
		.clk(clk), 
    	.remaining_packet_length(), // in blocks
		.wen(), // writing data in

		// Input when outputting
		.free_en(),
  		.raddr(), 

    	// output
		.packet_addr() // The addr of the data block, ready after first free_en/wen
	);

	simple_dual_port_mem #(.MEM_SIZE(1024*8), .DATA_WIDTH(32)) dmem
	(	
		.clk(clk), 
		.ra(curr_d_read), .wa(curr_d_write),
		.d(packet_in),	.q(packet_out),
		.write(write_en)
	);


endmodule