class EgressPort:
    """
    The EgressPort class manages the outgoing data flow within a network simulation, interfacing with
    crossbar switches and software controllers. It handles packet buffering, writing to the buffer
    from the crossbar, and reading from the buffer for further processing or transmission.

    Attributes:
        buffer (list): A list that simulates a buffer storing data packets in chunks.
        buffer_size (int): Total size of the buffer measured in the number of 32-byte chunks it can hold.
        head (int): Pointer to the start of valid data in the buffer.
        tail (int): Pointer to the end of valid data in the buffer, indicating where new data should be written.
        empty (bool): Flag to indicate if the buffer is empty.
        read_enable (bool): Control flag to enable reading from the buffer.
        write_enable (bool): Control flag to enable writing to the buffer.
        remaining_packet_out_len (int): Tracks the number of bytes left to be written to the buffer for the current packet.

    Methods:
        buffer_has_space(new_packet_len): Checks if there is enough space left in the buffer for a new packet.
        write_to_buffer(packet): Handles the process of writing packet data into the egress buffer, managing data chunking and buffer wrapping.
    """
    def __init__(self, buffer_size=1024):
        self.buffer = [None] * buffer_size # self.buffer = [32_bytes, 32_bytes, ..., 32_bytes]
        self.buffer_size = buffer_size # Default: holds 1024 32-byte chunks
        self.head = 0
        self.tail = 0
        self.empty = True
        self.read_enable = False # From software -> egress
        self.write_enable = False # From crossbar -> egress
        self.read_data = None

        # Remaining # of bytes to read from packet data (write_data)
        self.remaining_packet_out_len = 0

        ''' Positional indices (in bits) for WRITING (crossbar -> egress) and READING (egress -> software) '''
        self.write_start_position = 0
        self.write_end_position = 0
        self.read_start_position = 0


    def buffer_has_space(self, new_packet_len) -> bool:
        buffer_bytes = (self.tail - self.head + self.buffer_size) % self.buffer_size
        buffer_available = self.buffer_size - buffer_bytes
        return buffer_available >= new_packet_len


    def write_to_buffer(self, packet):
        print(packet)
        if packet is None:
            return
        elif self.write_enable:
            bits_to_read = 8 * 32

            if self.remaining_packet_out_len == 0:
                # Read the packet length from the first 16 bits and setup initial positions
                print(packet[0:16])
                packet_len_as_binary_string = packet[0:16].replace(" ", "")
                packet_len = int(packet_len_as_binary_string, 2)
                self.remaining_packet_out_len = packet_len
                self.write_start_position = 0
                self.write_end_position = bits_to_read
                #print("New packet arrived at egress port (length:", str(packet_len) + ")")

            # Slice the packet to write only the designated chunk to buffer
            packet_chunk = packet[self.write_start_position:self.write_end_position]
            self.buffer[self.tail] = packet_chunk.replace(" ", "")
            self.tail = (self.tail + 1) % self.buffer_size

            # Adjust positions for next write
            self.remaining_packet_out_len -= 32
            # if self.remaining_packet_out_len == 0:
                # print("Finished writing packet to buffer, tail at", self.tail)
            # else:
            self.write_start_position = self.write_end_position
            self.write_end_position += bits_to_read
            #print("Remaining packet length:", self.remaining_packet_out_len)


    def read_from_buffer(self):
        """
        Software reads a single packet from the ring buffer by asserting read_enable.
        The egress port transfers 32 bits out of the ring buffer to the software
        on each cycle.
        """
        num_bits_to_read = 32
        if self.read_enable:
            start = self.read_start_position
            end = start + num_bits_to_read
            if self.remaining_packet_out_len == 0:
                self.remaining_packet_out_len = int(self.buffer[self.head][0:16]) * 8 // 32
            self.read_data = self.buffer[self.head][start : end]
            print("[", start, " : ", end,"]")
            self.read_start_position = end
            self.remaining_packet_out_len -= 4
            if(self.read_start_position == 32*8):
                self.read_start_position = 0
                self.head += 1
                if(self.head == 1024):
                    self.head = 0
        else:
            self.read_data = ""
        return self.read_data


    def tick(self, read_enable, write_data, write_enable):
        print(read_enable, write_data, write_enable)
        if not read_enable and not write_enable:
            #print("This egress port is not currently connected (read_enable=0, write_enable=0)")
            return None, False

        data_out = ""
        software_valid = False

        if (read_enable):
            #print("Current state of buffer (before THIS read occurs):", self.buffer[0:4])
            self.read_enable = read_enable
            data_out = self.read_from_buffer()
            software_valid = True

        if (write_enable):
            #print("Current state of buffer (before THIS write occurs):\n", self.buffer[0:4])
            self.write_enable = write_enable
            self.write_to_buffer(write_data)

        # data_out holds packet data from the ring buffer -> software, and will only be read by the software when software_valid is asserted
        #print("Output values:\tdata_out=" + ("None" if str(data_out) == "" else str(data_out)), "software_valid=" + str(software_valid))
        return data_out, software_valid, self.remaining_packet_out_len, self.buffer
