#! /bin/sh

qemu-system-arm -M vexpress-a9 -m 256M -serial stdio -kernel ../linux-3.13.6/arch/arm/boot/zImage -append "root=/dev/ram rw earlyprintk rdinit=/bin/sh" -initrd /home/jimmy/initramfs/rootfs.cramfs
