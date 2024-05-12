ifneq (${KERNELRELEASE},)

# KERNELRELEASE defined: we are being compiled as part of the Kernel
        obj-m := pack_driver.o

else

pack_driver.o:
	cc -c pack_driver.c pack_driver.h


endif 
