#include <stdio.h>
#include "daFPGASwitch.h"
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#define DEVICE_PATH "/dev/daFPGASwitch"
#define MIN_PORT_NUM 0
#define MAX_PORT_NUM 3
#define NUM_PORTS 4
#define NUM_THREADS 10

int da_switch_fd;


void open_da_device()
{
    da_switch_fd = open(DEVICE_PATH, O_RDWR);

    if (da_switch_fd < 0) {
        perror("Failed to open da device");
        return;
    }
}

/*
 * Prints the given metadata @packet in binary (little endian), divided into
 * its 4 components: destination port, source port, length, timestamp.
 */
void print_binary(uint32_t packet)
{
    // Prints bits 31:30
    printf("%u%u | ", (packet >> 31) & 0x1, (packet >> 30) & 0x1);

    // Prints bits 29:28
    printf("%u%u | ", (packet >> 29) & 0x1, (packet >> 28) & 0x1);

    // Prints bits 27:22
    for (int i = 27; i >= 22; i--)
        printf("%u", (packet >> i) & 0x1);

	printf(" | ");

	// Prints bits 21:0 (timestamp)
    for (int i = 21; i >= 0; i--)
        printf("%u", (packet >> i) & 0x1);

	printf("\n");
}


void print_packet_no_hw(void *packet_data)
{
    uint32_t packet = *((uint32_t*) packet_data);
    
	printf("\t[ %-2u | %-2u | %-2u | %-3u ]\t",
        (packet >> 30) & 0x3,  // Extract bits 31:30
        (packet >> 28) & 0x3,  // Extract bits 29:28
        (packet >> 22) & 0x3F, // Extract bits 27:22
         packet & 0x3FFFFF     // Extract bits 21:0
    );
	print_binary(packet);
}


void print_packet(void *packet_data)
{
	uint32_t packet = *((uint32_t*) packet_data);

    printf("\t[%-2u | %-2u | %-2u | %-3u]\t",
        (packet >> 30) & 0x3,  // Extract bits 31:30
        (packet >> 28) & 0x3,  // Extract bits 29:28
        (packet >> 22) & 0x3F, // Extract bits 27:22
         packet & 0x3FFFFF     // Extract bits 21:0
    );
	print_binary(packet);
}


void set_ctrl_register(const packet_ctrl_t *pkt_ctrl)
{
	if (ioctl(da_switch_fd, DA_WRITE_CTRL, pkt_ctrl) < 0) {
        perror("ioctl(DA_WRITE_CTRL) set CTRL=1 failed\n");
        close(da_switch_fd);
        return;
    }
}


void send_packet(const packet_meta_t *pkt_meta)
{
    if (ioctl(da_switch_fd, DA_WRITE_PACKET, pkt_meta) < 0) {
        perror("Failed to send packet");
        return;
    }
}


/**
 * Sets the length field of the packet metadata.
 * Assumes that @pkt_meta is cleared prior to calling this function.
 * @param pkt_meta Pointer to the packet metadata.
 * @param length Length of the packet, to be set in bits [27:22].
 */
void set_packet_length(packet_meta_t *pkt_meta, unsigned int length)
{
	if (length > 0x3F) {
		perror("Failed to set length or time_delta\n");
		return;
	}
    // Mask and shift length @ bit pos [27:22]
    *pkt_meta |= (length & 0x3F) << 22;
}


void set_all_packet_fields(packet_meta_t *pkt_meta, uint32_t dst, 
						   uint32_t src, uint32_t length)
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
	uint32_t len = 1;
    packet_meta_t pkt_meta, rcvd_pkt_meta;
    packet_ctrl_t pkt_ctrl;

    open_da_device();

	printf("Set control state: 1\n");
    pkt_ctrl = 1;
	set_ctrl_register(&pkt_ctrl);

	set_all_packet_fields(&pkt_meta, 0, 0, len);
    for (int i = 0; i < write_num_packets; i++) {
		send_packet(&pkt_meta);
		print_packet(&pkt_meta);
	}
	num_sent += write_num_packets;

	len = 2;
	set_all_packet_fields(&pkt_meta, 0, 0, len);
	print_packet(&pkt_meta);
    for (int i = 0; i < write_num_packets; i++)
        send_packet(&pkt_meta);
	num_sent += write_num_packets;

	printf("Set control state: 2\n");
	pkt_ctrl = 2;
	set_ctrl_register(&pkt_ctrl);

	printf("Requested %d packets\n", num_sent);
	while (1) {
    	if (ioctl(da_switch_fd, DA_READ_PACKET_0, &rcvd_pkt_meta) < 0) {
			perror("ioctl read packet failed");
			close(da_switch_fd);
			return -1;
		}
		print_packet(&rcvd_pkt_meta);
	}

    close(da_switch_fd);
	printf("Da userspace program terminating\n");
	return 0;
}
