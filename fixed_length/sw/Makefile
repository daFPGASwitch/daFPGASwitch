ifneq (${KERNELRELEASE},)

# KERNELRELEASE defined: we are being compiled as part of the Kernel
	obj-m := simple_driver.o
else

# Compile the driver as a linux kernel module
KERNEL_SOURCE := /usr/src/linux-headers-$(shell uname -r)
PWD := $(shell pwd)/driver

default: clean module simpleSwitch

module:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} modules


simpleSwitch.o:
	cc -c simpleSwitch.c

simpleSwitch: simpleSwitch.o
	cc -o simpleSwitch simpleSwitch.o

clean:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} clean
	${RM} simpleSwitch simpleSwitch.o
endif