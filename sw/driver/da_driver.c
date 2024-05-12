/* Device driver for the daFPGASwitch packet generator.
 *
 * A Platform device implemented using the misc subsystem
 *
 * Adapted from Stephen A. Edwards
 * Adapted by daFPGA
 *
 * "make" to build
 * insmod da.ko
 *
 * Check code style with
 * checkpatch.pl --file --no-tree da_driver.c
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

#include "da_driver.h"

#define DRIVER_NAME "da_driver"

/* Device registers */
#define CTRL(x) (x) // Idle 0, sending 1, recv reset 2, 
#define META_DATA_0(x) ((x)+4) // Metadata for port 0
#define META_DATA_1(x) ((x)+8) // Metadata for port 1
#define META_DATA_2(x) ((x)+12) // Metadata for port 2
#define META_DATA_3(x) ((x)+16) // Metadata for port 3

/*
 * Information about our device
 */
struct da_driver_dev {
	struct resource res; /* Resource: our registers */
	void __iomem *virtbase; /* Where registers can be accessed in memory */
    /* Some states of our device */
    unsigned long ctrl_state;
    unsigned long packet_data[4];
} dev;

static unsigned int extract_port(packet_meta_t meta)
{
    return meta >> 30;
}

static void write_packet_meta(packet_meta_t *meta)
{
    unsigned int src_port = extract_port(*meta);
    if (src_port > 3) {
        printk(KERN_ERR "Port numbers should be btwn 0 and 3");
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
    iowrite32(*ctrl, CTRL(dev.virtbase));
    dev.ctrl_state = *ctrl;
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
    
    // TODO: Verify this
    // We need to READ OUT Whatever's available from the 4 egress
    case DA_READ_PACKET_0:
        pm = dev.packet_data[0];
		if (copy_to_user((packet_meta_t *) arg, &pm,
                sizeof(packet_meta_t)))
			return -EACCES;
		break;
    case DA_READ_PACKET_1:
        pm = dev.packet_data[1];
		if (copy_to_user((packet_meta_t *) arg, &pm,
                sizeof(packet_meta_t)))
			return -EACCES;
		break;
    case DA_READ_PACKET_2:
        pm = dev.packet_data[2];
		if (copy_to_user((packet_meta_t *) arg, &pm,
                sizeof(packet_meta_t)))
			return -EACCES;
		break;
    case DA_READ_PACKET_3:
        pm = dev.packet_data[3];
		if (copy_to_user((packet_meta_t *) arg, &pm,
                sizeof(packet_meta_t)))
			return -EACCES;
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
static const struct file_operations da_fops = {
	.owner		= THIS_MODULE,
	.unlocked_ioctl = da_ioctl,
};

/* Information about our device for the "misc" framework -- like a char dev */
static struct miscdevice da_misc_device = {
	.minor		= MISC_DYNAMIC_MINOR,
	.name		= DRIVER_NAME,
	.fops		= &da_fops,
};

/*
 * Initialization code: get resources (registers) and display
 * a welcome message
 */
static int __init da_probe(struct platform_device *pdev)
{
    packet_ctrl_t ctrl = 0;

	int ret;

	/* Register ourselves as a misc device: creates /dev/da_driver */
	ret = misc_register(&da_misc_device);

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
    write_packet_ctrl(&ctrl);

	return 0;

out_release_mem_region:
	release_mem_region(dev.res.start, resource_size(&dev.res));
out_deregister:
	misc_deregister(&da_misc_device);
	return ret;
}

/* Clean-up code: release resources */
static int da_remove(struct platform_device *pdev)
{
	iounmap(dev.virtbase);
	release_mem_region(dev.res.start, resource_size(&dev.res));
	misc_deregister(&da_misc_device);
	return 0;
}

/* Which "compatible" string(s) to search for in the Device Tree */
#ifdef CONFIG_OF
static const struct of_device_id da_of_match[] = {
	{ .compatible = "csee4840,da-1.0" },
	{},
};
MODULE_DEVICE_TABLE(of, da_of_match);
#endif

/* Information for registering ourselves as a "platform" driver */
static struct platform_driver da_driver = {
	.driver	= {
		.name	= DRIVER_NAME,
		.owner	= THIS_MODULE,
		.of_match_table = of_match_ptr(da_of_match),
	},
	.remove	= __exit_p(da_remove),
};

/* Called when the module is loaded: set things up */
static int __init da_init(void)
{
	pr_info(DRIVER_NAME ": init\n");
    pr_info(DRIVER_NAME ": Size of packet_meta_t: %zu bytes\n", sizeof(packet_meta_t));
    pr_info(DRIVER_NAME ": Size of packet_ctrl_t: %zu bytes\n", sizeof(packet_ctrl_t));
	return platform_driver_probe(&da_driver, da_probe);
}

/* Called when the module is unloaded: release resources */
static void __exit da_exit(void)
{
	platform_driver_unregister(&da_driver);
	pr_info(DRIVER_NAME ": exit\n");
}

module_init(da_init);
module_exit(da_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Teng Jiang tj2488");
MODULE_DESCRIPTION("daFPGASwitch Packet Driver");

