module pick_voq (
  input logic [1:0] start_voq_num, // the idx'th voq has the highest prio to be selected.
  input logic [3:0] voq_empty, // Which egress/voq is empty.
  input logic [7:0] prio,
  input logic policy,
  input logic [3:0] voq_picked, // Which egress/voq is picked.
  output logic no_available_voq, // either all empty, or non-empty egress is taken.
  output logic [1:0] voq_to_pick
);
  always_comb begin
    if (voq_empty == 4'b1111) begin
      voq_to_pick = start_voq_num;
      no_available_voq = 1'b1;
    end else if (policy == 0) begin 
      if (voq_empty[start_voq_num] == 1'b0 && voq_picked[start_voq_num] == 1'b0) begin
        voq_to_pick = start_voq_num; // Save the index of the first non-zero bit
        no_available_voq = 1'b0;
      end else if (voq_empty[start_voq_num + 1] == 1'b0 && voq_picked[start_voq_num + 1] == 1'b0) begin
        voq_to_pick = start_voq_num + 1;
        no_available_voq = 1'b0;
      end else if (voq_empty[start_voq_num + 2] == 1'b0 && voq_picked[start_voq_num + 2] == 1'b0) begin
        voq_to_pick = start_voq_num + 2;
        no_available_voq = 1'b0;
      end else if (voq_empty[start_voq_num + 3] == 1'b0 && voq_picked[start_voq_num + 3] == 1'b0) begin
        voq_to_pick = start_voq_num + 3;
        no_available_voq = 1'b0;
      end else begin
        voq_to_pick = start_voq_num;
        no_available_voq = 1'b1;
      end
    end else begin
      if (voq_empty[prio[7:6]] == 1'b0 && voq_picked[prio[7:6]] == 1'b0) begin
        voq_to_pick = prio[7:6]; // Save the index of the first non-zero bit
        no_available_voq = 1'b0;
      end else if (voq_empty[prio[5:4]] == 1'b0 && voq_picked[prio[5:4]] == 1'b0) begin
        voq_to_pick = prio[5:4];
        no_available_voq = 1'b0;
      end else if (voq_empty[prio[3:2]] == 1'b0 && voq_picked[prio[3:2]] == 1'b0) begin
        voq_to_pick = prio[3:2];
        no_available_voq = 1'b0;
      end else if (voq_empty[prio[1:0]] == 1'b0 && voq_picked[prio[1:0]] == 1'b0) begin
        voq_to_pick = prio[1:0];
        no_available_voq = 1'b0;
      end else begin
        voq_to_pick = start_voq_num;
        no_available_voq = 1'b1;
      end
    end
  end

endmodule

