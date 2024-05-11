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
    logic meta_en, send_en, packet_ready, done, buffer_empty, buffer_full;
    logic [31:0] meta_in, packet, ctrl, meta_out;
    //metadata_o meta_out;
    assign send_en = (ctrl == 32'h2) ? 1 : 0;
    
    packet_gen ingress_1(.clk(clk), .reset(reset), .meta_en(meta_en), .send_en(send_en), .meta_in(meta_in), .packet_ready(packet_ready), .packet(packet));
    //packet_gen ingress_2();
    //packet_gen ingress_3();
    //packet_gen ingress_4();
    egress     egress_1 (.clk(clk), .reset(reset), .write_en(packet_ready), .data_in(packet), .read_en(read), .data_out(meta_out), .data_valid(done), .buffer_empty(buffer_empty), .buffer_full(buffer_full));
    //egress     egress_2 ();
    //egress     egress_3 ();
    //egress     egress_4 ();
    hw_sw_interface hw_sw_interface_0(.clk(clk), .reset(reset), .ctrl(ctrl), .done(done), .writedata(writedata), .write(write), .read(read), .address(address), .data_from_egress(meta_out), .chipselect(chipselect), .readdata(readdata), .meta_en(meta_en), .meta_in(meta_in));

endmodule
