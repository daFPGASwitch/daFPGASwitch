from mmu import MMU
from voq import IngressQueue

class IngressPort:
    def __init__(self, idx):
        self.voq = IngressQueue(idx)
        self.mmu = MMU()
        self.idx = idx
        self.counter = 0
        self.length = format(0, '06b')
        self.MAC_address = ""
        self.output_port = 0
        self.w_addr = 0
        
    
    def tick(self, packet, new_packet_enable, write_packet_enable, dequeue_idx, dequeue_en):
        # free_addr, free_en, is_empty, busy_port_num = self.voq.tick(0, 0, dequeue_idx, dequeue_en)
        is_empty = []
        busy_port_num = -1
        free_en = False
        r_data = ""
        if(new_packet_enable):
            self.counter = 1
            # print(packet)
            r_data, w_addr = self.mmu.tick(1, packet, 0, 0, 0, new_packet_enable)
            #print("----------------------------------------------------------------------------")
            #print("32-bits packet received by MMU:")
            #print(r_data)
            #print("----------------------------------------------------------------------------")
            self.w_addr = w_addr
            self.length = format(int(packet[0:16], 2) // 32, '06b')
            #print(self.length)
        else:
            if(self.counter < 5):
                self.counter += 1
                r_data, w_addr = self.mmu.tick(1, packet, 0, 0, 0, new_packet_enable)
                
                #print("----------------------------------------------------------------------------")
                #print("32-bits packet received by MMU:")
                #print(r_data)
                #print("----------------------------------------------------------------------------")
                if(self.counter == 3):
                    self.MAC_address = packet
                elif(self.counter == 4):
                    self.MAC_address += packet[0:16]
                    self.output_port = int(self.MAC_address[-2:], 2)
                    print("From ingress: ", self.output_port, self.MAC_address)
                    output_port = format(self.output_port, '02b')
                    voq_packet = output_port + format(self.w_addr, '010b') + self.length + format(0,'06b')
                    _, _, is_empty, busy_port_num = self.voq.tick(voq_packet, write_packet_enable, dequeue_idx, dequeue_en)
                    print("----------------------------------------------------------------------------")
                    #print("Metadata added to Ingress Queue")
                    print("Queue Status:")
                    print(is_empty)
                    print("----------------------------------------------------------------------------")
                    
            else:  
                r_data, w_addr = self.mmu.tick(write_packet_enable, packet, 0, 0, 0, new_packet_enable)
                #print("----------------------------------------------------------------------------")
                #print("32-bits packet received by MMU:")
                #print(r_data)
                #print("----------------------------------------------------------------------------")
                free_addr, free_en, is_empty, busy_port_num = self.voq.tick(0, 0, dequeue_idx, dequeue_en)
                #print("----------------------------------------------------------------------------")
                #print("Dequeue Signal Received by Input Queue")
                #print("Packet Dequeued, the memory address: ", free_addr)
                #print("----------------------------------------------------------------------------")
                r_data, _ = self.mmu.tick(0, 0, 0, free_addr, free_en, new_packet_enable)
                #print("----------------------------------------------------------------------------")
                #print("Packet Read From Memory and removed from memory")
                #print("----------------------------------------------------------------------------")
        return free_en, r_data, is_empty, busy_port_num
