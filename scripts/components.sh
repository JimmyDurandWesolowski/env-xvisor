#! /bin/sh

FILE_SERVER="http://freki"

COMPONENTS="TOOLCHAIN XVISOR LINUX ${BOARD_COMPONENTS}"

XVISOR_VERSION=0.2.4
XVISOR_PATH=xvisor-${XVISOR_VERSION}
XVISOR_REPO="git@git.irt-systemx.fr:ela/xvisor"
XVISOR_BRANCH=nitrogen-port

# The toolchain is board dependent, and thus, its associated variables are
# in the board configuration file

LINUX_VERSION=3.7.4
LINUX_PATH=linux-${LINUX_VERSION}
LINUX_FILE=linux-${LINUX_VERSION}.tar.xz

BUSYBOX_VERSION=1.22.1
BUSYBOX_PATH=busybox-${BUSYBOX_VERSION}
BUSYBOX_FILE=busybox-${BUSYBOX_VERSION}.tar.bz2
