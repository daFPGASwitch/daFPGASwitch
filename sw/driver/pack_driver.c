/* Device driver for the VGA video generator
 *
 * A Platform device implemented using the misc subsystem
 *
 * Adapted from Stephen A. Edwards
 * Adapted by daFPGA
 *
 * "make" to build
 * insmod vga_ball.ko
 *
 * Check code style with
 * checkpatch.pl --file --no-tree vga_ball.c
 */

/*
 * Design register: 
 * 
 */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/errno.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/miscdevice.h>
#include <linux/slab.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include "pack_driver.h"

#define DRIVER_NAME "pack_driver"

/* Device registers */
#define CTRL(x) (x) // Idle 0, sending 1, recv reset 2
#define META_DATA(x) ((x)+1) // Maybe more

/*
 * Information about our device
 */
// struct vga_ball_dev {
// 	struct resource res; /* Resource: our registers */
// 	void __iomem *virtbase; /* Where registers can be accessed in memory */
//     vga_ball_color_t background;
// 	vga_ball_color_t ball_color;
// 	vga_ball_pos_t ball_pos;
// } dev;



// static void write_pack(vga_ball_color_t *background, vga_ball_color_t *ball_color, vga_ball_pos_t *ball_pos)
// {
// 	iowrite8(background->red, BG_RED(dev.virtbase) );
// 	iowrite8(background->green, BG_GREEN(dev.virtbase) );
// 	iowrite8(background->blue, BG_BLUE(dev.virtbase) );
// 	dev.background = *background;

// 	iowrite8(ball_color->red, BALL_RED(dev.virtbase));
// 	iowrite8(ball_color->green, BALL_GREEN(dev.virtbase));
// 	iowrite8(ball_color->blue, BALL_BLUE(dev.virtbase));
// 	dev.ball_color = *ball_color;

// 	// It would be better to put the higher bit first so that we can use the iowrite16
// 	iowrite8((char)(ball_pos->hcenter >> 8), HCENTER_HIGH(dev.virtbase));
// 	iowrite8((char)(ball_pos->hcenter & 0xFF), HCENTER_LOW(dev.virtbase));
// 	iowrite8((char)(ball_pos->vcenter >> 8), VCENTER_HIGH(dev.virtbase));
// 	iowrite8((char)(ball_pos->vcenter & 0xFF), VCENTER_LOW(dev.virtbase));
// 	dev.ball_pos = *ball_pos;
// }