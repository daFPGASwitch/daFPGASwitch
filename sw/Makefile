ifneq (${KERNELRELEASE},)

# KERNELRELEASE defined: we are being compiled as part of the Kernel
	obj-m := pack_driver.o
else

# Compile the driver as a linux kernel module
KERNEL_SOURCE := /usr/src/linux-headers-$(shell uname -r)
PWD := $(shell pwd)/driver

default: module daFPGASwtich

module:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} modules


daFPGASwitch.o:
	cc -c daFPGASwitch.c

daFPGASwitch: daFPGASwitch.o
	cc -o daFPGASwitch daFPGASwitch.o

clean:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} clean
	${RM} daFPGASwitch daFPGASwitch.o
endif