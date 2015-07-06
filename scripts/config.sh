#! /usr/bin/env bash
#
# This file is part of Xvisor Build Environment.
# Copyright (C) 2015 Institut de Recherche Technologique SystemX
# Copyright (C) 2015 OpenWide
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this Xvisor Build Environment. If not, see
# <http://www.gnu.org/licenses/>.
#
# @file scripts/config.sh
#



config_write() {
    print "${BOLD}Components:${NORMAL} ${COMPONENTS}\n"

    mkdir -p $(dirname ${CONF})

    echo "# Configuration generated on $(date)" > ${CONF}
    echo "# by ${USER} on ${HOSTNAME}" >> ${CONF}
    printf "\n\n" >> ${CONF}

    echo "# Environment configuration" >> ${CONF}
    echo "COMPONENTS=\"${COMPONENTS}\"" >> ${CONF}
    for elt in CURDIR MAKEDIR SCRIPTDIR BUILDDIR TARGETDIR HOSTDIR ARCDIR \
	STAMPDIR TMPDIR CONFDIR ROOTFS_IMG QEMU_IMG BUILD_VERBOSE BUILD_DEBUG \
	PARALLEL_JOBS TESTDIR TFTPDIR; do
	echo "${elt}=${!elt}" >> ${CONF}
    done

    echo ".DEFAULT_GOAL=${DEFAULT_GOAL}" >> ${CONF}
    printf "\n\n" >> ${CONF}

    echo "# Board configuration" >> ${CONF}
    for elt in BOARDNAME ARCH QEMU_ARCH XVISOR_ARCH BOARD_BUSYBOX \
	BOARD_QEMU BOARD_LOADER BOARD_UBOOT TOOLCHAIN_PREFIX; do
	echo "${elt}=${!elt}" >> ${CONF}
    done
    printf "\n\n" >> ${CONF}

    echo "# Memory mapping" >> ${CONF}
    echo "# Physical memory mapping" >> ${CONF}
    for elt in RAM_BASE ADDR_HYPER ADDR_DISK; do
	echo "${elt}=${!elt}" >> ${CONF}
    done
    echo >> ${CONF}
    echo "# Hypervised memory mapping" >> ${CONF}
    for elt in ADDRH_KERN ADDRH_KERN_DT ADDRH_RFS ADDRH_FLASH_FW ADDRH_FLASH_CMD\
	ADDRH_FLASH_KERN ADDRH_FLASH_KERN_DT ADDRH_FLASH_RFS; do
	echo "${elt}=${!elt}" >> ${CONF}
    done

    printf "\n\n# Components\n" >> ${CONF}
    for component in ${COMPONENTS}; do
	COMPONENT_VERSION=${component}_VERSION
	COMPONENT_PATH=${component}_PATH
	COMPONENT_CONF=${component}_CONF
	COMPONENT_FILE=${component}_FILE
	COMPONENT_REPO=${component}_REPO
	COMPONENT_BRANCH=${component}_BRANCH
	COMPONENT_SERVER=${component}_SERVER
	COMPONENT_LOCAL=${component}_LOCAL

	echo "${COMPONENT_VERSION}=${!COMPONENT_VERSION}" >> ${CONF}
	echo "${COMPONENT_PATH}=${!COMPONENT_PATH}" >> ${CONF}
	echo "${COMPONENT_CONF}=${!COMPONENT_CONF}" >> ${CONF}

	if [ -n "${!COMPONENT_LOCAL}" ]; then
	    echo "${COMPONENT_LOCAL}=${!COMPONENT_LOCAL}" >> ${CONF}
	fi

	# If the component is on a git repository, get its path...
	if [ -n "${!COMPONENT_REPO}" ]; then
	    echo "${COMPONENT_REPO}=${!COMPONENT_REPO}" >> ${CONF}
	    # ... and its branch
	    if [ -n "${!COMPONENT_BRANCH}" ]; then
		echo "${COMPONENT_BRANCH}=${!COMPONENT_BRANCH}" >> ${CONF}
	    else
		echo "${COMPONENT_BRANCH}=master" >> ${CONF}
	    fi
	# Otherwise, it is provided with a archive server and file
	else
	    echo "${COMPONENT_SERVER}=${!COMPONENT_SERVER}" >> ${CONF}
	    echo "${COMPONENT_FILE}=${!COMPONENT_FILE}" >> ${CONF}
	fi
	echo "${component}_DIR=${BUILDDIR}/${!COMPONENT_PATH}" >> ${CONF}
	printf "${component}_BUILD_DIR=${BUILDDIR}/build_" >> ${CONF}
	printf "${!COMPONENT_PATH}\n" >> ${CONF}
	printf "${component}_BUILD_CONF=${BUILDDIR}/build_" >> ${CONF}
	printf "${!COMPONENT_PATH}/.config\n" >> ${CONF}
	echo >> ${CONF}
    done

    for elt in DTB_BOARDNAME GUEST_BOARDNAME MEMIMG XVISOR_BIN XVISOR_IMX \
	KERN_IMG DISK_DIR DISK_IMG \
	DISK_ARCH DISK_BOARD UBOOT_BOARD_CFG UBOOT_BOARDNAME UBOOT_MKIMAGE \
	XVISOR_ELF2C XVISOR_CPATCH XVISOR_FW_IMG BUSYBOX_XVISOR_DEV DTB \
	DTB_DIR USE_KERN_DT KERN_DT DTB_IN_IMG BOARDNAME_CONF TEST_NAME \
	XVISOR_UIMAGE ROOTFS_LOCAL; do
	[ -n "${!elt}" ] && echo "${elt}=${!elt}" >> ${CONF}
    done
    printf "\n" >> ${CONF}
}
