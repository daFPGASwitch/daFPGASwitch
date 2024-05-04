module ingress (
	input logic 		clk,

	input logic[31:0] 	packet_in,
	input logic 		new_packet_en, write_en, sched_done,
	input logic[3:0]	sched_sel,
	
	output logic[31:0]	packet_out
);

	// VOQ Registers
	reg[9:0] start_idx0, end_idx0;

	// ctrl registers
	reg[9:0] 	curr_write, curr_read, next_write, next_read, empty_blocks;
	reg[3:0]	write_offset, read_offset;
	reg[5:0] 	remaining_packet_len;			//In terms of 32 Byte blocks
	reg[10:0]	ctrl_in, ctrl_out;				//1 bit allocated + 10 bits of address
	logic		ctrl_wen_a, ctrl_wen_b;
	reg[9:0]	meta_in, meta_out;
	logic		voq_wen;
	logic		new_block;
	

	// data registers
	reg[12:0]	curr_d_write, curr_d_read;

	initial begin
		packet_out 			 <= 31'b0;
		start_idx0 			 <= 10'b0;
		end_idx0   			 <= 10'b0;
		curr_write 			 <= 10'b0;
		curr_read			 <= 10'b0;
		next_write			 <= 10'b0;
		next_read			 <=	10'b0;
		write_offset		 <= 4'b0;			//Used to count upto 8
		read_offset			 <= 4'b0;
		remaining_packet_len <=	6'b0;
		curr_d_write		 <= 13'b0;
		curr_d_read			 <= 13'b0;
		new_block			 <= 1'b0;
	end

	// Instantiate DMEM, CMEM and VMEM
	simple_dual_port_mem #(.MEM_SIZE(1024*8), .DATA_WIDTH(32)) dmem
	(	
		.clk(clk), 
		.ra(curr_d_read), .wa(curr_d_write),
		.d(packet_in),	.q(packet_out),
		.write(write_en)
	);

	true_dual_port_mem #(.MEM_SIZE(1024), .DATA_WIDTH(16)) cmem
	(	
		.clk(clk), 
		.aa(curr_write), 	.ab(curr_read),
		.da(ctrl_in),		.db(ctrl_in),
		.wa(ctrl_wen_a),	.wb(ctrl_wen_b),
		.qa(ctrl_out),		.qb(ctrl_out)
	);

	simple_dual_port_mem #(.MEM_SIZE(1024*8), .DATA_WIDTH(16)) vmem
	(	
		.clk(clk), 
		.ra(start_idx0), .wa(end_idx0),
		.d(meta_in),	.q(meta_out),
		.write(voq_wen)
	);


	always @(posedge clk) begin
		if (write_en) begin
			case(write_offset)
				0000:	begin
					if (new_packet_en) begin
						/* Check requested length. Write if there's sapce */
						remaining_packet_len <= packet_in[15:0] / 32;
						if (remaining_packet_len < empty_blocks) begin
							new_block <= 1'b0;
						end

					if (new_blocki) begin
						/* Start writing to dmem */
						curr_d_write <= (next_write * 8) + write_offset; 

						/* Format control data for cmem */
						empty_blocks <= empty_blocks - remaining_packet_len;

						// Update where to write the new packet
						curr_write <= next_write;
						if (ctrl_out[10:1] == 10'b0) begin
							next_write <= next_write + 1;
						end else begin
							next_write <= ctrl_out[10:1];
						end

						// Decide on chain and format control data
						ctrl_in[0] <= 1'b1;
						if (packet_in[15:0] / 32 > 1) begin
							ctrl_in[10:1] <= ctrl_out[10:1];
						end else begin
							ctrl_in[10:1] <= 10'b0;
						end
						
						/* Write to the control block */
						crtl_wen_a <= 1'b1;

						/* Increase offset */
						write_offset <= write_offset + 1;	
					end

					/* Dequeue the VOQ */
					start_idx0 = start_idx0 + 1;
												
				end
	
				0001:	begin
					/* Write to dmem */
					curr_d_write <= curr_d_write + write_offset;
	
					/* Update VOQ metadata */
					meta_in <= curr_write;

					write_offset <= write_offset + 1;  
				end

				0010:	begin
					/* Write to dmem */
					curr_d_write <= curr_d_write + write_offset;
				
					write_offset <= write_offset + 1;

					/* Read from dmem */
					curr_d_read <= (curr_read * 8) + 1;
					  
				end

				0011:	begin
					/* Write to dmem */
					curr_d_write <= curr_d_write + write_offset;
					
					/* Write to vmem */
					voq_wen <= 1'b1;
					end_idx0 <= end_idx0 + 1;
					
					write_offset <= write_offset + 1;  
				end
				
				0100:	begin
					/* Write to dmem */
					curr_d_write <= curr_d_write + write_offset;
					write_offset <= write_offset + 1;  
				end

				0101:	begin
					/* Write to dmem */
					curr_d_write <= curr_d_write + write_offset;
					write_offset <= write_offset + 1;  
				end

				0110:	begin
					/* Write to dmem */
					curr_d_write <= curr_d_write + write_offset;
					
					write_offset <= write_offset + 1; 

					/* Read next write control */
					curr_read <= meta_out; 
				end

				0111:	begin
					/* Write to dmem */
					curr_d_write <= curr_d_write + write_offset;
					
					/* Reset counter */
					write_offset <= 4'b0;
					new_block <= 1'b1;

					/* Determine next free address */
					next_free = ctrl_out[10:1];  
				end

				default: write_offset = 4'b0;	
					
			end
				
		end

			
