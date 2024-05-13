/* verilator lint_off UNUSED */
module simple_interface(
    input logic clk,

    // From sw
    input logic        reset,
    input logic [31:0] writedata,
    input logic        write,
    input logic        read,
    input logic [ 2:0] address,
    input logic        chipselect,

    // From egress
    input logic [31:0] interface_in_0,
    input logic [31:0] interface_in_1,
    input logic [31:0] interface_in_2,
    input logic [31:0] interface_in_3,

    // To sw
    output logic [31:0] readdata,

    // To packet_val/ingress
    output logic [3:0] interface_out_en,
    output logic [31:0] interface_out,

    // Experimenting
    output logic experimenting,
    output logic simple_reset,
    // output logic send_only,

    // Special case: Because we're polling but not handling interrupt
    // we need to acknowledge that this metadata is consumed by the software.
    // This is the only ack in our program. 
    output logic [3:0] interface_out_ack,

    output logic sched_policy,
    output logic [7:0] sched_prio
);

  logic [31:0] ctrl;
  logic prev_read;

  always_comb begin
    experimenting = (ctrl[1:0] == 2);
    // send_only = (ctrl == 1);
    simple_reset = (ctrl[1:0] == 0) || reset;
    sched_policy = ctrl[2];
    sched_prio = ctrl[10:3];
  end

  always_ff @(posedge clk) begin
    prev_read <= read;
    if (reset) begin
      ctrl <= 32'h0;
      readdata <= 32'h0;
      interface_out_en <= 0;
      interface_out_ack <= 0;
      interface_out <= 0;
    end else begin
      if (chipselect && write) begin
        case (address)
          3'h0: begin
            ctrl <= writedata;
          end
          3'h1: begin
            interface_out_en[0] <= 1;
            interface_out <= writedata;
          end
          3'h2: begin
            interface_out_en[1] <= 1;
            interface_out <= writedata;
          end
          3'h3: begin
            interface_out_en[2] <= 1;
            interface_out <= writedata;
          end
          3'h4: begin
            interface_out_en[3] <= 1;
            interface_out <= writedata;
          end
          default: begin
          end
        endcase
      end else begin
        interface_out_en[0] <= 0;
        interface_out_en[1] <= 0;
        interface_out_en[2] <= 0;
        interface_out_en[3] <= 0;
      end
      if (chipselect && read && prev_read == 0) begin // Need rising edge detection?
        case (address)
          3'h1: begin
            readdata <= interface_in_0;
            interface_out_ack[0] <= 1;
          end
          3'h2: begin
            readdata <= interface_in_1;
            interface_out_ack[1] <= 1;
          end
          3'h3: begin
            readdata <= interface_in_2;
            interface_out_ack[2] <= 1;
          end
          3'h4: begin
            readdata <= interface_in_3;
            interface_out_ack[3] <= 1;
          end
          default: begin
          end
        endcase
      end else begin
        interface_out_ack[0] <= 0;
        interface_out_ack[1] <= 0;
        interface_out_ack[2] <= 0;
        interface_out_ack[3] <= 0;
      end
    end
  end

endmodule
