`include "switch_defs.svh"

`define DEBUG

module pack_val #(
    parameter PACKET_XFER_LEN = 32,
    parameter BUFFER_LEN = 1024
) (
	input logic clk,
	input logic reset,
	input logic data_en,
	input logic [`BLOCK_SIZE-1:0] data_in,

	output metadata_o meta_out,
  	output logic done
);

	PACKET_METADATA_STATE state;
	logic meta_en;
	logic [`BLOCK_SIZE-1:0] meta_data, time_start, time_end;

  	integer counter;

	always_ff @(posedge clk) begin
		if (reset) begin
			state <= IDLE;
			counter <= 0;
		end else begin
			case (state)
				// @TODO: currently using the lower two bits of the MAC addr as the port
				// will replace with real logic after MAC-to-port module is implemented
			IDLE: begin
				if (data_en) begin
					meta_out <= '{dest: data_in[9:8], src: 2'b0, len: data_in[29:24], t_delta: 22'b0};
					time_start <= 32'b0;
					meta_en <= 0;
					state <= RECEIVE_LENGTH_DEST_MAC_SND;
					done <= 0;
               counter <= 0;
				end else begin
               state <= IDLE;
               counter <= 0;
            end
			end

			// @TODO: update `dest` (all 4 bytes) after implementing MAC-to-port
			RECEIVE_LENGTH_DEST_MAC_SND: begin
				meta_out <= meta_out;
				state <= RECEIVE_SRC_MAC_FST;
			end

			// @TODO: update `src` (all 4 bytes) after implementing MAC-to-port
			RECEIVE_SRC_MAC_FST: begin
				meta_out.src <= data_in[9:8];
				state <= RECEIVE_SRC_MAC_SND;
			end

			// @TODO: update `src` (first 2 bytes) after implementing MAC-to-port
			RECEIVE_SRC_MAC_SND: begin
				meta_out <= meta_out;
				state <= RECEIVE_TIME_STAMPS_FST;
`ifdef DEBUG
				$display("RECEIVE_SRC_MAC_SND\ttime_start=%b\tsrc=%b", data_in, meta_out.src);
`endif
			end
			RECEIVE_TIME_STAMPS_FST: begin
				time_start <= data_in;
				state <= RECEIVE_TIME_STAMPS_SND;
				$display("time_start=%b", data_in);
			end
			RECEIVE_TIME_STAMPS_SND: begin
				meta_out.t_delta <= data_in - time_start;
				state <= DONE;
`ifdef DEBUG
				$display("time_start=%b, time_end=%b", time_start, data_in);
`endif
			end
			DONE: begin
            if (counter) begin
              	state <= IDLE;
					done <= 1;
         	  	meta_en <= 1;
					counter <= 0;
`ifdef DEBUG
               $display("RECEIVED FULL PAYLOAD\tdest %b (%d)\tsrc %b (%d)\tlen %b (%d)", meta_out.dest, meta_out.dest, meta_out.src, meta_out.src, meta_out.len, meta_out.len);
`endif
            end else begin
            	counter <= counter + 1;
					done <= 0;
`ifdef DEBUG
               $display("DONE\ttime_delta=%b", meta_out.t_delta);
               $display("DONE\tdest %b (%d)\tsrc %b (%d)\tlen %b (%d)", meta_out.dest, meta_out.dest, meta_out.src, meta_out.src, meta_out.len, meta_out.len);
`endif
           	end
         end
			endcase
		end
 	end

	simple_dual_port_mem #(
		.MEM_SIZE(PACKET_CNT),
		.DATA_WIDTH(8)
	) vmem (
		.clk(clk),
		.ra(start_idx), // @TODO: set w/ actual start_idx
		.wa(end_idx),  // @TODO: set w/ actual end_idx
		.d(data_en),
		.q(meta_out),
		.write(meta_en)
	);

endmodule


module egress #(
	parameter PACKET_XFER_LEN = 32,
	parameter BUFFER_LEN = 1024
) (
	input logic clk,
	input logic reset,
	input logic write_en, // Comes from the ingress buffer
	input logic [PACKET_XFER_LEN-1:0] data_in,
	input logic read_en, // Comes from the software
	input logic [31:0] counter,

	// @TODO: update w/ actual packet data -> data_out
	// currently sends metadata -> data_out to software (for testing) until integrated
	output logic [PACKET_XFER_LEN-1:0] data_out,
	output logic data_valid,
	output logic buffer_empty,
	output logic buffer_full
);

	localparam BUFFER_PTR_WIDTH = $clog2(BUFFER_LEN);

	logic [`BLOCK_SIZE-1:0] buffer[BUFFER_LEN-1:0];
	logic [BUFFER_PTR_WIDTH-1:0] head, tail;
	logic done, process_packet_en, packet_meta_done, data_ready, pkt2meta_en, out_valid;
	logic [`BLOCK_SIZE-1:0] packet_in;

 	metadata_o meta_data;

	assign buffer_empty = (head == tail);
	assign buffer_full = ((tail + 1) % BUFFER_LEN) == head;

	integer count;
	integer cycle_count;
	always_ff @(posedge clk) begin
		if (reset) begin cycle_count <= 0; end
		else begin cycle_count <= cycle_count + 1; end
	end

	always_ff @(posedge clk) begin
`ifdef DEBUG
      $display("   Cycle %d (head=%d, tail=%d)\n", cycle_count, head, tail);
`endif
	  	if (reset) begin: RESET_EGRESS_BUFFERS
	      head <= 0;
	      tail <= 0;
			process_packet_en <= 0;
       	count <= 0;
	  	end else begin: NOT_RESET
    		if (write_en && count == 0) begin
            packet_in <= data_in;
          	process_packet_en <= 1;
            data_ready <= 1;
            count <= 0;
        	end else if ((data_ready) && count < 8) begin
        		process_packet_en <= 1;
            packet_in <= data_in;
            data_ready <= 1;
           	count <= count + 1;
        	end else if (packet_meta_done && count == 8) begin
            buffer[tail] <= meta_data;
            tail <= (tail + 1) % BUFFER_LEN;
            process_packet_en <= 0;
            count <= 0;
   			data_ready <= 0;
        	end
			if (out_valid) begin
            data_out <= buffer[head][31:0];
            data_valid <= 1;
         end else if (data_valid && !out_valid) begin
            head <= (head + 1) % BUFFER_LEN;
            data_valid <= 0;
         end
	  end
`ifdef DEBUG
      print_buffer();
`endif
	end

  	assign out_valid = (read_en && head != tail);
  	assign pkt2meta_en = process_packet_en && !buffer_full;

	pack_val #(
	     .PACKET_XFER_LEN(PACKET_XFER_LEN),
	     .BUFFER_LEN(BUFFER_LEN)
 	) pack_val_0 (
	     .clk(clk),
	     .reset(reset),
		  .data_en(pkt2meta_en),
		  .data_in(packet_in),
		  .meta_out(meta_data),
	     .done(packet_meta_done)
 	);

`ifdef DEBUG
  	task print_buffer;
    	$display("\nCurrent egress buffer contents:");
		for (int i = head; i < tail; i++) begin
      	$display("   buffer[%4d] = %b\n                 %2d | %2d | %6d | %d", i, buffer[i], buffer[i][31:30], buffer[i][29:28], buffer[i][27:22], buffer[i][21:0]);
		end
  	endtask
`endif

endmodule
