import numpy as np

class Memory:
    # configures memory based on a given length
    def __init__(self, length):
        self.address = 0
        self.write_en = 0
        self.read_en = 0
        self.write_data = ""

        self.mem = np.zeros(length, dtype=object)

    def tick(self, address, write_en, write_data, read_en):
        r_data = ""
        if (write_en == 1):
            self.address = int(address)
            self.write_en = write_en
            self.write_data = write_data
            self.write()

        if (read_en == 1):
            self.read_en = read_en
            self.address = int(address)
            r_data = self.read()

        return r_data

    def write(self):
        if (self.write_en):
            self.mem[self.address] = self.write_data

    def read(self):
        if (self.read_en):
            return (self.mem[self.address])

    def print_mem(self):
        print(self.mem)
        print("\n")


