`define IN_0 4'b0000
`define IN_1 4'b0001
`define IN_2 4'b0010
`define IN_3 4'b0011
`define IN_4 4'b0100
`define IN_5 4'b0101
`define IN_6 4'b0110
`define IN_7 4'b0111
`define IN_IDLE 4'b1000


`define IDLE 2'b00
`define SEND_META_2_CMU 2'b01
`define GET_NEXT_ADDR 2'b10
`define SEND_PACKET 2'b11

module ingress (
	input logic 		clk,
	input logic	[31:0]	packet_in, // From packet gen, getting packet
	input logic 		packet_en, // From packet gen, meaning that we should start recving a packet segment
	input logic 		new_packet_en, // From packet gen, meaning that we should start recving a new packet

	input logic [1:0]	sched_sel, // From scheduler, the voq to dequeue the packet
	input logic			sched_done, // (actually SCHED_ENABLE) From scheduler, meaning that we should start sending a packet segment
	
	// output logic		sched_en, // To sch
	output logic[31:0]	packet_out, // To crossbar
	output logic		packet_out_en // To crossbar
);

	logic [2:0] input_counter;
	logic [2:0] send_cycle_counter, next_send_cycle_counter;
	
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
	logic [9:0] free_addr, next_free_addr, voq_meta_out, voq_meta_out_reg, free_addr_reg, next_free_addr_reg;
	logic is_empty, is_full;
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
				curr_d_write				 = (first_packet == 0) ? 1 : alloc_addr;
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
				if(remaining_packet_length > 0) begin	
					next_remaining_packet_length = remaining_packet_length - 1;
					next_in_state                   = `IN_6;
					next_d_mac 					 = d_mac;
					temp_packet_in 				 = packet_in;

				end else begin 
					next_remaining_packet_length = 0;
					next_in_state 					 = `IN_IDLE;
					next_d_mac 					 = 48'b0;
					temp_packet_in 				 = 32'b0;

				end
				if((curr_time - packet_start_time_logic) % 8 == 0) begin
					alloc_en = 1;
					curr_d_write				 = alloc_addr;
				end else begin
					alloc_en = 0;
					curr_d_write				 = alloc_addr + ((curr_time - packet_start_time_logic) % 8);
				end
				

			end
			default: begin end
		endcase

		case (out_state)
			`IDLE: begin
				free_en = 1'b0;
				free_addr = voq_meta_out;
				voq_meta_out_reg = meta_out;
				next_send_cycle_counter = 0;
				next_out_state = (sched_done) ? `SEND_META_2_CMU : `IDLE_SND; // no packet or no decision
			end
			`SEND_META_2_CMU: begin
				free_en = 1'b1;
				free_addr = voq_meta_out;
				curr_d_read = voq_meta_out;
			
				next_send_cycle_counter = 1;
				next_out_state = `GET_NEXT_ADDR;
			end
			`GET_NEXT_ADDR: begin
				free_en = 1'b0;
				free_addr = voq_meta_out;
				free_addr_reg = next_free_addr;
				curr_d_read = voq_meta_out + send_cycle_counter;
				next_send_cycle_counter = 2;
				next_out_state = `SEND_PACKET;
			end
			`SEND_PACKET: begin
				free_en = 1'b0;
				free_addr = voq_meta_out;
				curr_d_read = voq_meta_out + send_cycle_counter;
				next_send_cycle_counter = (send_cycle_counter == 7) ? 0 : (send_cycle_counter + 1);
				if (send_cycle_counter == 7 && next_free_addr_reg != 10'b0) begin
					next_out_state = `SEND_META_2_CMU;
					voq_meta_out_reg = next_free_addr_reg;
				end else if (send_cycle_counter == 7 && next_free_addr_reg == 10'b0) begin
					next_out_state = `IDLE;
				end else begin
					next_out_state = `SEND_PACKET;
				end
			end
			default: begin
			end
		endcase
	end

	assign next_free_addr_reg = free_addr_reg;


	always_ff @(posedge clk) begin
		if (reset) begin
			in_state <= `IDLE;
			out_state <= `IDLE;
			curr_time <= 0;
			remaining_packet_length <= 0;
			first_packet            <= 0;
			send_cycle_counter <= 0;
		end // if reset
		else begin
			/* Time driver*/
			curr_time <= curr_time + 1;

			/* Input */
			if (packet_en) begin
				first_packet <= 1;
				in_state <= next_in_state;
				d_mac <= next_d_mac;
				remaining_packet_length <= next_remaining_packet_length;
			end
			if (sched_done) begin
				out_state <= next_out_state;
				voq_meta_out <= voq_meta_out_reg;
				send_cycle_counter <= next_send_cycle_counter;
			end

		end
	end

	vmu #(.PACKET_CNT(1024), .EGRESS_CNT(4)) voq_mu(
		// Input
		.clk(clk), 
		.voq_enqueue_en(voq_enqueue_en), .voq_enqueue_sel(voq_enqueue_sel),
		.voq_dequeue_en(sched_done), .voq_dequeue_sel(sched_sel),
		.meta_in(alloc_addr),
		// Output
		.meta_out(meta_out),
		.is_empty(is_empty), .is_full(is_full)
	);

	cmu ctrl_mu(
		// Input when inputting
		.clk(clk), 
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

	simple_dual_port_mem #(.MEM_SIZE(1024*8), .DATA_WIDTH(32)) dmem(	
		.clk(clk), 
		.ra(curr_d_read), .wa(curr_d_write),
		.d(temp_packet_in),	.q(packet_out),
		.write(packet_en)
	);

	mac_to_port mac_to_port_2(.DMAC(dmac), .port_number(port_number));


endmodule
