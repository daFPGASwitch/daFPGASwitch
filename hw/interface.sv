module top #() // Params
(
    /* The input comes from the software, output also output to software */
    input logic clk,
    input logic reset,
    input logic [7:0] writedata,
    input logic write,
    input logic [2:0]  address,

    output logic [7:0] readdata,
    // output logic irq
);

   always_ff @(posedge clk)
      if (reset) begin

      end else if (chipselect && write)
        case (address)
          3'd0 : ctrl <= writedata;
          3'd1 : packet_meta <= writedata;
          3'd2 : 
        endcase


    pack_gen 


endmodule;