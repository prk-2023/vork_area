# Makefile for building the simple_cb_driver kernel module

obj-m += simple_cb_driver.o

KDIR := /lib/modules/$(shell uname -r)/build
PWD  := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

load:
	sudo insmod simple_cb_driver.ko

unload:
	sudo rmmod simple_cb_driver

reload: unload load

log:
	dmesg | tail -20
