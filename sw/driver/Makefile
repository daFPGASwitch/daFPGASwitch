ifneq (${KERNELRELEASE},)

# KERNELRELEASE defined: we are being compiled as part of the Kernel
        obj-m := da_driver.o

else

da_driver.o:
	cc -c da_driver.c da_driver.h


endif 
