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



module pack_gen #(parameter PACKET_CNT = 1024, BLOCK_SIZE = 32, META_WIDTH = 16)
(
    input reset;
    input meta_en;
    input [1:0] src_port;
    input [META_WIDTH-1:0] meta_in;
    output [31:0] packet;
)
    logic [META_WIDTH-1:0] meta_out;

    logic [$clog2(PACKET_CNT)-1: 0] start_idx; // The first element
    logic [$clog2(PACKET_CNT)-1: 0] end_idx; // One pass the last element

    // Some state machine here
    // SMAC_FST, SMAC_SND Are not used
    enum logic [2:0] {LENGTH_DMAC_FST, LENGTH_DMAC_SND, TIME_FST, TIME_SND, SMAC_FST, SMAC_SND, PAYLOAD} state


    // always @(posedge clk) begin
    //     if reset begin
    //         start_idx <= 0;
    //         end_idx <= 0;
    //     end
    //     if (meta_en) begin
    //         end_idx <= (end_idx != PACKET_CNT - 1) ? end_idx + 1 : 0;
    //         length <= meta_in[11:0];
    //         state <= SENDING_LENGTH_EMAC;
    //     end else case state begin
    //         if (length == 1) begin
                
    //         end
    //         length <= length - 1;

    // end


	simple_dual_port_mem #(.MEM_SIZE(PACKET_CNT), .DATA_WIDTH(8)) vmem
	(	
		.clk(clk), 
		.ra(start_idx), .wa(end_idx),
		.d(meta_in),	.q(meta_out),
		.write(meta_en)
	);



endmodule