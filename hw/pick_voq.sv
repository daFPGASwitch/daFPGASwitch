module pick_voq (
  input logic [1:0] start_voq_num, // the idx'th voq has the highest priority to be selected.
  input logic [3:0] voq_empty, // Which egress/voq is empty.
  input logic [3:0] voq_picked, // Which egress/voq is picked.
  output logic no_available_voq, // either all empty, or non-empty egress is taken.
  output logic [1:0] voq_to_pick
);
  logic [1:0] check_index;
  logic [2:0] i;
  always_comb
    if (voq_empty == 4'b1111) begin
      no_available_voq = 1'b1;
    end else begin 
      no_available_voq = 1'b1;
      for (i = 0; i < 4; i = i + 1) begin // cannot have for (i = 0; i <= 3; i = i + 1) with logic [1:0] i, this will cause infinite loop!
        check_index = start_voq_num + i[1:0]; // Automatically obtain the 2 lower digits (which is just %4)
        if (voq_empty[check_index] == 1'b0 && voq_picked[check_index] == 1'b0) begin
          voq_to_pick = check_index; // Save the index of the first non-zero bit
          no_available_voq = 1'b0;
          break; // Exit the loop once the first non-empty, non-occupied egress is found
        end
      end
    end
endmodule

