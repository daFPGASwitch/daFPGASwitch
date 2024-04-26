class ControlCrossbar:
    def __init__(self, ingress_ports=4, egress_ports=4):
        self.ingress_ports = ingress_ports
        self.egress_ports = egress_ports


    def tick(self, read_en_1, read_en_2, read_en_3, read_en_4):
        enables = [0, 0,0,0]
        if(read_en_1 != -1):
            enables[read_en_1] = 1
        if(read_en_2 != -1):
            enables[read_en_2] = 1
        if(read_en_3 != -1):
            enables[read_en_3] = 1
        if(read_en_4 != -1):
            enables[read_en_4] = 1
        return enables[0], enables[1], enables[2], enables[3]


class DataCrossbar:
    def __init__(self, ingress_ports=4, egress_ports=4):
        self.ingress_ports = ingress_ports
        self.egress_ports = egress_ports


    def transfer_data(self):
        """
        Transfers data from an ingress port to an egress port in chunks of 32 bytes.

        Args:
            ingress_port (int): The index of the ingress port to transfer data from.
            egress_port (int): The index of the egress port to transfer data to.
            packet: The packet to be transferred.
        """
        packet_size = len(packet)
        chunk_size = 32

        # Check if there is a pending transfer for this ingress-egress pair
        if (ingress_port, egress_port) in self.pending_transfers:
            pending_packet, current_position = self.pending_transfers[(ingress_port, egress_port)]
            packet = pending_packet
            packet_size = len(packet)
        else:
            current_position = 0

        while current_position < packet_size:
            chunk = packet[current_position:current_position+chunk_size]

            # Check if the egress port has enough space in its buffer for the chunk
            if self.egress_ports[egress_port].buffer_has_space(len(chunk)):
                # Write the chunk to the egress port's buffer
                self.egress_ports[egress_port].write_to_buffer(chunk)
                current_position += chunk_size
            else:
                # Store the pending transfer and break the loop
                self.pending_transfers[(ingress_port, egress_port)] = (packet, current_position)
                break

        # Check if the transfer is complete
        if current_position >= packet_size:
            # Remove the pending transfer if it exists
            self.pending_transfers.pop((ingress_port, egress_port), None)


    def tick(self, data_1, data_2, data_3, data_4, c1, c2, c3, c4):
        data_out = ["", "", "", ""]
        if c1 >= 0:  data_out[c1] = data_1
        if c2 >= 0:  data_out[c2] = data_2
        if c3 >= 0:  data_out[c3] = data_3
        if c4 >= 0:  data_out[c4] = data_4
        return data_out[0], data_out[1], data_out[2], data_out[3]
        # returns data_out for each port


    def connect(self, ingress_port, egress_port):
        """
        Connects an ingress port to an egress port based on the scheduling decision.

        Args:
            ingress_port (int): The index of the ingress port to connect.
            egress_port (int): The index of the egress port to connect.
        """
        if ingress_port not in self.connections:
            self.connections[ingress_port] = egress_port
        else:
            pass


    def disconnect(self, ingress_port, egress_port):
        if ingress_port in self.connections:
            if self.connections[ingress_port] == egress_port:
                del self.connections[ingress_port]
            else:
                print("ERROR: connection between ingress", ingress_port, "and egress", egress_port, "does not exist")
                pass