`include "switch_defs.svh"
module top #()
(
    input logic clk,
    input logic reset,
    input logic [31:0]  writedata, 
    input logic         write,
    input logic         read,
    input logic [2:0]   address,
    input logic         chipselect,

    output logic [31:0] readdata
    
); 
    logic meta_en, send_en, packet_ready;
    logic [31:0] meta_in, packet, ctrl, meta_out;
    //metadata_o meta_out;
    assign send_en = (ctrl == 32'h2) ? 1 : 0;
    
    packet_gen ingress_1(.clk(clk), .reset(reset), .meta_en(meta_en), .send_en(send_en), .meta_in(meta_in), .packet_ready(packet_ready), .packet(packet));
    //packet_gen ingress_2();
    //packet_gen ingress_3();
    //packet_gen ingress_4();
    packet_val     packet_val_1 (.clk(clk), .reset(reset), .data_en(packet_ready), .send_en(read), .data_in(packet), .meta_out(meta_out));
    //egress     egress_2 ();
    //egress     egress_3 ();
    //egress     egress_4 ();
    hw_sw_interface hw_sw_interface_0(.clk(clk), .reset(reset), .ctrl(ctrl), .writedata(writedata), .write(write), .read(read), .address(address), .data_from_egress(meta_out), .chipselect(chipselect), .readdata(readdata), .meta_en(meta_en), .meta_in(meta_in));

endmodule
