import random
import struct
import pprint

from crossbar import DataCrossbar, ControlCrossbar
from egress_port import EgressPort
from packetgen import PacketGen
from ingress_port import IngressPort
from sched import Scheduler

NUM_CYCLES = 5
packet_gen = PacketGen()
data_crossbar = DataCrossbar()
control_crossbar = ControlCrossbar()
scheduler = Scheduler()


ingress_ports = [IngressPort(idx) for idx in range(4)]
egress_port1 = EgressPort()
egress_port2 = EgressPort()
egress_port3 = EgressPort()
egress_port4 = EgressPort()
egress_ports = [egress_port1, egress_port2, egress_port3, egress_port4]

packets = []
packets_as_bits = []
dest_ports = []
counter = 0

"""
packet_1 = ['00000000100000001001111110100001', '10010011001010100110011101011100', 
              '11010001011011100010000110000011', '11100110111110011110101001110011', 
              '11011101110001101110011011000111', '11101100111111111001110111011011', 
              '00110101000100010010000010111010', '00110001110000001110001101011010']
packet_2 = ['00000000100000001001111110100001', '10010011001010100110011101011100', 
              '11010001011011100010000110000011', '11100110111110011110101001110011', 
              '11011101110001101110011011000111', '11101100111111111001110111011011', 
              '00110101000100010010000010111010', '00110001110000001110001101011010']
packet_3 = ['00000000100000001001111110100001', '10010011001010100110011101011100', 
              '11010001011011100010000110000011', '11100110111110011110101001110001', 
              '11011101110001101110011011000111', '11101100111111111001110111011011', 
              '00110101000100010010000010111010', '00110001110000001110001101011010']
packet_4 = ['00000000100000001001111110100001', '10010011001010100110011101011100', 
              '11010001011011100010000110000011', '11100110111110011110101001110001', 
              '11011101110001101110011011000111', '11101100111111111001110111011011', 
              '00110101000100010010000010111010', '00110001110000001110001101011010']
packet_5 = ['00000000100000001001111110100001', '10010011001010100110011101011100', 
              '11010001011011100010000110000011', '11100110111110011110101001110001', 
              '11011101110001101110011011000111', '11101100111111111001110111011011', 
              '00110101000100010010000010111010', '00110001110000001110001101011010']
packet_6 = ['00000000100000001001111110100001', '10010011001010100110011101011100', 
              '11010001011011100010000110000011', '11100110111110011110101001110111', 
              '11011101110001101110011011000111', '11101100111111111001110111011011', 
              '00110101000100010010000010111010', '00110001110000001110001101011010']
packet_7 = ['00000000100000001001111110100001', '10010011001010100110011101011100', 
              '11010001011011100010000110000011', '11100110111110011110101001110111', 
              '11011101110001101110011011000111', '11101100111111111001110111011011', 
              '00110101000100010010000010111010', '00110001110000001110001101011010']
packet_8 = ['00000000100000001001111110100001', '10010011001010100110011101011100', 
              '11010001011011100010000110000011', '11100110111110011110101001110111', 
              '11011101110001101110011011000111', '11101100111111111001110111011011', 
              '00110101000100010010000010111010', '00110001110000001110001101011010']
packets_arr = [packet_1, packet_2, packet_3, packet_4, packet_5, packet_6, packet_7, packet_8]
"""

packGen = PacketGen()
dest_list = [0, 0, 1, 2, 3, 1, 2, 0, 1, 0]
_, packets_arr = packGen.tick(1, dest_list)

print(packets_arr)

is_empty = [[],[],[],[]]
busy_port_num = [-1, -1, -1, -1]

"""
print("----------------------------------------------------------------------------")
print("Input Packet Generated:")
print("".join(packet_arr))
print("----------------------------------------------------------------------------")
"""

for ingress_idx in range(4):

    for packet_arr in packets_arr:
        print("----------------------------------------------------------------------------")
        print("Input Packet Generated:")
        print("".join(packet_arr))
        print("----------------------------------------------------------------------------")
        counter = 0
        for p in packet_arr:
            if(counter == 0):
                _, _, is_empty[ingress_idx], busy_port_num[ingress_idx] = (ingress_ports[ingress_idx]).tick(p, 1, 1, 0, 0)
                counter += 1
            else:
                _, _, is_empty[ingress_idx], busy_port_num[ingress_idx] = (ingress_ports[ingress_idx]).tick(p, 0, 1, 0, 0)

print("----------------------------------------------------------------------------")
print("Ingress Operations Completed")
print("----------------------------------------------------------------------------")

while(True):
    dequeue_idx, dequeue_en, sched_sel_data_crossbar, sched_sel_ctrl_crossbar = scheduler.tick([[is_empty[0], busy_port_num[0], 1], [is_empty[1], busy_port_num[1], 1], [is_empty[2], busy_port_num[2], 1], [is_empty[3], busy_port_num[3], 1]])
    if (sum(dequeue_idx) == -4):
        exit()
    print("----------------------------------------------------------------------------")
    print("Scheduler Decision:")
    print("Dequeue Index: ", dequeue_idx)
    print("Dequeue Enable: ", dequeue_en)
    print("----------------------------------------------------------------------------")

    write_en = [0, 0, 0, 0]
    r_data = [-1, -1, -1, -1]
    for j in range(4):
        write_en[j], r_data[j], _, _= ingress_ports[j].tick(0, 0, 0, dequeue_idx[j], dequeue_en[j])
        print("r_data", r_data)
        print("write_en", write_en)

    data_eg_0, data_eg_1, data_eg_2, data_eg_3 = data_crossbar.tick(r_data[0], r_data[1], r_data[2], r_data[3], dequeue_idx[0], dequeue_idx[1], dequeue_idx[2], dequeue_idx[3])

    enable_1, enable_2, enable_3, enable_4 = control_crossbar.tick(dequeue_idx[0], dequeue_idx[1], dequeue_idx[2], dequeue_idx[3])
    print("Deq idx", dequeue_idx)
    enables = [enable_1, enable_2, enable_3, enable_4]
    print(enables)
    data_from_crossbars = [data_eg_0, data_eg_1, data_eg_2, data_eg_3]
    print(data_from_crossbars)
    length = 1
    buff = ""
    for j in range(4):
        if enables[j]:
            break

    for eg in range(4):
        if enables[eg] == 1:
            length = 1
            buff = ""
            while(length):
                print(length)
                #print("\n[ Egress 2 ]")
                print("\n[ Egress {} ]".format(eg))

                _, _, length, buff = egress_ports[eg].tick(False, data_from_crossbars[eg], enables[eg])
                # #print("\n[ Egress 3 ]")
                # egress_port3.tick(False, data_3_from_crossbar, enable_3)
                # #print("\n[ Egress 4 ]")
                # egress_port4.tick(False, data_4_from_crossbar, enable_4)

                data = ""
                k = 0
                while(k < len(buff)):
                    if(buff[k] == None):
                        break
                    data = buff[k]
                    k+=1
                    print("--------------------------------------------------------------------")
                    print("Data Written to Output Buffer:")
                    print(data)

                #print(buff, length)
                #print(buff[0])
                    print("--------------------------------------------------------------------")
                    print("Is this data correct output port data?")
                #print(buff[0])
                #print("".join(packets_arr[0][0:8]))

                    if(int(data[110:112],2) == eg):
                        print(True)
                    else:
                        print(eg)
                        print(data[110:112])
                        print(False)
                        exit()
            enables[eg] = 0
        print("---------------------------------------------------------------------")

