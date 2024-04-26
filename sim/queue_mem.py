import numpy as np

class voq:
    def __init__(self, clock):
        self.read_address = 0
        self.write_en = False
        self.read_en = False
        self.write_data = ""
        self.clock = clock
        self.mem = []
    
    def write(self, write_data):
        if (self.clock and self.write_en):
            self.mem.append(write_data)
            return 1
    
    def read(self, address):
        if (self.clock and self.read_en):
            return (self.mem[self.address])


