import random
import math
import numpy as np

NUM_EGRESS_PORTS = 4
WORD_LEN = 8
BYTES_PER_CYCLE_MMU = 4
BYTES_PER_CYCLE = 32
PACKET_CHUNK_SIZE = 32

class PacketGen:
    def __init__(self):
        self.incoming_packets = [] # Store raw binary strings of packets
        self.packet_as_32bits = [] # Store packets divided into 32-bit segments

    def single_packet_gen(self, num_packet_chunks=0, dest=-1):
        """
        Generates a packet of random length or num_packet_chunks * 32
        """
        assert 0 <= num_packet_chunks <= 1024, "num_packet_chunks must be >= 0 and <= 1024"

        if num_packet_chunks == 0:
            packet_len = math.floor(random.randint(32, 320) / 32) * PACKET_CHUNK_SIZE
            length = format(packet_len, '016b')
        else:
            packet_len = num_packet_chunks * PACKET_CHUNK_SIZE
            length = format(packet_len, '016b')
            print(length)

        packet = []
        packet_32_bits = []

        source_adr = random.randint(0, 2**48 - 1)
        source = format(source_adr, '048b')

        if dest == -1:
            dest_adr = random.randint(0, 2**48 - 1)
            dest = format(dest_adr, '048b')
        else:
            dest_adr = random.randint(0, 2 ** 46 - 1)
            dest = format(dest_adr, '046b') + format(dest, '02b')

        # Build packet content with source, destination, and data
        packet.append(length)
        packet.append(source)
        packet.append(dest)

        # Append random data to fill the packet
        for i in range(0, (packet_len - 14) * 8, 16):
            data = format(random.randint(0, 2**16-1), '016b')
            packet.append(data)

        # Combine all parts into one binary string and store
        packet = ''.join(packet)
        # self.incoming_packets.append(packet)
        packet_32_bits = [packet[i:i+32] for i in range(0, len(packet), 32)]
        # self.packet_as_32bits.append(packet_32_bits)
        return packet, packet_32_bits


    def print_bytes(self, packet_num):
        # Print packet in 8-bit segments, 4 bytes per line
        if packet_num < len(self.packet_as_32bits):
            packet_segments = self.packet_as_32bits[packet_num]
            for segment in packet_segments:
                formatted_segment = ' '.join(segment[i:i+8] for i in range(0, len(segment), 8))
                #print(formatted_segment)

    def get_packet_len(self, packet_num):
        # Get the length of a packet from its binary data
        if packet_num < len(self.incoming_packets):
            packet_size_bytes = self.incoming_packets[packet_num][:2]
            packet_len = int(packet_size_bytes, 2)
            return packet_len
        raise ValueError("packet_num out of range")


    def get_dest_port(self, packet_num):
        """
        Calculate the destination port as a modulo of NUM_EGRESS_PORTS.
        """
        if packet_num < len(self.incoming_packets):
            dest_port_bits = self.incoming_packets[packet_num][64:112]
            dest_port = int(dest_port_bits, 2)
            return dest_port_bits, (dest_port % NUM_EGRESS_PORTS)
        raise ValueError("packet_num is out of range")


    def get_dest_port_num(self, packet):
        """
        * For use in main driver code (main.py) *

        Calculate the destination port as a modulo of NUM_EGRESS_PORTS + 1 (1-indexing).
        """
        # if packet_num < len(self.incoming_packets):
        dest_port_bits = packet[64:112]
        dest_port = int(dest_port_bits, 2)
        return dest_port_bits, ((dest_port % NUM_EGRESS_PORTS))


    def tick(self, length, dest_list):
        """
        Simulate a tick where 0-4 packets may be generated on each cycle.
        """
        packet_list = []
        packet_32_bits_list = []
        for d in dest_list:
            #if bool(random.getrandbits(1)):
            packet, packet_32_bits = self.single_packet_gen(length, d)
            packet_list.append(packet)
            packet_32_bits_list.append(packet_32_bits)

        return packet_list, packet_32_bits_list

