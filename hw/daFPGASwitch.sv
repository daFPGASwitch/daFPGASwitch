`include "switch_defs.svh"
module daFPGASwitch #()
(
    // From sw
    input logic clk,
    input logic reset,
    input logic [31:0]  writedata, 
    input logic         write,
    input logic         read,
    input logic [2:0]   address,
    input logic         chipselect,

    // To sw
    output logic [31:0] readdata
); 

    logic meta_in_en, packet_en;
    logic [31:0] meta_in, packet, meta_out;
    logic experimenting;
    // Change to 4 bit later.
    logic meta_out_ack;
    
    packet_gen ingress_0(
        // Input
        .clk(clk), .reset(reset),
        .packet_gen_in_en(meta_in_en), .experimenting(experimenting),
        .packet_gen_in(meta_in),
    
        // Output
        .packet_gen_out_en(packet_en), .packet_gen_out(packet));

    packet_val egress_0 (
        // Input
        .clk(clk), .reset(reset),
        .egress_in(packet),
        .egress_in_en(packet_en), .egress_in_ack(meta_out_ack),
        
        // Output
        .egress_out(meta_out));

    hw_sw_interface hw_sw_interface (
        .clk(clk),

        // Input: sw->interface
        .reset(reset),
        .writedata(writedata),// sw->hw
        .write(write), // sw->hw
        .read(read), // hw->sw
        .address(address),
        .chipselect(chipselect),

        // Input: hw->interface
        .interface_in(meta_out),
        
        // Output: interface->sw
        .readdata(readdata),

        // Output: interface->egress (ack)
        .interface_out_ack(meta_out_ack),

        // Output: To ingress/packet_val
        .interface_out_en(meta_in_en),
        .interface_out(meta_in),

        // Output: Ongoing experiment.
        .experimenting(experimenting)

    );

endmodule
