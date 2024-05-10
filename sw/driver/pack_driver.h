#ifndef _PACK_DRIVER_H
#define _PACK_DRIVER_H
#include <linux/ioctl.h>

// High [2 bit src] [2 bit dst] [6 bit length in 32 Byte chunk] [22 bit time stamp] Low
typedef uint32_t packet_meta_t;
typedef uint32_t packet_ctrl_t;

#define PACK_DRIVER_MAGIC 'q'

/* ioctls and their arguments */
#define DA_WRITE_PACKET _IOW(PACK_DRIVER_MAGIC, 1, packet_meta_t *)

#define DA_WRITE_CTRL _IOW(PACK_DRIVER_MAGIC, 2, packet_ctrl_t *)

#define DA_READ_PACKET _IOR(PACK_DRIVER_MAGIC, 3, packet_meta_t *)

#define DA_READ_CTRL _IOR(PACK_DRIVER_MAGIC, 4, packet_ctrl_t *)

#endif







#ifndef _VGA_BALL_H
#define _VGA_BALL_H

#include <linux/ioctl.h>

typedef struct {
	unsigned char red, green, blue;
} vga_ball_color_t;
  

typedef struct {
  vga_ball_color_t background;
} vga_ball_arg_t;

#define VGA_BALL_MAGIC 'q'

/* ioctls and their arguments */
#define VGA_BALL_WRITE_BACKGROUND _IOW(VGA_BALL_MAGIC, 1, vga_ball_arg_t *)
#define VGA_BALL_READ_BACKGROUND  _IOR(VGA_BALL_MAGIC, 2, vga_ball_arg_t *)

#endif
