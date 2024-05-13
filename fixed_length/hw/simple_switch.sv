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
    logic [3:0] sched_en;

    logic [31:0] meta_in, meta_out;
    logic [127:0] packet;
    logic experimenting;
    logic [15:0] empty;
    logic [31:0] counter;
    logic [3:0] cycle;

    always_ff @(posedge clk) begin
        cycle <= (cycle == 15) ? 0 : cycle + 1;
        if (experimenting) begin
            if (cycle == 0) begin
                counter <= counter + 1;
                // call_out scheduler
                sched_sel[1:0] <= 0;
                sched_sel[3:2] <= 1;
                sched_sel[5:4] <= 2;
                sched_sel[7:6] <= 3;
            end
            if (cycle == 1) begin
                sched_en[0] <= 1;
                sched_en[1] <= 1;
                sched_en[2] <= 1;
                sched_en[3] <= 1;
            end
            if (cycle == 2) begin
                sched_en[0] <= 0;
                sched_en[1] <= 0;
                sched_en[2] <= 0;
                sched_en[3] <= 0;
            end
        end
    end
    
    ingress ingress_0 (
        // Input
        .clk(clk), .reset(reset),
        .ingress_in_en(meta_in_en[0]), .experimenting(experimenting),
        .ingress_in(meta_in),
        .sched_en(sched_en[0]),
        .sched_sel(sched_sel[1:0]),
    
        // Output
        .ingress_out_en(packet_en[0]), .ingress_out(packet[32 * sched_sel[1:0] +: 32]),
        .is_empty(empty[3:0])
    );

    ingress ingress_1 (
        // Input
        .clk(clk), .reset(reset),
        .ingress_in_en(meta_in_en[1]), .experimenting(experimenting),
        .ingress_in(meta_in),
        .sched_en(sched_en[1]),
        .sched_sel(sched_sel[3:2]),
    
        // Output
        .ingress_out_en(packet_en[1]), .ingress_out(packet[32 * sched_sel[3:2] +: 32]),
        .is_empty(empty[7:4])
    );

    ingress ingress_2 (
        // Input
        .clk(clk), .reset(reset),
        .experimenting(experimenting),
        .ingress_in_en(meta_in_en[2]),
        .ingress_in(meta_in),
        .sched_en(sched_en[2]),
        .sched_sel(sched_sel[5:4]),

    
        // Output
        .ingress_out_en(packet_en[2]), .ingress_out(packet[32 * sched_sel[5:4] +: 32]),
        .is_empty(empty[11:8])
    );

    ingress ingress_3 (
        // Input
        .clk(clk), .reset(reset),
        .ingress_in_en(meta_in_en[3]), .experimenting(experimenting),
        .ingress_in(meta_in),
        .sched_en(sched_en[3]),
        .sched_sel(sched_sel[7:6]),
    
        // Output
        .ingress_out_en(packet_en[3]), .ingress_out(packet[32 * sched_sel[7:6] +: 32]),
        .is_empty(empty[15:12])
    );

    egress egress_0(
        // Input
        .clk(clk), .reset(reset),
        .egress_in(packet[31:0]),
        .egress_in_en(packet_en[0]), .egress_in_ack(meta_out_ack[0]),
        
        
        // Output
        .egress_out(meta_out)
    );
    egress egress_1(
        // Input
        .clk(clk), .reset(reset),
        .egress_in(packet[63:32]),
        .egress_in_en(packet_en[1]), .egress_in_ack(meta_out_ack[1]),
        
        // Output
        .egress_out(meta_out)
    );
    egress egress_2 (
        // Input
        .clk(clk), .reset(reset),
        .egress_in(packet[95:64]),
        .egress_in_en(packet_en[2]), .egress_in_ack(meta_out_ack[2]),
        
        // Output
        .egress_out(meta_out)
    );
    egress egress_3 (
        // Input
        .clk(clk), .reset(reset),
        .egress_in(packet[127:96]),
        .egress_in_en(packet_en[3]), .egress_in_ack(meta_out_ack[3]),
        
        // Output
        .egress_out(meta_out)
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
        .interface_in(meta_out),
        
        // Output: interface->sw
        .readdata(readdata),

        // Output: interface->egress (ack)
        .interface_out_ack(meta_out_ack), // 4 bit

        // Output: To ingress/packet_val
        .interface_out_en(meta_in_en), // 4 bit
        .interface_out(meta_in),

        // Output: Ongoing experiment.
        .experimenting(experimenting)

    );

endmodule
