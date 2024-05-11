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

`define IDLE 4'b0000
`define LENGTH_DMAC_FST 4'b0001
`define LENGTH_DMAC_SND 4'b0010
`define TIME_FST 4'b0011
`define TIME_SND 4'b0100
`define SMAC_FST 4'b0101
`define SMAC_SND 4'b0110
`define PAYLOAD 4'b0111



module packet_val #(parameter PACKET_CNT = 1023, BLOCK_SIZE = 32, META_WIDTH = 32)
(
    input logic            clk,
    input logic            reset,
	
	// From crossbar
    input logic [META_WIDTH-1:0] egress_in,
    input logic            egress_in_en,

	// From interface
    input logic            egress_out_ack,

	// To interface
    output logic [31:0]    egress_out
);
/* verilator lint_off UNUSED */
    logic [META_WIDTH-1:0] temp_egress_out;
    
    logic [$clog2(PACKET_CNT)-1: 0] start_idx; // The first element
    logic [$clog2(PACKET_CNT)-1: 0] end_idx; // One pass the last element
    logic meta_ready;
    logic [15:0] remaining_length;
    logic [15:0] next_remaining_length;
    logic [47:0] DMAC;
    logic [5:0] length_in_blocks;
    logic [1:0] port_number;
    logic [31:0] start_time, next_start_time;

    logic [31:0] time_stamp; 

    logic [3:0]  state, next_state;
    logic [15:0] temp_length;
    assign temp_length = (egress_in[31:16] >> 5);
    assign length_in_blocks = temp_length[5:0];

    assign temp_egress_out[21:0] = time_stamp[21:0];

    // SMAC_FST, SMAC_SND Are not used

    

    always_comb begin
        case(state)
	    `IDLE           : begin
		next_state = `LENGTH_DMAC_FST;
		temp_egress_out = 32'b0;
		meta_ready = 0;
		temp_egress_out[27:22]     = length_in_blocks;
	
		next_remaining_length = egress_in[31:16] - 4;
		DMAC[47:32] = egress_in[15:0];
	    end //START
	    `LENGTH_DMAC_FST : begin
		next_state = `LENGTH_DMAC_SND;
		meta_ready = 0;
		DMAC[31:0] = egress_in;
		next_remaining_length = remaining_length - 4;
	    end // LENGTH_DMAC_FST
	    `LENGTH_DMAC_SND : begin
		//next_remaining_length = egress_out[27:22];
		next_remaining_length = remaining_length - 4;
		next_state = `TIME_FST;
		temp_egress_out[29:28] = port_number;
		next_start_time = egress_in;
		//packet     = DMAC[31:0];
		meta_ready = 0;
	    end // LENGTH_DMAC_SND
	    `TIME_FST        : begin
		next_state = `TIME_SND;
		time_stamp = egress_in - start_time;
		//packet     = {10'b0, egress_out[21:0]};
		meta_ready = 0;
		next_remaining_length = remaining_length - 4;
	    end // TIME_FST	
	    `TIME_SND        : begin
		next_state = `SMAC_FST;
		next_remaining_length = remaining_length - 4;		
		//packet     = 32'b0;
		meta_ready = 0;
	    end // TIME_SND
	    `SMAC_FST        : begin
		next_state = `SMAC_SND;
		temp_egress_out[31:30] = egress_in[1:0];		
		//packet     = {30'b0, egress_out[31:30]};
		meta_ready = 0;
		next_remaining_length = remaining_length - 4;
	    end //SMAC_FST
	    `SMAC_SND        : begin
		next_state = `PAYLOAD;
		next_remaining_length = remaining_length - 4;
		//packet     = {30'b0, egress_out[31:30]};
		meta_ready = 0;
	    end //SMAC_SND
	    `PAYLOAD     : begin
		//packet     = ~0;
		//packet_ready = 1;
		if(remaining_length > 0) begin
		    next_remaining_length = remaining_length - 4;
		    next_state        = `PAYLOAD;
		    meta_ready        = 0;
		end // remaining_length > 0
		else begin
		    next_state        = `IDLE; //UNDER QUESTION (GREATER THAN 0 OR GREATER THAN 1)
		    meta_ready        = 1;
		end // else remaining_length < 0
	    end // SRC_PAYLOAD	
	    default: begin
		meta_ready = 0;
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
	    if(egress_in_en) begin
	        if(next_state == `IDLE) begin
		    end_idx <= (end_idx != PACKET_CNT - 1) ? end_idx + 1 : 0;
	        end 
	        state <= next_state;
		remaining_length <= next_remaining_length;
		start_time <= next_start_time;
	    end //meta_en
	    if(egress_out_ack && (start_idx != end_idx)) begin	
	        
		start_idx <= (start_idx != PACKET_CNT - 1) ? start_idx + 1 : 0;
	        
   	    end // egress_out_ack
	end // not reset

    end //always_ff


	simple_dual_port_mem #(.MEM_SIZE(PACKET_CNT), .DATA_WIDTH(32)) vmem
	(	
		.clk(clk), 
		.ra(start_idx), .wa(end_idx),
		.d(temp_egress_out),	.q(egress_out),
		.write(meta_ready)
	);

	mac_to_port mac_to_port_0(
		.MAC(DMAC),
		.port_number(port_number)
	);

endmodule
