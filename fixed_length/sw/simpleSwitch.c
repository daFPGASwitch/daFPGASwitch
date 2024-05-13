/*
 * TODO: 
 * [ ] write to CTRL register (CTRL=1)
 *     inputting meta data
 * [ ] start w/ single threaded test prog
 * [ ] send 2 packets (call 2 ioctl w/ write + data flags & other combinations)
 * [ ] try setting different parameters using ioctl (i.e., src, dest, len)
 * [ ] len=1 or 2
 * [ ] ioctl_write (set CTRL=2) for both read & write
 * [ ] ioctl_read should return the 2 packets
 *    (1) inf loop to read packets: can i write at the same time???
 *     OR
 *    (2) ioctl w/ different flags
 *    (3)  
 *     [ ] 
 * [ ] later: create separate thread for polling
 *
 * ioctrl_write w/ write flag (1) and data and actual packet metadata that we assemble here
 * all port 0 (src + dest)
 */

#include <stdio.h>
#include "simpleSwitch.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#define MIN_PORT_NUM 0
#define MAX_PORT_NUM 3
#define DEVICE_PATH "/dev/simple_driver"


int simple_switch_fd;

// High [2 bit src] [2 bit dst] [6 bits for the # of 32 byte chunks] [22 bit time stamp] Low
// typedef unsigned int packet_meta_t;
// typedef unsigned int packet_ctrl_t;
// packet_info_t;

void open_simple_device()
{
    simple_switch_fd = open(DEVICE_PATH, O_RDWR);
    if (simple_switch_fd < 0) {
        perror("Failed to open simple device");
        return;
    }
}

void print_packet_no_hw(void *packet_data)
{
	unsigned int packet = *((unsigned int*) packet_data);
	
    printf("\tmetadata (0x%X): [%u | %u | %u | %u]\n",
		packet,
        (packet >> 30) & 0x3,  // Extract bits 31:30
        (packet >> 28) & 0x3,  // Extract bits 29:28
        (packet >> 22) & 0x3F, // Extract bits 27:22
         packet & 0x3FFFFF     // Extract bits 21:0
    );
}

void print_packet(void *packet_data)
{
	unsigned int packet = *((unsigned int*) packet_data);
    if (ioctl(simple_switch_fd, SIMPLE_READ_PACKET_0, packet_data)) {
        perror("ioctl(SIMPLE_READ_PACKET_0) failed");
        return;
    }

    printf("\tmetadata: [%u | %u | %u | %u]\n",
        (packet >> 30) & 0x3,  // Extract bits 31:30
        (packet >> 28) & 0x3,  // Extract bits 29:28
        (packet >> 22) & 0x3F, // Extract bits 27:22
         packet & 0x3FFFFF     // Extract bits 21:0
    );
}

void set_ctrl_register(const packet_ctrl_t *pkt_ctrl)
{
	if (ioctl(simple_switch_fd, SIMPLE_WRITE_CTRL, pkt_ctrl) < 0) {
        perror("ioctl(SIMPLE_WRITE_CTRL) set CTRL=1 failed\n");
        close(simple_switch_fd);
        return;
    }
}

void send_packet(const packet_meta_t *pkt_meta)
{
    sleep(1);
    if (ioctl(simple_switch_fd, SIMPLE_WRITE_PACKET, pkt_meta) < 0) {
        perror("Failed to send packet");
        return;
    }
}

// void receive_packet(int packet_id, packet_meta_t *pkt_meta)
// {
//     if (ioctl(simple_switch_fd, cmd, pkt_meta) < 0) {
//         perror("Failed to receive packet");
//         return;
//     }
// }

/**
 * Sets the length and time_delta fields of the packet metadata.
 * Assumes that @pkt_meta is cleared prior to calling this function.
 * @param pkt_meta Pointer to the packet metadata.
 * @param length Length of the packet, to be set in bits [27:22].
 */
void set_packet_length(packet_meta_t *pkt_meta, unsigned int length)
{
	if (length > 0x3F) {
		// perror("Failed to set length or time_delta\n");
		return;
	}
    // Mask and shift length @ bit pos [27:22]
    *pkt_meta |= (length & 0x3F) << 22;
    // Mask and set time_delta @ bit pos [21:0]
    // *pkt_meta |= (timestamp & 0x3FFFFF);
}


void set_all_packet_fields(packet_meta_t *pkt_meta, unsigned int dst, 
						   			 unsigned int src, unsigned int length)
{
	packet_meta_t pkt_tmp;
	*pkt_meta = 0;

	set_packet_length(pkt_meta, length);
	*pkt_meta = set_dst_port(*pkt_meta, dst);
	*pkt_meta = set_src_port(*pkt_meta, src);
}


int main()
{
    int write_num_packets = 2, num_sent = 0;
	unsigned int dest = 0, src = 0, len = 1, t_delta = 10;
    packet_meta_t pkt_meta, rcvd_pkt_meta;
    packet_ctrl_t pkt_ctrl;

    open_simple_device();

    // Set control register (CTRL=1)
	printf("Set CTRL register to 1\n");
    pkt_ctrl = 1;
	set_ctrl_register(&pkt_ctrl);
	print_packet_no_hw(&pkt_ctrl);

	set_all_packet_fields(&pkt_meta, 0, 3, 1);
    for (int i = 0; i < write_num_packets; i++) {
		send_packet(&pkt_meta);
		print_packet_no_hw(&pkt_meta);
	}
	num_sent += write_num_packets;

	len = 2;

	set_all_packet_fields(&pkt_meta, 0, 4, 4);
    for (int i = 0; i < 4; i++)
        send_packet(&pkt_meta);
		print_packet_no_hw(&pkt_meta);
	num_sent += write_num_packets;

    // Change control register to reading/writing (CTRL=2)
	printf("Set CTRL register to 2\n");
	pkt_ctrl = 2;
	set_ctrl_register(&pkt_ctrl);
	print_packet_no_hw(&pkt_ctrl);

	printf("Requested %d packets\n", num_sent);
	for (int i = 0; i < 100; i++) {
        sleep(1);
    	if (ioctl(simple_switch_fd, SIMPLE_READ_PACKET_0, &rcvd_pkt_meta) < 0) {
			perror("ioctl read packet failed");
			close(simple_switch_fd);
			return -1;
		}
		print_packet_no_hw(&rcvd_pkt_meta);
	}

    close(simple_switch_fd);
	printf("Userspace program terminating\n");
	return 0;
}
