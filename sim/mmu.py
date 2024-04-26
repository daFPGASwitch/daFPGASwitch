from ingress_memory import Memory
from queue_mem import voq
from random import randint

"""
Ingress memory management unit
Has 2 separate memory: data_mem and control_mem
There are 1024 * 8 data mem blocks. Each has 32 bits of info
There are 1024 control blocks. Each is structured as follows
    |    1    |   10   |    10   |  3  |
    |allocated|data_mem|next_ctrl|empty|
0 is used as Null/none. the 0th index is not used for that reason

"""


class MMU:
    def __init__(self):
        # Define memories
        self.control_mem = Memory(1024)
        self.data_mem = Memory(1024 * 8)

        # inputs
        self.write_en = 0
        self.write_data = ""
        self.read_en = 0
        self.free_addr = 0
        self.free_en = 0
        self.new_packet = 0

        # registers
        self.next_write = 1
        self.empty_blocks = 1024
        self.offset = 0
        self.length = 0
        self.new_block = 1
        self.next_read = 0
        self.curr_read = 0
        self.curr_write = 0

    def tick(self, write_en=None, write_data=None,
                   read_en=None, free_addr=None,
                   free_en=None, new_packet=None):

        r_data = ""
        w_addr = 0
        if (write_en == 1):
            self.new_packet = new_packet
            self.write_en = write_en
            w_addr = self.receive_packet(write_data)


        if (read_en == 1):
            self.new_packet = new_packet
            self.read_en = read_en
            self.free_addr = int(free_addr, 2)
            r_data = self.read_packet()

        if (free_en == 1):
            self.read_en = free_en
            self.curr_read = int(free_addr, 2)
            n_data = "i"
            r_data = ""
            while(n_data != ""):
                n_data = self.read_packet()
                r_data += n_data
            self.new_packet = new_packet
            self.free_en = free_en
            self.free_addr = free_addr
            self.free_address()

        return r_data, w_addr

    # Receive new data and write to memory
    def receive_packet(self, packet_32b):
        if (self.write_en == 1):
            if (self.new_packet == 1):
                self.new_block = 1

            if (self.new_block == 1):  # Write to a new data block
                self.new_block = 0
                self.curr_write = self.next_write

                if (self.new_packet == 1):  # Deal with a new packet
                    self.length = int(packet_32b[0:16].lstrip(), 2)
                    if ((self.length // 32) > self.empty_blocks):
                        print("No space!")
                        return 0

                next_addr = self.write_to_control()  # Format and write control
                self.update_next_write(next_addr)

            self.write_data = packet_32b
            self.write_to_data()  # Write to data
            self.length -= 4

            self.offset += 1
            if (self.offset == 8):
                self.offset = 0
                self.empty_blocks -= 1
                self.new_block = 1
                #self.control_mem.print_mem()
                #self.data_mem.print_mem()

            return self.curr_write
        return 0

    def write_to_control(self):
        if (self.length > 32):  # packet takes >1 block
            if (self.next_write == 1):  # Deals with the first write
                next_empty = self.next_write + 1
            else:
                next_write_control = self.read_control(self.next_write)

                if (next_write_control != 0):  # Existing chain
                    next_empty = int(next_write_control[11:21], 2)
                else:  # No chains
                    next_empty = self.next_write + 1

            # Foramt the control block
            control_data = "1" + format(self.next_write, '010b') + format(next_empty, '010b') + "000"

        else:  # Packet takes exactly 1 block
            next_write_control = self.read_control(self.next_write)
            if (next_write_control == 0):
                next_empty = 0
            else:
                next_empty = int(next_write_control[11:21], 2)
            control_data = "1" + format(self.next_write, '010b') + format(next_empty, '010b') + "000"

        self.write_control(self.next_write, control_data)
        #print("From write_to_control:", self.next_write, int(control_data[1:11], 2), int(control_data[11:21], 2))
        return next_empty

    def write_control(self, address, control):
        self.control_mem.tick(address, 1, control, 0)
        self.control_mem.tick(0, 0, "", 0)

    def write_to_data(self):
        # Write data to first free data block
        self.data_mem.tick(((8 * self.curr_write) + self.offset), 1, self.write_data,0)
        self.data_mem.tick(0, 0, "", 0)

    def update_next_write(self, new_addr):
        if (new_addr == 0):
            self.next_write += 1
        else:
            self.next_write = new_addr

    def read_control(self, address):
        control = self.control_mem.tick(address, 0, "", 1)
        self.control_mem.tick(0, 0, "", 0)
        return control

    # Read packets from the data memory given address to control memory
    def read_packet(self):
        # access control block informtion
        if (self.read_en == 1):
            if (self.new_packet == 1):
                self.new_packet = 0
                self.new_block = 1
                self.curr_read = self.free_addr
            if (self.new_block == 1):
                self.new_block = 0

                control = self.read_control(self.curr_read)
                #print(self.curr_read, control)
                if (control == 0):
                    #print("Error: reading unallocated block")
                    return ""

                self.curr_read = int(control[1:11], 2)
                self.next_read = int(control[11:21], 2)

            # Read data from the data memory
            data = self.data_mem.tick(((8 * self.curr_read) + self.offset), 0, "", self.read_en)

            self.offset += 1
            if (self.offset == 8):
                self.new_block = 1
                self.curr_read = self.next_read
                self.offset = 0

            return data
        return 0

    # Write to a random queue
    def write_to_queue(self, address, length):
        egress = randint(0, 5)
        q_data = format(egress, '02b') + format(address, '010b') + format(length // 8, '06b') + "000000"
        self.q1.clock = self.clock
        self.q1.write_en = True
        valid = self.q1.write(q_data)
        self.q1.write_en = False

    # Freeing a particular address will free everything in that chain
    def free_address(self):
        # read control information
        if (self.free_en == 1):
            curr_control = self.read_control(self.free_addr)
            if (curr_control == 0):
                print("Error: Attempt to free unallocated block")
                return 0

            # Change the first bit to 0 to represent a free block
            next_in_chain = int(curr_control[11:21], 2)

            while (next_in_chain != 0):
                curr_control = "0" + curr_control[1:11] + format(self.next_write, '010b') + "000"
                #print(int(curr_control[1:11], 2), int(curr_control[11:21], 2))
                self.next_write = int(curr_control[1:11], 2)
                #print(self.next_write)
                self.write_control(self.next_write, curr_control)

                curr_control = self.read_control(next_in_chain)
                next_in_chain = int(curr_control[11:21], 2)

            curr_control = "0" + curr_control[1:11] + format(self.next_write, '010b') + "000"
            #print("From free:", int(curr_control[1:11], 2), int(curr_control[11:21], 2))
            self.next_write = int(curr_control[1:11], 2)
            #print(self.next_write)
            self.write_control(self.next_write, curr_control)

            return 1

