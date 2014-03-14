#! /bin/sh



qemu-system-arm -M vexpress-a9 -m 256M -serial stdio -kernel build/qemu.img
