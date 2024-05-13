#ifndef _simpleSwitch_H
#define _simpleSwitch_H
#include "driver/simple_driver.h"

packet_meta_t set_src_port(packet_meta_t meta, unsigned int port) {
    if (port > 3) {
        printf("Ports number (%u) should be btw 0 and 3. \n", port);
        return meta;
    }
    meta &= ~(0x3 << 30);
    
    switch(port) {
        case 0:
            break;
        case 1:
            meta |= (0x1 << 30);
            break;
        case 2:
            meta |= (0x2 << 30);
            break;
        case 3:
            meta |= (0x3 << 30);
            break;
        default:
            break;
    }
    return meta;
}

packet_meta_t set_dst_port(packet_meta_t meta, unsigned int port) {
    if (port > 3) {
        printf("Ports number (%u) should be btw 0 and 3. \n", port);
        return meta;
    }
    // Clear the bits 28 and 29
    meta &= ~(0x3 << 28);

    switch(port) {
        case 0: // 00
            break; // No action needed as bits 28 and 29 are already cleared
        case 1: // 01
            meta |= (0x1 << 28); // Set bit 28
            break;
        case 2: // 10
            meta |= (0x2 << 28); // Set bit 29
            break;
        case 3: // 11
            meta |= (0x3 << 28); // Set both bits 28 and 29
            break;
        default:
            break;
    }

    return meta;
}

#endif