#! /bin/sh


# This should be written as a Makefile ASAP

export CROSS_COMPILE=arm-none-linux-gnueabi-
KSRC_PATH=~/linux-3.13.6
IMAGE=${KSRC_PATH}/arch/arm/boot/Image
ROOTFS=/home/jimmy/buildroot-2014.02/output/images/rootfs.cramfs
CUSTOM_DIR=./custom

make -C tests/arm32/vexpress-a9/basic
mkdir -p ./build/disk/images/arm32/vexpress-a9

# Bootloader part part
cp -f ./build/tests/arm32/vexpress-a9/basic/firmware.bin.patched ./build/disk/images/arm32/vexpress-a9/firmware.bin

# Kernel part
CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make -j5 -C ${KSRC_PATH} Image
./arch/arm/cpu/arm32/elf2cpatch.py -f ${KSRC_PATH}/vmlinux | ./build/tools/cpatch/cpatch32 ${KSRC_PATH}/vmlinux 0
CROSS_COMPILE=arm-linux-gnueabi- ARCH=arm make -j5 -C ${KSRC_PATH} Image

# Rootfs part
cp -f ${ROOTFS} ./build/disk/images/arm32/rootfs.img


# Mapping and scripting part
cp -f ./tests/arm32/vexpress-a9/linux/nor_flash.list ./build/disk/images/arm32/vexpress-a9/nor_flash.list
IMAGE_SIZE=$(stat -c '%s' ${IMAGE})
IMAGE_SIZE_HEX=$(echo "obase=16; ibase=10; ${IMAGE_SIZE}" | bc)
ROOTFS_SIZE=$(stat -c '%s' ${ROOTFS})
ROOTFS_SIZE_HEX=$(echo "obase=16; ibase=10; ${ROOTFS_SIZE}" | bc)
CMDLIST_SRC=${CUSTOM_DIR}/tests/arm32/vexpress-a9/linux/cmdlist
CMDLIST_DST=./build/disk/images/arm32/vexpress-a9/cmdlist
sed -e "s/KERNEL_SIZE/0x${IMAGE_SIZE_HEX}/" ${CMDLIST_SRC} > ${CMDLIST_DST}
sed -i "s/ROOTFS_SIZE/0x${ROOTFS_SIZE_HEX}/" ${CMDLIST_DST}

cp ${IMAGE} ./build/disk/images/arm32/vexpress-a9/Image
# cp ./build/tests/arm32/vexpress-a9/basic/firmware.bin.patched ./build/disk/images/arm32/vexpress-a9/Image
genext2fs -B 1024 -b 16384 -d ./build/disk ./build/disk.img

./tools/scripts/memimg.py -a 0x60010000 -o build/qemu.img build/vmm.bin@0x60010000 build/disk.img@0x61000000
