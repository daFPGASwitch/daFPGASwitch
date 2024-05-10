module port_to_mac 
(

    input logic [1:0] port_number,
    output logic [47:0] MAC
);
    always_comb begin
	MAC = {46'b0, port_number};
    end

endmodule
