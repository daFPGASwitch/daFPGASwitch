module hw_sw_interface(
    input logic clk,

    // From sw
    input logic        reset,
    input logic [31:0] writedata,
    input logic        write,
    input logic        read,
    input logic [ 2:0] address,
    input logic        chipselect,

    // From egress
    input logic [31:0] interface_in,

    // To sw
    output logic [31:0] readdata,

    // To packet_val/ingress
    // Change to 4 bits later
    output logic interface_out_en,
    output logic [31:0] interface_out,

    // Experimenting
    output logic experimenting,

    // Special case: Because we're polling but not handling interrupt
    // we need to acknowledge that this metadata is consumed by the software.
    // This is the only ack in our program. 
    // Change to 4 bits later
    output logic interface_out_ack
);

  logic [31:0] ctrl;

  always_comb begin
    experimenting = (ctrl == 2);
  end

  always_ff @(posedge clk) begin
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
            interface_out_en <= 1;
            // interface_out_en[0] <= 1;
            interface_out <= writedata;
          end
          3'h2: begin
            // interface_out_en[1] <= 1;
            interface_out <= writedata;
          end
          3'h3: begin
            // interface_out_en[2] <= 1;
            interface_out <= writedata;
          end
          3'h4: begin
            // interface_out_en[3] <= 1;
            interface_out <= writedata;
          end
          default: begin
          end
        endcase
      end else begin
        // interface_out_en[0] <= 0;
        // interface_out_en[1] <= 0;
        // interface_out_en[2] <= 0;
        // interface_out_en[3] <= 0;
        interface_out_en <= 0;
        interface_out <= 0;
      end
      if (chipselect && read) begin
        readdata <= interface_in;
        case (address)
          3'h1: begin
            readdata <= interface_in;
            // interface_out_ack[0] <= 1;
            interface_out_ack <= 1;
          end
          3'h2: begin
            readdata <= interface_in;
            // interface_out_ack[1] <= 1;
          end
          3'h3: begin
            readdata <= interface_in;
            // interface_out_ack[2] <= 1;
          end
          3'h4: begin
            readdata <= interface_in;
            // interface_out_ack[3] <= 1;
          end
          default: begin
          end
        endcase
      end else begin
        readdata <= 0;
        interface_out_ack <= 0;
        // interface_out_ack[0] <= 0;
        // interface_out_ack[1] <= 0;
        // interface_out_ack[2] <= 0;
        // interface_out_ack[3] <= 0;
      end
    end
  end

endmodule
