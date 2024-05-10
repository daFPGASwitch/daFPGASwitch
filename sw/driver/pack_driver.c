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
#include <linux/types.h>
#include "pack_driver.h"

#define DRIVER_NAME "pack_driver"

/* Device registers */
#define CTRL_0(x) (x) // Idle 0, sending 1, recv reset 2
#define META_DATA_0(x) ((x)+4) // Metadata
#define CTRL_1(x) ((x)+8) // Idle 0, sending 1, recv reset 2
#define META_DATA_1(x) ((x)+12) // Metadata
#define CTRL_2(x) ((x)+16) // Idle 0, sending 1, recv reset 2
#define META_DATA_2(x) ((x)+20) // Metadata
#define CTRL_3(x) ((x)+24) // Idle 0, sending 1, recv reset 2
#define META_DATA_3(x) ((x)+28) // Metadata

/*
 * Information about our device
 */
struct pack_driver_dev {
	struct resource res; /* Resource: our registers */
	void __iomem *virtbase; /* Where registers can be accessed in memory */
    /* Some states of our device */
    unsigned long ctrl_state[4];
    unsigned long packet_data[4];
} dev;

static unsigned int extra_port(unsigned int meta) {
    
}

static void write_packet_meta(pack_meta_t *meta, unsigned int src_port)
{
    if (src_port > 3) {
        printk(KERN_ERR "Ports number should be btw 0 and 3");
    }
    switch (src_port) {
        case 0: 
            iowrite32(*meta, META_DATA_0(dev.virtbase));
            dev.packet_data[0] = *meta;
            break;
        case 1:
            iowrite32(*meta, META_DATA_1(dev.virtbase));
            dev.packet_data[1] = *meta;
            break;
        case 2:
            iowrite32(*meta, META_DATA_2(dev.virtbase));
            dev.packet_data[2] = *meta;
            break;
        case 3:
            iowrite32(*meta, META_DATA_3(dev.virtbase));
            dev.packet_data[3] = *meta;
            break;
        default:
            break;
    }
}

static void write_packet_ctrl(packet_ctrl_t *ctrl)
{
    if (port > 3) {
        printk(KERN_ERR "Ports number should be btw 0 and 3");
    }
    switch (src_port) {
        case 0: 
            iowrite32(*ctrl, CTRL_0(dev.virtbase));
            dev.ctrl_state[0] = *ctrl;
            break;
        case 1:
            iowrite32(*ctrl, CTRL_1(dev.virtbase));
            dev.ctrl_state[1] = *ctrl;
            break;
        case 2:
            iowrite32(*ctrl, CTRL_2(dev.virtbase));
            dev.ctrl_state[2] = *ctrl;
            break;
        case 3:
            iowrite32(*ctrl, CTRL_3(dev.virtbase));
            dev.ctrl_state[3] = *ctrl;
            break;
        default:
            break;
    }
}

/*
 * Handle ioctl() calls from userspace:
 * Read or write the segments on single digits.
 * Note extensive error checking of arguments
 */
static long da_ioctl(struct file *f, unsigned int cmd, unsigned long arg)
{
	packet_meta_t pm;
    packet_ctrl_t pc;

	switch (cmd) {
	case DA_WRITE_PACKET:
		if (copy_from_user(&pm, (packet_meta_t *) arg,
				   sizeof(packet_meta_t)))
			return -EACCES;
		write_packet_meta(&pm);
		break;
    case DA_WRITE_CTRL:
		if (copy_from_user(&pc, (packet_ctrl_t *) arg,
				   sizeof(packet_ctrl_t)))
			return -EACCES;
		write_packet_ctrl(&pc);
		break;
    case DA_READ_PACKET:
        pm = dev.packet_data;
		if (copy_to_user((packet_meta_t *) arg, &pm,
				 sizeof(packet_meta_t)))
			return -EACCES;
		write_background(&pm);
		break;

	case DA_READ_CTRL:
	  	pc = dev.ctrl_state;
		if (copy_to_user((packet_ctrl_t *) arg, &pc,
				 sizeof(packet_ctrl_t)))
			return -EACCES;
		break;

	default:
		return -EINVAL;
	}
	return 0;
}

/* The operations our device knows how to do */
static const struct file_operations vga_ball_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = vga_ball_ioctl,
};

/* Information about our device for the "misc" framework -- like a char dev */
static struct miscdevice vga_ball_misc_device = {
	.minor		= MISC_DYNAMIC_MINOR,
	.name		= DRIVER_NAME,
	.fops		= &vga_ball_fops,
};

/*
 * Initialization code: get resources (registers) and display
 * a welcome message
 */
static int __init vga_ball_probe(struct platform_device *pdev)
{
        vga_ball_color_t beige = { 0xf9, 0xe4, 0xb7 };
	int ret;

	/* Register ourselves as a misc device: creates /dev/vga_ball */
	ret = misc_register(&vga_ball_misc_device);

	/* Get the address of our registers from the device tree */
	ret = of_address_to_resource(pdev->dev.of_node, 0, &dev.res);
	if (ret) {
		ret = -ENOENT;
		goto out_deregister;
	}

	/* Make sure we can use these registers */
	if (request_mem_region(dev.res.start, resource_size(&dev.res),
			       DRIVER_NAME) == NULL) {
		ret = -EBUSY;
		goto out_deregister;
	}

	/* Arrange access to our registers */
	dev.virtbase = of_iomap(pdev->dev.of_node, 0);
	if (dev.virtbase == NULL) {
		ret = -ENOMEM;
		goto out_release_mem_region;
	}
        
	/* Set an initial color */
        write_background(&beige);

	return 0;

out_release_mem_region:
	release_mem_region(dev.res.start, resource_size(&dev.res));
out_deregister:
	misc_deregister(&vga_ball_misc_device);
	return ret;
}

/* Clean-up code: release resources */
static int vga_ball_remove(struct platform_device *pdev)
{
	iounmap(dev.virtbase);
	release_mem_region(dev.res.start, resource_size(&dev.res));
	misc_deregister(&vga_ball_misc_device);
	return 0;
}

/* Which "compatible" string(s) to search for in the Device Tree */
#ifdef CONFIG_OF
static const struct of_device_id vga_ball_of_match[] = {
	{ .compatible = "csee4840,vga_ball-1.0" },
	{},
};
MODULE_DEVICE_TABLE(of, vga_ball_of_match);
#endif

/* Information for registering ourselves as a "platform" driver */
static struct platform_driver vga_ball_driver = {
	.driver	= {
		.name	= DRIVER_NAME,
		.owner	= THIS_MODULE,
		.of_match_table = of_match_ptr(vga_ball_of_match),
	},
	.remove	= __exit_p(vga_ball_remove),
};

/* Called when the module is loaded: set things up */
static int __init vga_ball_init(void)
{
	pr_info(DRIVER_NAME ": init\n");
	return platform_driver_probe(&vga_ball_driver, vga_ball_probe);
}

/* Calball when the module is unloaded: release resources */
static void __exit vga_ball_exit(void)
{
	platform_driver_unregister(&vga_ball_driver);
	pr_info(DRIVER_NAME ": exit\n");
}

module_init(pack_driver_init);
module_exit(pack_driver_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Teng Jiang tj2488");
MODULE_DESCRIPTION("daFPGASwitch Packet Driver");

