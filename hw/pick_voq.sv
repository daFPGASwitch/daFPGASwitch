module pick_voq (
  input logic [3:0] voq_empty,
  input logic [1:0] idx, // the idx'th voq has the highest priority to be selected.
  output logic all_empty, // Or put this outside
  output logic [1:0] first_non_empty_num
);
  logic [2:0] check_index;
  logic [2:0] i;
  always_comb
    if (voq_empty == 4'b1111) begin
      all_empty = 1'b1;
    end else begin 
      all_empty = 1'b0;
      for (i = 0; i < 4; i = i + 1) begin
        check_index = idx + i[1:0];
        check_index = (check_index > 3)? (check_index - 4): check_index;
        if (voq_empty[check_index[1:0]] == 1'b0) begin
          first_non_empty_num = check_index[1:0]; // Save the index of the first non-zero bit
          break; // Exit the loop once the first non-zero bit is found
        end
      end
    end
endmodule

