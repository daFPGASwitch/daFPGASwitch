module mac_to_port 
(
/* verilator lint_off UNUSED */
    input logic [47:0] MAC,
    output logic [1:0] port_number
);
/* verilator lint_off UNUSED */
    always_comb begin

	port_number = MAC[1:0];
    end

endmodule
