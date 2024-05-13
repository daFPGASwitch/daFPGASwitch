ifneq (${KERNELRELEASE},)

# KERNELRELEASE defined: we are being compiled as part of the Kernel
        obj-m := simple_driver.o

else

simple_driver.o:
	cc -c simple_driver.c simple_driver.h


endif 
