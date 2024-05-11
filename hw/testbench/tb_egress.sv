`timescale 1ns / 1ps

module tb_egress;

	localparam PACKET_XFER_LEN = 32;
	localparam BUFFER_LEN = 1024;

	logic clk;
	logic reset;
	logic write_en;
	logic [PACKET_XFER_LEN-1:0] data_in;
	logic read_en;
	logic [31:0] counter;

   logic [PACKET_XFER_LEN-1:0] data_out, expected;
   logic buffer_empty;
   logic buffer_full;
  	logic out_valid;

    egress #(
     	.PACKET_XFER_LEN(PACKET_XFER_LEN),
      .BUFFER_LEN(BUFFER_LEN)
    ) uut (
		.clk(clk),
		.reset(reset),
		.write_en(write_en),
		.data_in(data_in),
		.read_en(read_en),
		.counter(counter),
		.data_out(data_out),
		.buffer_empty(buffer_empty),
		.data_valid(out_valid),
		.buffer_full(buffer_full)
    );

    always #5 clk = ~clk;

    initial begin
		clk = 0;
		reset = 1;
		write_en = 0;
		data_in = 0;
		read_en = 0;
		counter = 0;

		#100;
		reset = 0;

		$display("\nPacket 1");
		@(posedge clk);
		write_en = 1;
		data_in = {8'd40, 8'b0, 8'd2, 8'b0};  // Packet 1
		@(posedge clk);
		write_en = 0;
		data_in = {32'b0};                   // Packet 2 (empty data)
		@(posedge clk);
		data_in = {8'b0, 8'b0, 8'd3, 8'b0};  // Packet 3
		@(posedge clk);
		data_in = {32'b0};                   // Packet 4 (empty data)
		@(posedge clk);
		data_in = 32'd5;                     // Start time
		@(posedge clk);
		data_in = 32'd12;                    // End time
		@(posedge clk);
		data_in = {32'b1};
		@(posedge clk);
		data_in = '{default:1};
		@(posedge clk);

      $display("\nPacket 2");
		write_en = 1;
		data_in = {8'd24, 8'b0, 8'd2, 8'b0};  // Packet 1 (len=24, dest=2)
		@(posedge clk);
		data_in = {32'b0};                   // Packet 2 (empty data)
		write_en = 0;
		@(posedge clk);
		data_in = {8'b0, 8'b0, 8'd1, 8'b0};  // Packet 3 (src=1)
		@(posedge clk);
		data_in = {32'b0};                   // Packet 4 (empty data)
		@(posedge clk);
		data_in = 32'd3;                     // Start time (t=3)
		@(posedge clk);
		data_in = 32'd19;                    // End time (t=19)
		@(posedge clk);
		data_in = {32'b1};                   // Payload
		@(posedge clk);
		data_in = {32'b1};                   // Payload
		@(posedge clk);

		#10;
		expected = 32'b10111010000000000000000000000111;
		read_en = 1;
		wait(out_valid);
		@(posedge clk);
		read_en = 0;

      $display("Packet 3");
		write_en = 1;
		data_in = {8'd40, 8'b0, 8'd2, 8'b0};  // Packet 1
		@(posedge clk);
		write_en = 0;
		data_in = {32'b0};                   // Packet 2 (empty data)
		@(posedge clk);
		data_in = {8'b0, 8'b0, 8'd3, 8'b0};  // Packet 3
		@(posedge clk);
		data_in = {32'b0};                   // Packet 4 (empty data)
		@(posedge clk);
		data_in = 32'd5;                     // Start time
		@(posedge clk);
		data_in = 32'd12;                    // End time
		@(posedge clk);
		data_in = {32'b1};
		@(posedge clk);
		data_in = {32'b1};
		@(posedge clk);


		$display("Case 5: Simultaneous read_en & write_en");
		write_en = 1;
		expected = 32'b10010110000000000000000000010000;
		read_en = 1;
		data_in = {8'd40, 8'b0, 8'd2, 8'b0};  // Packet 1
		@(posedge clk);
		read_en = 0;
		write_en = 0;
		data_in = {32'b0};                   // Packet 2 (empty data)
		@(posedge clk);
		data_in = {8'b0, 8'b0, 8'd3, 8'b0};  // Packet 3
		@(posedge clk);
		data_in = {32'b0};                   // Packet 4 (empty data)
		@(posedge clk);
		data_in = 32'd5;                     // Start time
		@(posedge clk);
		data_in = 32'd12;                    // End time
		@(posedge clk);
		data_in = {32'b1};
		@(posedge clk);
		data_in = {32'b1};
		@(posedge clk);

		#50;
		$finish;
   end

  	logic checked_result;

   always @(posedge clk) begin
      if (read_en) begin
        $display("SOFTWARE READING PACKET");
        checked_result <= 1;
      end else if (checked_result && out_valid) begin
         assert(data_out == expected)
         else $error("Software received the wrong data: %b (expected: %b)", data_out, expected);
        checked_result <= 0;
      end
    end

	task next_clock_cycle;
    	@(posedge clk);
    	counter <= counter + 1;
    	$display("Cycle %0d", counter);
	endtask

endmodule
