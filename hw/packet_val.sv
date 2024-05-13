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



module packet_val #(
    parameter PACKET_CNT = 1023,
    BLOCK_SIZE = 32,
    META_WIDTH = 32
) (
    input logic clk,
    input logic reset,

    // From crossbar
    input logic [META_WIDTH-1:0] egress_in,
    input logic                  egress_in_en,

    // From interface
    input logic egress_in_ack,

    // To interface
    output logic [31:0] egress_out
);
  /* verilator lint_off UNUSED */
  logic [META_WIDTH-1:0] next_meta;
  logic [META_WIDTH-1:0] meta;

  logic [$clog2(PACKET_CNT)-1:0] start_idx;  // The first element
  logic [$clog2(PACKET_CNT)-1:0] end_idx;  // One pass the last element
  logic meta_ready;
  logic [15:0] remaining_length;
  logic [15:0] next_remaining_length;
  logic [47:0] next_DMAC, DMAC;
  logic [5:0] length_in_blocks;
  logic [1:0] port_number;
  logic [31:0] start_time, next_start_time;
  logic [31:0] delta;

  logic [3:0] state, next_state;
  // logic [15:0] temp_length;
  // assign temp_length = (egress_in[31:16] >> 5);
  // assign length_in_blocks = temp_length[5:0];

  // SMAC_FST, SMAC_SND Are not used

  always_comb begin
    length_in_blocks = egress_in[26:21];
    delta = (egress_in - start_time);
    case (state)
      `IDLE: begin
        next_state             = `LENGTH_DMAC_FST;
        next_meta[31:28]        = 0;
        next_meta[21:0]         = 0;
        meta_ready             = 0;
        next_meta[27:22] = length_in_blocks;
        next_start_time        = 0;

        next_remaining_length  = egress_in[31:16] - 4;
        next_DMAC[47:32]            = egress_in[15:0];
        next_DMAC[31:0] = DMAC[31:0];
      end  //START
      `LENGTH_DMAC_FST: begin
        next_state = `LENGTH_DMAC_SND;
        meta_ready = 0;
        next_DMAC[31:0] = egress_in;
        next_DMAC[47:32] = DMAC[47:32];
        next_meta = meta;
        next_remaining_length = remaining_length - 4;
        next_start_time = start_time;
      end  // LENGTH_DMAC_FST
      `LENGTH_DMAC_SND: begin
        //next_remaining_length = egress_out[27:22];
        next_remaining_length = remaining_length - 4;
        next_state = `TIME_FST;
        next_meta[31:30] = meta[31:30];
        next_meta[29:28] = port_number;
        next_meta[27:0] = meta[27:0];
        next_start_time = egress_in;
        next_DMAC = DMAC;
        meta_ready = 0;
      end  // LENGTH_DMAC_SND
      `TIME_FST: begin
        next_state = `TIME_SND;
        next_meta[21:0] = delta[21:0];
        next_meta[31:22] = meta[31:22];
        meta_ready = 0;
        next_remaining_length = remaining_length - 4;
        next_start_time = start_time;
        next_DMAC = DMAC;
      end  // TIME_FST	
      `TIME_SND: begin
        next_state = `SMAC_FST;
        next_remaining_length = remaining_length - 4;
        next_meta = meta;
        meta_ready = 0;
        next_start_time = start_time;
        next_DMAC = DMAC;
      end  // TIME_SND
      `SMAC_FST: begin
        next_state = `SMAC_SND;
        next_meta[31:30] = egress_in[1:0];
        next_meta[29:0] = meta[29:0];
        meta_ready = 0;
        next_remaining_length = remaining_length - 4;
        next_start_time = start_time;
        next_DMAC = DMAC;
      end  //SMAC_FST
      `SMAC_SND: begin
        next_state = `PAYLOAD;
        next_remaining_length = remaining_length - 4;
        next_meta = meta;
        meta_ready = 0;
        next_start_time = start_time;
        next_DMAC = DMAC;
      end  //SMAC_SND
      `PAYLOAD: begin
        if (remaining_length > 4) begin
          next_remaining_length = remaining_length - 4;
          next_state            = `PAYLOAD;
          meta_ready            = 0;
          next_meta             = meta;
          next_start_time = start_time;
          next_DMAC             = DMAC;
        end // remaining_length > 0
		else begin
          next_remaining_length = remaining_length;
          next_state = `IDLE;  //UNDER QUESTION (GREATER THAN 0 OR GREATER THAN 1)
          meta_ready = 1;
          next_meta = meta;
          next_start_time = start_time;
          next_DMAC       = DMAC;
        end  // else remaining_length < 0
      end  // SRC_PAYLOAD	
      default: begin
        meta_ready = 0;
      end

    endcase  //end case

  end  // end always_comb


  always_ff @(posedge clk) begin
    if (reset) begin
      start_idx <= 0;
      end_idx   <= 0;
      state     <= `IDLE;
    end //if reset
	else begin

      /* packet->meta, the input*/ 
      if (egress_in_en) begin
        if (next_state == `IDLE) begin
          end_idx <= (end_idx != PACKET_CNT - 1) ? end_idx + 1 : 0;
        end
        state <= next_state;
        remaining_length <= next_remaining_length;
        start_time <= next_start_time;
        meta <= next_meta;
        DMAC <= next_DMAC;
      end  //meta_en

      /* Output */
      if (egress_in_ack && (start_idx != end_idx)) begin

        start_idx <= (start_idx != PACKET_CNT - 1) ? start_idx + 1 : 0;

      end  // egress_in_ack
    end  // not reset

  end  //always_ff


  simple_dual_port_mem #(
      .MEM_SIZE  (PACKET_CNT),
      .DATA_WIDTH(32)
  ) meta_mem (
      .clk(clk),
      .ra(start_idx),
      .wa(end_idx),
      .d(meta),
      .q(egress_out),
      .write(meta_ready)
  );

  mac_to_port mac_to_port_0 (
      .MAC(DMAC),
      .port_number(port_number)
  );

endmodule
