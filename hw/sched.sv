module sched(input logic  [3:0] a,
	       output logic [6:0] y);
   always_comb
      case (a)
         4'h0: y = 7'b100_0000;
         4'h1: y = 7'b111_1001;
         4'h2: y = 7'b010_0100;
         4'h3: y = 7'b011_0000;
         4'h4: y = 7'b001_1001;
         4'h5: y = 7'b001_0010;
         4'h6: y = 7'b000_0010;
         4'h7: y = 7'b111_1000;
         4'h8: y = 7'b000_0000;
         4'h9: y = 7'b001_0000;
         4'hA: y = 7'b000_1000;
         4'hB: y = 7'b000_0011;
         4'hC: y = 7'b100_0110;
         4'hD: y = 7'b010_0001;
         4'hE: y = 7'b000_0110;
         4'hF: y = 7'b000_1110;
         default: y = 7'b111_1111;
      endcase
endmodule
