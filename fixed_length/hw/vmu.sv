/* 
The virtual output queue management unit: 
*/

/*
voq memory is divided into 16-bit chunks
and each of them represents a whole packet

Inside each chunk:
* an 10-bit address, which is the ctrl address of the first segment of the packet

The same packet in cmu (that needs 2 block) would be:
Address 0: 10'b1
*/

/*
The voq is implemented as a ring buffer. there are #egress voqs in each ingress.
Each voq can contain at most 1024 packets. (indexexd by the lower 10 bits of the memory)
The 2 higher bits represents which voq it is.

    [11, 10]       [9,8,7,6,5,4,3,2,1,0]
 ----voq_idx-----addr of 1st seg of packet------

*/


module vmu #(
    parameter PACKET_CNT = 1024,  /* How many packets can there be in each VOQ, 1024 by default */
    parameter EGRESS_CNT = 4 /* How many egress there are; which is also how many voqs there are. */
) (
    input logic clk,
    input logic reset,
    input logic voq_enqueue_en,
    input logic [$clog2(EGRESS_CNT)-1:0] voq_enqueue_sel,
    input logic voq_dequeue_en,
    input logic [$clog2(EGRESS_CNT)-1:0] voq_dequeue_sel,
    input logic [31:0] meta_in, // The address to find the first address of the packet

    /* TODO: How many bits for meta_out? */
    output logic [31:0] meta_out, // The content (first addr of the packet) saved for the dequeue packet
    output logic [EGRESS_CNT-1:0] is_empty, // For scheduler
    output logic [EGRESS_CNT-1:0] is_full // For potential packet drop. If is_full, then drop the current
);
    logic [$clog2(PACKET_CNT)+1:0] start_idx[3:0]; // first element
    logic [$clog2(PACKET_CNT)+1:0] end_idx[3:0]; // one pass the last element

    logic [$clog2(EGRESS_CNT):0] i;
    logic [$clog2(EGRESS_CNT)-1:0] _i;

    always_comb begin
        for (i = 0; i < EGRESS_CNT; i = i + 1) begin
            _i = i[$clog2(EGRESS_CNT)-1:0];
            is_empty[_i] = (start_idx[_i] == end_idx[_i]);
            is_full[_i] = (start_idx[_i] == ((end_idx[_i] == PACKET_CNT - 1) ? 0 : end_idx[_i] + 1));
        end
    end


    always @(posedge clk) begin
        if (reset) begin
            start_idx[0] <= 0;
            start_idx[1] <= 0;
            start_idx[0] <= 0;
            start_idx[1] <= 0;
            end_idx[0] <= 0;
            end_idx[1] <= 0;
            end_idx[2] <= 0;
            end_idx[3] <= 0;
        end else begin
            if (voq_enqueue_en && !is_full[voq_enqueue_sel]) begin
                end_idx[voq_enqueue_sel] <= (end_idx[voq_enqueue_sel] != PACKET_CNT - 1) ? end_idx[voq_enqueue_sel] + 1 : 0;
            end
            
            if (voq_dequeue_en && !is_empty[voq_dequeue_sel]) begin
                start_idx[voq_dequeue_sel] <=  (start_idx[voq_dequeue_sel] != PACKET_CNT - 1) ? start_idx[voq_dequeue_sel] + 1 : 0;
            end
        end
    end

	simple_dual_port_mem #(.MEM_SIZE(PACKET_CNT * EGRESS_CNT), .DATA_WIDTH(32)) vmem
	(	
		.clk(clk), 
		.ra(start_idx[voq_dequeue_sel]), .wa(end_idx[voq_enqueue_sel]),
		.d(meta_in),	.q(meta_out),
		.write(voq_enqueue_en)
	);

endmodule