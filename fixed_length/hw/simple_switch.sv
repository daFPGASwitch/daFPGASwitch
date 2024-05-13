module simple_switch
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
    /* verilator lint_off UNUSED */
    logic [3:0] meta_in_en;
    logic [3:0] packet_en;
    logic [3:0] meta_out_ack;
    logic [7:0] sched_sel;
    logic [3:0] sched_sel_en;

    logic [31:0] meta_in;
    // logic [127:0] meta_out;
    logic [31:0] meta_out[4];
    logic [127:0] packet;
    logic [127:0] packet_out;
    logic [3:0] packet_out_en;
    logic experimenting;
    logic [15:0] empty;
    logic [10:0] counter;
    logic [3:0] cycle;
    logic sched_en;
    logic simple_reset;
    logic global_reset;
    logic sched_policy;
    logic [7:0] sched_prio;

    assign global_reset = simple_reset || reset;

    always_ff @(posedge clk) begin
        cycle <= (cycle == 15) ? 0 : cycle + 1;
        if (experimenting) begin
            if (cycle == 0) begin
                counter <= counter + 1;
                sched_en <= 1;
            end else if (cycle == 1) begin
                sched_en <= 0;
            end
        end else begin
           counter <= 0;
        end
    end
    
    ingress ingress_0 (
        // Input
        .clk(clk), .reset(global_reset),
        .ingress_in_en(meta_in_en[0]), .experimenting(experimenting),
        .ingress_in(meta_in),
        .sched_en(sched_sel_en[0] && experimenting),
        .sched_sel(sched_sel[1:0]),
        .time_stamp(counter),
    
        // Output
        // .ingress_out_en(packet_en[0]),
        .ingress_out(packet[31:0]),
        .is_empty(empty[3:0])
    );

    ingress ingress_1 (
        // Input
        .clk(clk), .reset(global_reset),
        .ingress_in_en(meta_in_en[1]), .experimenting(experimenting),
        .ingress_in(meta_in),
        .sched_en(sched_sel_en[1] && experimenting),
        .sched_sel(sched_sel[3:2]),
        .time_stamp(counter),
    
        // Output
        // .ingress_out_en(packet_en[1]),
        .ingress_out(packet[63:32]),
        .is_empty(empty[7:4])
    );

    ingress ingress_2 (
        // Input
        .clk(clk), .reset(global_reset),
        .experimenting(experimenting),
        .ingress_in_en(meta_in_en[2]),
        .ingress_in(meta_in),
        .sched_en(sched_sel_en[2] && experimenting),
        .sched_sel(sched_sel[5:4]),
        .time_stamp(counter),

    
        // Output
        // .ingress_out_en(packet_en[2]),
        .ingress_out(packet[95:64]),
        .is_empty(empty[11:8])
    );

    ingress ingress_3 (
        // Input
        .clk(clk), .reset(global_reset),
        .ingress_in_en(meta_in_en[3]), .experimenting(experimenting),
        .ingress_in(meta_in),
        .sched_en(sched_sel_en[3] && experimenting),
        .sched_sel(sched_sel[7:6]),
        .time_stamp(counter),
    
        // Output
        // .ingress_out_en(packet_en[3]),
        .ingress_out(packet[127:96]),
        .is_empty(empty[15:12])
    );

    egress egress_0(
        // Input
        .clk(clk), .reset(global_reset),
        .egress_in(packet_out[31:0]),
        .egress_in_en(packet_out_en[0]), .egress_in_ack(meta_out_ack[0]),
        
        // Output
        .egress_out(meta_out[0])
    );
    egress egress_1(
        // Input
        .clk(clk), .reset(global_reset),
        .egress_in(packet_out[63:32]),
        .egress_in_en(packet_out_en[1]), .egress_in_ack(meta_out_ack[1]),
        
        // Output
        .egress_out(meta_out[1])
    );
    egress egress_2 (
        // Input
        .clk(clk), .reset(global_reset),
        .egress_in(packet_out[95:64]),
        .egress_in_en(packet_out_en[2]), .egress_in_ack(meta_out_ack[2]),
        
        // Output
        .egress_out(meta_out[2])
    );
    egress egress_3 (
        // Input
        .clk(clk), .reset(global_reset),
        .egress_in(packet_out[127:96]),
        .egress_in_en(packet_out_en[3]), .egress_in_ack(meta_out_ack[3]),
        
        // Output
        .egress_out(meta_out[3])
    );

    simple_interface simple_interface (
        .clk(clk),

        // Input: sw->interface
        .reset(reset),
        .writedata(writedata),// sw->hw
        .write(write), // sw->hw
        .read(read), // hw->sw
        .address(address),
        .chipselect(chipselect),

        // Input: hw->interface
        .interface_in_0(meta_out[0]),
        .interface_in_1(meta_out[1]),
        .interface_in_2(meta_out[2]),
        .interface_in_3(meta_out[3]),
        
        // Output: interface->sw
        .readdata(readdata),

        // Output: interface->egress (ack)
        .interface_out_ack(meta_out_ack), // 4 bit

        // Output: To ingress/packet_val
        .interface_out_en(meta_in_en), // 4 bit
        .interface_out(meta_in),

        // Output: Ongoing experiment.
        .experimenting(experimenting),
        .simple_reset(simple_reset),

        .sched_policy(sched_policy),
        .sched_prio(sched_prio)

    );

    crossbar crossbar (
        .clk(clk),
        .sched_sel(sched_sel),
        .crossbar_in_en(sched_sel_en),
        .crossbar_in(packet),
        .crossbar_out_en(packet_out_en),
        .crossbar_out(packet_out)
    );

    sched scheduler (
        .clk(clk),
        .sched_en(sched_en),
        .is_busy(0),
        .busy_voq_num(0),
        .voq_empty(empty),
        .policy(sched_policy),
        .prio(sched_prio),

        .sched_sel_en(sched_sel_en), // passed by to ingress, to know which ingress should dequeue
        .sched_sel(sched_sel) // passed by to ingress, to know which voq to dequeue
    );

endmodule
