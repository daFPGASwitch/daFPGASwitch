from queue import Queue

BUFFER_SIZE = 1024
NUM_VOQS = 4

def get_queue_index(metadata):
    return int(metadata[0:2], 2)

class IngressQueue:
    def __init__(self, idx):
        self.voq = [Queue() for _ in range (NUM_VOQS)]
        self.counter = 0
        self.busy = -1
        self.idx = idx
        self.is_empty = [1,1,1,1]

    def tick(self, voq_metadata, voq_metadata_en, dequeue_idx, dequeue_en):
        
        # voq_metadata_en is just one bit

        #voq_metadata is a 24 bit string 
        """
        On each tick (based on the scheduler's decision), one VOQ from each ingress port
        will dequeue its oldest packet metadata if its selected.
        """
        # Output wires
        free_addr = ""
        free_en = False
        is_empty = self.is_empty
        busy_port_num = self.busy
        is_full = 0
        i = dequeue_idx

        if dequeue_en:
            # Dequeues packet from corresponding VOQ, outputs packet metadata on output `read_data`
            # and the address to fetch the actual packet from on output `write_addr`
            if(busy_port_num != -1):
                self.counter = self.counter - 1
            else:
                # When a new packet arrives, the busy_port_num[i] will be 0 and the counter will be (packet_length - 1)
                #
                packet = self.voq[i].get()
                free_addr = packet[2:12]
                free_en = True
                self.counter = int(packet[12:18])-1
                if(self.counter > 1):
                    busy_port_num = dequeue_idx
                if(is_full > 0):
                    is_full -= 1 
            
            if(self.counter == 0):
                busy_port_num = -1
            
        if voq_metadata_en:
            idx = get_queue_index(voq_metadata)
           
            # When voq_metadata_en is asserted, a single packet (metadata) is written to the corresponding VOQ
            print("From VOQ:", idx, voq_metadata)
            if self.voq[idx].qsize() <= 1024:
                # extra which voq to put into
                self.voq[idx].put(voq_metadata)
                
        for k in range(4):
            if (self.voq[k]).qsize() == 0:
                is_empty[k] = 1
            else:
                is_empty[k] = 0
        self.busy = busy_port_num
        self.is_empty = is_empty
        return free_addr, free_en, is_empty, busy_port_num # empty is a list of 4 bit, busy is 1 bit
