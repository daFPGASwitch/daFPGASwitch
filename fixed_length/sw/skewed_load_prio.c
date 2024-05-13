#include <stdio.h>
#include "simpleSwitch.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#define DEVICE_PATH "/dev/simple_driver"
int simple_switch_fd;

// High [2 bit src] [2 bit dst] [6 bits for the # of 32 byte chunks] [11 bit start time] [11 bit end time] Low
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

void print_packet(void *packet_data)
{
	unsigned int packet = *((unsigned int*) packet_data);
	
    printf("\tmetadata: [%u | %u | %u | %u | %u ]\n",
        (packet >> 30) & 0x3,  // Extract bits 31:30
        (packet >> 28) & 0x3,  // Extract bits 29:28
        (packet >> 22) & 0x3F, // Extract bits 27:22
        (packet >> 11) & 0x7FF, // Extract bits 21:11
         packet & 0x7FF     // Extract bits 10:0
    );
}

int extra_time_delta(unsigned int packet)
{
    return (packet & 0x7FF) - ((packet >> 11) & 0x7FF);
}

int extra_dst_port(unsigned int packet)
{
    return (packet >> 28) & 0x3;
}

void set_ctrl_register(const packet_ctrl_t *pkt_ctrl)
{
	if (ioctl(simple_switch_fd, SIMPLE_WRITE_CTRL, pkt_ctrl) < 0) {
        perror("ioctl(SIMPLE_WRITE_CTRL) set CTRL failed\n");
        close(simple_switch_fd);
        return;
    }
}

void send_packet(const packet_meta_t *pkt_meta)
{
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
		perror("Failed to set length\n");
		return;
	}
    // Mask and shift length @ bit pos [27:22]
    *pkt_meta |= (length & 0x3F) << 22;
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
    int num_sent = 0;
    int num_get = 0;
    packet_meta_t pkt_meta, rcvd_pkt_meta;
    packet_ctrl_t pkt_ctrl;
    int total_latency = 0;

    open_simple_device();

	printf("Start: \n");
    pkt_ctrl = 0;
	set_ctrl_register(&pkt_ctrl);
	print_packet(&pkt_ctrl);

    // Set control register (CTRL=1)
	printf("Start sending\n");
    pkt_ctrl = 1;
	set_ctrl_register(&pkt_ctrl);
	print_packet(&pkt_ctrl);

    for (int i = 0; i < 12; i++) {
        set_all_packet_fields(&pkt_meta, (i+1)%2, i%4, 1);
		send_packet(&pkt_meta);
		print_packet(&pkt_meta);
	}
	num_sent += 10;

    for (int i = 0; i < 12; i++)
        set_all_packet_fields(&pkt_meta, (i+3)%4, (i+1)%4, 1);
        send_packet(&pkt_meta);
		print_packet(&pkt_meta);
	num_sent += 10;

	printf("Start recving\n");
	pkt_ctrl = 2;
	set_ctrl_register(&pkt_ctrl);
	print_packet(&pkt_ctrl);

	printf("Requested %d packets\n", num_sent);
	for (int i = 0; i < 50; i++) {
    	if (ioctl(simple_switch_fd, SIMPLE_READ_PACKET_0, &rcvd_pkt_meta) < 0) {
			perror("ioctl read packet failed");
			close(simple_switch_fd);
			return -1;
		}
        if (rcvd_pkt_meta >> 22) {
            printf("Port 0: \n");
            print_packet(&rcvd_pkt_meta);
            total_latency += extra_time_delta(rcvd_pkt_meta);
            num_get++;
        }
        if (ioctl(simple_switch_fd, SIMPLE_READ_PACKET_1, &rcvd_pkt_meta) < 0) {
			perror("ioctl read packet failed");
			close(simple_switch_fd);
			return -1;
		}
        if (rcvd_pkt_meta >> 22) {
            printf("Port 1: \n");
            print_packet(&rcvd_pkt_meta);
            total_latency += extra_time_delta(rcvd_pkt_meta);
            num_get++;
        }
        if (ioctl(simple_switch_fd, SIMPLE_READ_PACKET_2, &rcvd_pkt_meta) < 0) {
			perror("ioctl read packet failed");
			close(simple_switch_fd);
			return -1;
		}
        if (rcvd_pkt_meta >> 22) {
            printf("Port 2: \n");
            print_packet(&rcvd_pkt_meta);
            total_latency += extra_time_delta(rcvd_pkt_meta);
            num_get++;
        }
        if (ioctl(simple_switch_fd, SIMPLE_READ_PACKET_3, &rcvd_pkt_meta) < 0) {
			perror("ioctl read packet failed");
			close(simple_switch_fd);
			return -1;
		}
        if (rcvd_pkt_meta >> 22) {
            printf("Port 3: \n");
            print_packet(&rcvd_pkt_meta);
            total_latency += extra_time_delta(rcvd_pkt_meta);
            num_get++;
        }
	}
    printf("Got %d packets\n", num_get);
    printf("Total latency: %d\n", total_latency);

    close(simple_switch_fd);
	printf("Userspace program terminating\n");
	return 0;
}
