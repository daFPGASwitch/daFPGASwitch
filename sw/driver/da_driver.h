#ifndef _DA_DRIVER_H
#define _DA_DRIVER_H
#include <linux/ioctl.h>

// High [2 bit src] [2 bit dst] [6 bit length in 32 Byte chunk] [22 bit time stamp] Low
typedef unsigned int packet_meta_t;
typedef unsigned int packet_ctrl_t;

#define DA_DRIVER_MAGIC 'q'

/* ioctls and their arguments */
/* xhttps://www.kernel.org/doc/Documentation/core-api/ioctl.rst */
/* The * in the data-type field? */
#define DA_WRITE_PACKET _IOW(DA_DRIVER_MAGIC, 1, packet_meta_t)

#define DA_WRITE_CTRL _IOW(DA_DRIVER_MAGIC, 2, packet_ctrl_t)

#define DA_READ_PACKET_0 _IOR(DA_DRIVER_MAGIC, 3, packet_meta_t)

#define DA_READ_PACKET_1 _IOR(DA_DRIVER_MAGIC, 4, packet_meta_t)

#define DA_READ_PACKET_2 _IOR(DA_DRIVER_MAGIC, 5, packet_meta_t)

#define DA_READ_PACKET_3 _IOR(DA_DRIVER_MAGIC, 6, packet_meta_t)

#define DA_READ_CTRL _IOR(DA_DRIVER_MAGIC, 7, packet_ctrl_t)

#endif