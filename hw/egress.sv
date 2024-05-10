

/*
 * Packet metadata (32 bits) definition:
 * 	src port: 2 bits
 * 	dest port: 2 bits
 * 	length: 6 bits (Packet size is 32 Bytes * length, min is 1 block = 32 Bytes, max is 64 * 32 Bytes)
 *    timestamp: 22 bits (delta)
 *
 * Input metadata contains the timestamp
 *
 * Output metadata contains the timestamp (delta)
 *    meta_out <= {dest, src, time_delta, packet_len};
 *
 * Part of packet (by definition)
 * 	Length: 2 Bytes (00000xxxxx)
 * 	Dest MAC: 6 Bytes
 * 	Src MAC: 6 Bytes
 * 	Start time
 * 	End time
 *
 * Part of packet (by block)
 * 	Length: 2 Bytes + Dest MAC: 6 Bytes
 * 	Time stamp: 4 bytes (start) + 4 bytes (end)
 *	 	Src MAC: 6 Bytes + 2 garbage byte
 * 	Data payload all 1's for now for the rest of the bits (at least 8 bytes)
 */

`define WORD_SIZE 8
`define BLOCK_SIZE (32 * `WORD_SIZE)
`define META_SIZE 16

typedef enum logic [3:0] {
	IDLE,
	RECEIVE_LENGTH_DEST_MAC_FST,
	RECEIVE_LENGTH_DEST_MAC_SND,
	RECEIVE_SRC_MAC_FST,
	RECEIVE_SRC_MAC_SND,
	RECEIVE_TIME_STAMPS_FST,
	RECEIVE_TIME_STAMPS_SND,
	DONE
} state_packet_val;

module pack_val #(
    parameter PACKET_XFER_LEN = 32,
    parameter BUFFER_LEN = 1024
) (
	input logic clk,
	input logic reset,
	input logic data_en,
	input logic [31:0] data_in,

	// output logic meta_en,
	output logic [31:0] meta_out
);

	localparam PACKET_XFER_WIDTH = $clog2(PACKET_XFER_LEN);
	localparam BUFFER_PTR_WIDTH = $clog2(BUFFER_LEN);

	state_packet_val state;
	logic meta_en;
	logic [11:0] packet_len, bytes_sent;
	logic [21:0] time_delta;

	logic [31:0] meta_data, time_start, time_end;


	// assign done = (bytes_sent == packet_len);
	assign time_delta = time_end - time_start;


	// set meta_en and build meta_data in the state machien
    always_ff @(posedge clk) begin
     	if (reset) begin
			data_out <= 0;
			data_valid <= 0;
			state <= IDLE;
    	 end else begin
			case (state)
				// collapsing `RECEIVE_LENGTH_DEST_MAC_FST` into `IDLE` state w/ read_en
				// set meta_data[11:0] := length
				// @TODO: currently using the lower two bits of the MAC addr as the port
				// will replace with real logic after MAC-to-port module is implemented
				IDLE: begin
					if (read_en) begin
                  packet_len <= data_in[11:0];
                  state <= RECEIVE_LENGTH_DEST_MAC_SND;
					end
					packet_len <= 0;
					time_start <= 0;
					time_end <= 0;
					done <= 0;
					state <= IDLE;
          	end

				// @TODO: update `dest` (all 4 bytes) after implementing MAC-to-port
				RECEIVE_LENGTH_DEST_MAC_SND: begin
					state <= RECEIVE_SRC_MAC_FST;
				end

				// @TODO: update `src` (all 4 bytes) after implementing MAC-to-port
				RECEIVE_SRC_MAC_FST: begin
					state <= RECEIVE_SRC_MAC_SND;
				end

				// @TODO: update `src` (first 2 bytes) after implementing MAC-to-port
				RECEIVE_SRC_MAC_SND: begin
					state <= RECEIVE_TIME_STAMPS_FST;
				end

				// start
				RECEIVE_TIME_STAMPS_FST: begin
					state <= RECEIVE_TIME_STAMPS_SND;
				end

				// end
				RECEIVE_TIME_STAMPS_SND: begin
					state <= DONE;
				end

				DONE: begin
					state <= IDLE;
					meta_data <= {dest, src, time_delta, packet_len};
					done <= 1;
				end
        end
    end

	simple_dual_port_mem #(
		.MEM_SIZE(PACKET_CNT),
		.DATA_WIDTH(8)
	) vmem (
		.clk(clk),
		.ra(start_idx),
		.wa(end_idx),
		.d(data_en),
		.q(meta_data),
		.write(meta_en) // write_en
	);

endmodule

module egress #(
	parameter PACKET_XFER_LEN = 32,
	parameter BUFFER_LEN = 1024
) (
    input logic clk,
    input logic reset,
    input logic write_en, // Comes from the ingress buffer
    input [PACKET_XFER_LEN-1:0] data_in,
    input logic read_en, // Comes from the software
	 input [31:0] counter,

    output [PACKET_XFER_LEN-1:0] data_out,
    output logic buffer_empty,
    output logic buffer_full
);

	localparam PACKET_XFER_WIDTH = $clog2(PACKET_XFER_LEN);
	localparam BUFFER_PTR_WIDTH = $clog2(BUFFER_LEN);

	// 16 bits == metadata for one full packet
	logic [`BLOCK_SIZE-1:0] buffer[BUFFER_LEN-1:0];
	logic [BUFFER_PTR_WIDTH-1:0] head, tail;
	logic [PACKET_XFER_WIDTH-1:0] packet_len, processed_bits;
	logic done;

	assign buffer_empty = (head == tail);
	assign buffer_full = ((tail + 1) % BUFFER_LEN) == head;

	always_ff @(posedge clk) begin
	  if (reset) begin: RESET_EGRESS_BUFFERS
	      head <= 0;
	      tail <= 0;
	      processed_bits <= 0;
	  end else begin
	      if (write_en && !buffer_full) begin: READ_METADATA
	          buffer[tail] <= data_in;
	          tail <= (tail + 1) % BUFFER_LEN;
	      end

	      if (read_en && !buffer_empty) begin: PROCESS_PACKET
	          if (done) begin
	              head <= (head + 1) % BUFFER_LEN;
	              processed_bits <= 0;
	          end else begin
	              processed_bits <= processed_bits + 1;
	          end
	      end
	  end
	end

	pack_val #(
	     .PACKET_XFER_LEN(PACKET_XFER_LEN),
	     .BUFFER_LEN(BUFFER_LEN)
	 ) pack_val_0 (
	     .clk(clk),
	     .reset(reset),
	     .meta_in(buffer[head][15:0]), // Pass the metadata from the buffer
	     .meta_valid(read_en), // Use read_en as meta_valid
	     .data_out(data_out),
	     .data_valid(data_valid),
	     .done(done)
	 );

endmodule
