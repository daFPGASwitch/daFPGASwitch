class Scheduler:
    def __init__(self, num_ingress_queues=4, num_voqs_per_queue=4):
        self.num_voqs = num_ingress_queues
        self.num_queues_per_voq = num_voqs_per_queue

    def tick(self, sched_info_list):

        # for idx, ingress_queue in enumerate(self.ingress_queues):
        #     print()
        #     print("Ingress port "+ str(idx))
        #     ingress_queue.print_ingress_queue()
        empty_signal = [sched_info[0] for sched_info in sched_info_list]
        output_port_busy_signals = [sched_info[1] for sched_info in sched_info_list]
        sched_info_en_signals = [sched_info[2] for sched_info in sched_info_list]
   
        # print(empty_signal)
        # print(output_port_busy_signals)
        # The idx in selected_voqs is the ingress
        # for example [-1, 0, 3, 2] means that:
        # port 0 send nothing, port 1 send to 0, port 2 send to 3, port 3 send to 2
        selected_voqs = [-1, -1, -1, -1]

        for ingress_queue_index in range(4):
            if not sched_info_en_signals[ingress_queue_index]:
                break
            if output_port_busy_signals[ingress_queue_index] == -1:
                for voq_index in range(4):
                    # Use the empty_signal to check if the VOQ is not empty.
                    # empty_signal is assumed to be a 2D structure, where the first dimension corresponds to the ingress queue index,
                    # and the second dimension corresponds to the VOQ index within that ingress queue.
                    if not empty_signal[ingress_queue_index][voq_index] and (voq_index not in selected_voqs):
                        # If the VOQ is not empty and the corresponding output port is not busy,
                        # select this VOQ for processing.
                        selected_voqs[ingress_queue_index] = voq_index
                        break  # Move to the next ingress queue after finding a non-empty VOQ whose output port is not busy.
            else:
                busy_voq_idx = output_port_busy_signals[ingress_queue_index]
                selected_voqs[ingress_queue_index] = busy_voq_idx

        dequeue_idx = selected_voqs
        dequeue_en = [True if i != -1 else False for i in selected_voqs]
        sched_sel_data_crossbar = dequeue_idx
        sched_sel_ctrl_crossbar = dequeue_idx
        return dequeue_idx, dequeue_en, sched_sel_data_crossbar, sched_sel_ctrl_crossbar
        # return selected_voqs

# sched = Scheduler()
# print(sched.tick([[[0,0,0,0],1,1],[[0,0,0,0],-1,1],[[0,0,-1,0],-1,1],[[0,0,0,0],-1,1]]))
