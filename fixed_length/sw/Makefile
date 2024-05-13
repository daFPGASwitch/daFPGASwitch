ifneq (${KERNELRELEASE},)

# KERNELRELEASE defined: we are being compiled as part of the Kernel
	obj-m := simple_driver.o
else

# Compile the driver as a linux kernel module
KERNEL_SOURCE := /usr/src/linux-headers-$(shell uname -r)
PWD := $(shell pwd)/driver

default: clean module simpleSwitch even_load skewed_load even_load_prio skewed_load_prio

module:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} modules


simpleSwitch.o:
	cc -c simpleSwitch.c

simpleSwitch: simpleSwitch.o
	cc -o simpleSwitch simpleSwitch.o

even_load.o:
	cc -c even_load.c

even_load: even_load.o
	cc -o even_load even_load.o

skewed_load.o:
	cc -c skewed_load.c

skewed_load: skewed_load.o
	cc -o skewed_load skewed_load.o

even_load_prio.o:
	cc -c even_load_prio.c

even_load_prio: even_load_prio.o
	cc -o even_load_prio even_load_prio.o

skewed_load_prio.o:
	cc -c skewed_load_prio.c

skewed_load_prio: skewed_load_prio.o
	cc -o skewed_load_prio skewed_load_prio.o

clean:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} clean
	${RM} simpleSwitch simpleSwitch.o
endif