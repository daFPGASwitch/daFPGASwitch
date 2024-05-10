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
* Src MAC: 6 Bytes + 2 garbage byte
* Data payload all 1's for now for the rest of the bits (at least 8 bytes)

*/
//enum logic [3:0] {IDLE, LENGTH_DMAC_FST, LENGTH_DMAC_SND, TIME_FST, TIME_SND, SMAC_FST, SMAC_SND, PAYLOAD} state;

`define IDLE 4'b0000
`define LENGTH_DMAC_FST 4'b0001
`define LENGTH_DMAC_SND 4'b0010
`define TIME_FST 4'b0011
`define TIME_SND 4'b0100
`define SMAC_FST 4'b0101
`define SMAC_SND 4'b0110
`define PAYLOAD 4'b0111



module packet_gen #(parameter PACKET_CNT = 1023, BLOCK_SIZE = 32, META_WIDTH = 16)
(
    input logic            clk,
    input logic            reset,
    input logic            meta_en,
    input logic            send_en,
    //input [1:0] src_port;
    input logic [META_WIDTH-1:0] meta_in,
    output logic           packet_ready,
    output logic [31:0]    packet
);
    logic [META_WIDTH-1:0] meta_out;

    logic [$clog2(PACKET_CNT)-1: 0] start_idx; // The first element
    logic [$clog2(PACKET_CNT)-1: 0] end_idx; // One pass the last element

    logic [11:0] remaining_length;
    logic [11:0] next_remaining_length;
    logic [47:0] DMAC;
    logic [15:0] length_in_bits;
    logic [3:0]  state, next_state;
    assign length_in_bits = meta_out[11:0] * 32;
    // SMAC_FST, SMAC_SND Are not used
    

    always_comb begin
        case(state)
	    `IDLE           : begin
		next_state = `LENGTH_DMAC_FST;
		packet_ready = 0;
	    end //START
	    `LENGTH_DMAC_FST : begin
		next_state = `LENGTH_DMAC_SND;
		packet     = {length_in_bits, DMAC[47:32]};
		packet_ready = 1;
	    end // LENGTH_DMAC_FST
	    `LENGTH_DMAC_SND : begin
		next_remaining_length = meta_out[11:0];
		next_state = `TIME_FST;
		packet     = DMAC[31:0];
		packet_ready = 1;
	    end // LENGTH_DMAC_SND
	    `TIME_FST        : begin
		next_state = `TIME_SND;
		packet     = 32'b0;
		packet_ready = 1;
	    end // TIME_FST	
	    `TIME_SND        : begin
		next_state = `SMAC_FST;
		packet     = 32'b0;
		packet_ready = 1;
	    end // TIME_SND
	    `SMAC_FST        : begin
		next_state = `SMAC_SND;
		packet     = {30'b0, meta_out[15:14]};
		packet_ready = 1;
	    end //SMAC_FST
	    `SMAC_SND        : begin
		next_state = `PAYLOAD;
		packet     = {30'b0, meta_out[15:14]};
		packet_ready = 1;
	    end //SMAC_SND
	    `PAYLOAD     : begin
		packet     = ~0;
		packet_ready = 1;
		if(remaining_length > 0) begin
		    next_remaining_length = remaining_length - 1;
		    next_state        = `PAYLOAD;
		end // remaining_length > 0
		else begin
		    next_state        = `IDLE; //UNDER QUESTION (GREATER THAN 0 OR GREATER THAN 1)
		end // else remaining_length < 0
	    end // SRC_PAYLOAD	
	    default: begin
		packet_ready = 0;
	    end 
	    


	endcase //end case

    end // end always_comb


    always_ff @(posedge clk) begin
	if(reset) begin
	    start_idx <= 0;
	    end_idx   <= 0;
	    state     <= `IDLE;
	    //packet_ready = 0;
	end //if reset
	else begin
	    if(meta_en) begin
	        end_idx <= (end_idx != PACKET_CNT - 1) ? end_idx + 1 : 0;
	        
	    end //meta_en
	    if(send_en) begin	
	        if(next_state == `IDLE) begin
		    start_idx <= (start_idx != PACKET_CNT - 1) ? start_idx + 1 : 0;
	        end 
	        state <= next_state;
		remaining_length <= next_remaining_length;
   	    end // send_en
	end // not reset

    end //always_ff


	simple_dual_port_mem #(.MEM_SIZE(PACKET_CNT), .DATA_WIDTH(16)) vmem
	(	
		.clk(clk), 
		.ra(start_idx), .wa(end_idx),
		.d(meta_in),	.q(meta_out),
		.write(meta_en)
	);

	port_to_mac port_to_mac_0(
		.port_number(meta_out[13:12]),
		.MAC(DMAC)
	);

endmodule
