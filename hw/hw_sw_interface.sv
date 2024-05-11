module hw_sw_interface #() // Params
(
    /* The input comes from the software, output also output to software */
    input logic         clk,
    input logic         reset,
    input logic [31:0]  writedata, 
    input logic         write,
    input logic         read,
    input logic [2:0]   address,
    input logic [31:0]  data_from_egress,
    input logic         chipselect,


    output logic [31:0] readdata,
    output logic 	meta_en,
    output logic [31:0]	meta_in,
    output logic [31:0] ctrl
    // output logic irq
);
   //logic [31:0]         dummy; // 0 -> 
   always_ff @(posedge clk)
      if (reset) begin
	  ctrl <= 32'h0;
	  //packet_meta <= 32'h0;
	  //dummy <= 32'h0;
	  readdata <= 32'h0;
	  meta_en  <= 0;
      end else begin
	if (chipselect && write) begin
      	    case (address)
                 3'h0 : begin 
			ctrl <= writedata;
			meta_en <= 0;
		 end
                 3'h1 : begin
			//packet_meta <= writedata;
			meta_en     <= 1;
			meta_in     <= writedata;
		 end
                 default :  begin 
			//dummy <= writedata;
			meta_en <= 0;
		 end
      	    endcase
        end
	if (chipselect && read) begin
	    case(address)
		3'h1 : readdata <= data_from_egress;
		default: readdata <= 32'h0;		
	    endcase
	end
      end

endmodule;
