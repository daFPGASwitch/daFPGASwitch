/*

Packet metadata definition:
* src port: 2 bits
* dest port: 2 bits
* length: 12 bit (Packet size is 32 Bytes * length, min is 1 block = 32 Bytes, max is 64 * 32 Bytes)


Part of packet (by definition)
* Length: 2 Bytes (00000xxxxx)
* Dest MAC: 6 Bytes
* Src MAC: 6 Bytes
* Start time
* End time

Part of packet (by block)
* Length: 2 Bytes + Dest MAC: 6 Bytes
* Time stamp: 8 bytes
* Src MAC: 2 garbage byte + 6 Bytes
* Data payload all 1's for now for the rest of the bits (at least 8 bytes)

*/

`define IDLE 4'b0000
`define LENGTH_DMAC_FST 4'b0001
`define LENGTH_DMAC_SND 4'b0010
`define TIME_FST 4'b0011
`define TIME_SND 4'b0100
`define SMAC_FST 4'b0101
`define SMAC_SND 4'b0110
`define PAYLOAD 4'b0111



module packet_gen #(
    parameter PACKET_CNT = 1024,
    BLOCK_SIZE = 32,
    META_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  reset,

    input  logic [META_WIDTH-1:0] packet_gen_in,
    input  logic                  packet_gen_in_en,
    input  logic                  experimenting,

	// To Ingress
    output logic                  packet_gen_out_en,
    output logic [31:0]           packet_gen_out
);
  logic [META_WIDTH-1:0] meta_out;

  logic [$clog2(PACKET_CNT)-1:0] start_idx;  // The first element
  logic [$clog2(PACKET_CNT)-1:0] end_idx;  // One pass the last element

  logic [5:0] remaining_length;
  logic [5:0] next_remaining_length;
  logic [47:0] DMAC, SMAC;  // A lot of registers, be really careful!
  logic [15:0] length_in_bits;
  logic [3:0] state, next_state;
  assign length_in_bits = meta_out[27:22] * 32;
  // SMAC_FST, SMAC_SND Are not used


  always_comb begin
    case (state)
      `IDLE: begin
        next_state   = `LENGTH_DMAC_FST;
        packet_gen_out = 0;
        packet_gen_out_en = 0;
        next_remaining_length = remaining_length;
      end  //START
      `LENGTH_DMAC_FST: begin
        next_state   = `LENGTH_DMAC_SND;
        packet_gen_out       = {length_in_bits, DMAC[47:32]};
        packet_gen_out_en = 1;
        next_remaining_length = remaining_length;
      end  // LENGTH_DMAC_FST
      `LENGTH_DMAC_SND: begin
        next_remaining_length = meta_out[27:22];
        next_state            = `TIME_FST;
        packet_gen_out                = DMAC[31:0];
        packet_gen_out_en          = 0;
        next_remaining_length = remaining_length;
      end  // LENGTH_DMAC_SND
      `TIME_FST: begin
        next_state   = `TIME_SND;
        packet_gen_out       = {10'b0, meta_out[21:0]};
        packet_gen_out_en = 0;
        next_remaining_length = remaining_length;
      end  // TIME_FST	
      `TIME_SND: begin
        next_state   = `SMAC_FST;
        packet_gen_out       = 32'b0;
        packet_gen_out_en = 0;
        next_remaining_length = remaining_length;
      end  // TIME_SND
      `SMAC_FST: begin
        next_state   = `SMAC_SND;
        packet_gen_out       = {16'b0, SMAC[47:32]};
        packet_gen_out_en = 0;
        next_remaining_length = remaining_length;
      end  //SMAC_FST
      `SMAC_SND: begin
        next_state   = `PAYLOAD;
        packet_gen_out       = SMAC[31:0];
        packet_gen_out_en = 0;
        next_remaining_length = remaining_length;
      end  //SMAC_SND
      `PAYLOAD: begin
          if (remaining_length > 1) begin
              next_remaining_length = remaining_length - 1;
              next_state = `PAYLOAD;
          end else begin
              next_remaining_length = 0;
              next_state = `IDLE;
          end
          packet_gen_out = ~32'b0;
          packet_gen_out_en = 0;
      end
      default: begin
        packet_gen_out_en = 0;
        packet_gen_out = 0;
        next_remaining_length = remaining_length;
        next_state = state;

      end
    endcase  //end case

  end  // end always_comb


  always_ff @(posedge clk) begin
    if (reset) begin
      start_idx <= 0;
      end_idx   <= 0;
      state     <= `IDLE;
      //packet_gen_out_en = 0;
    end //if reset
	else begin
      if (packet_gen_in_en) begin
        end_idx <= (end_idx == 1023) ? 0 : end_idx + 1;

      end  //packet_gen_in_en
      if (experimenting && (start_idx != end_idx)) begin
        if (state == `IDLE) begin
          start_idx <= (start_idx != 1023) ? start_idx + 1 : 0;
        end
        state <= next_state;
        remaining_length <= next_remaining_length;
      end  // experimenting
    end  // not reset

  end  //always_ff


  simple_dual_port_mem #(
      .MEM_SIZE  (PACKET_CNT),
      .DATA_WIDTH(32)
  ) vmem (
      .clk(clk),
      .ra(start_idx),
      .wa(end_idx),
      .d(packet_gen_in),
      .q(meta_out),
      .write(packet_gen_in_en)
  );

  port_to_mac port_to_mac_0 (
      .port_number(meta_out[29:28]),
      .MAC(DMAC)
  );
  port_to_mac port_to_mac_1 (
      .port_number(meta_out[31:30]),
      .MAC(SMAC)
  );

endmodule
