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
# @file scripts/package.sh
#



package_install() {
    PKG_DEBIAN=$1
    PKG_GENTOO=$2
    ENV_GENTOO=$3

    INSTALL_DEBIAN="${INSTALL_DEBIAN} ${PKG_DEBIAN}"
    INSTALL_GENTOO="${INSTALL_GENTOO} ${PKG_GENTOO}"
    if [ -n "${ENV_GENTOO}" ]; then
	INSTALL_GENTOO_ENV=" ${ENV_GENTOO}"
    fi
}

# Check if a binary exists, and add it to the install list otherwise
# $1: Test if the binary is necessary (set to 1 to force)
# $2: The binary to test
# $3: The Debian package name
# $4: The Gentoo package name
# $5: The optional Gentoo environment to install the package
package_check_binary() {
    TEST=$1
    BIN=$2
    PKG_DEBIAN=$3
    PKG_GENTOO=$4
    ENV_GENTOO=$5

    if [ ${TEST} -ne 1 ]; then
	return 1
    fi

    which ${BIN} &>/dev/null
    if [ $? -ne 0 ]; then
	package_install $3 $4 $5
	return 1
    fi
    return 0
}

# Check if a binary exists, in the specified version with the format X.Y.Z,
# and add it to the install list otherwise
# $1: Test if the binary is necessary (set to 1 to force)
# $2: The binary to test
# $3: The minimum expected version
# $4: The Debian package name
# $5: The Gentoo package name
# $6: The optional Gentoo environment to install the package
package_check_binary_version() {
    package_check_binary $1 $2 $4 $5 $6

    if [ $? -eq 1 ]; then
	# The package must be installed, version checking is not necessary
	return 1
    fi

    REGEX='s/.*([0-9]+)\.([0-9]+)\.([0-9]+).*/\1 \2 \3/p'
    VERSION=($($2 --version | sed -rne "${REGEX}"))

    if [ -z "${VERSION}" ]; then
	echo "Failed to check required version for \"$2\""
	exit 1
    fi

    REQ_VERS=($(echo $3 | sed -rne "${REGEX}"))
    if [ -z "${REQ_VERS}" ]; then
	echo "Failed to parse the required version for \"$2\""
	echo "It must be in the X.Y.Z format (X, Y and Z being numbers)"
	exit 1
    fi

    for idx in $(seq 0 2); do
	if [ ${VERSION[$idx]} -gt ${REQ_VERS[$idx]} ]; then
	    return 0
	elif [ ${VERSION[$idx]} -lt ${REQ_VERS[$idx]} ]; then
	    echo "\"$2\" minimum version is $3, please update it"
	    package_install $4 $5 $6
	    return 1
	fi
    done
}

# Check that the Debian/Ubuntu package is installed
# Fills the INSTALL_DEBIAN string
# $1: Name of the package
package_debian_installed() {
    PKG=$1

    dpkg -s ${PKG} &>/dev/null
    if [ $? -ne 0 ]; then
	INSTALL_DEBIAN="${INSTALL_DEBIAN} ${PKG}"
    fi
}

# Check that the required packages, depending on the target, are installed
packages_check() {
    INSTALL_DEBIAN=""
    INSTALL_GENTOO=""
    INSTALL_GENTOO_ENV=""
    NCURSE_TMP="${TMPDIR}/ncurse_tmp"
    ISSUE_FILE=/etc/issue

    if [ -f "${ISSUE_FILE}" ]; then
    	DISTRO=$(head -n1 "${ISSUE_FILE}" | sed -nre 's/([a-zA-Z]+).*/\1/p')
        [ -z "${DISTRO}" ] && DISTRO=Gentoo
    else
        echo "Unknown GNU/Linux distribution"
        exit 1
    fi

    # Check that realpath, used for these scripts is available
    package_check_binary 1 realpath realpath "realpath" "app-misc/realpath"

    # Checking that Qemu is installed
    package_check_binary_version ${BOARD_QEMU} qemu-system-${QEMU_ARCH} \
	"1.6.1" "qemu-system" "\">=app-emulation/qemu-1.6.1\"" \
	"QEMU_SOFTMMU_TARGETS=${QEMU_ARCH} USE=fdt"

    # Checking that expect is installed
    package_check_binary ${BOARD_QEMU} expect "expect" "dev-tcltk/expect"

    # Checking that fakeroot, used by Busybox, is installed
    package_check_binary ${BOARD_BUSYBOX} fakeroot "fakeroot" \
	"sys-apps/fakeroot"

    # Checking that libtool, used by autotools, is installed
    package_check_binary ${BOARD_OPENOCD} libtool "libtool-bin" "sys-devel/libtool"

    # Checking that telnet, useful with openocd
    package_check_binary ${BOARD_OPENOCD} telnet "telnet" \
	"net-misc/netkit-telnetd"

    # Check the tool required to create the rootfs image
    TOOL=
    ROOTFS_IMG_SUFFIX=$(echo ${ROOTFS_IMG} | sed -re 's|.*\.(.+)|\1|')
    case ${ROOTFS_IMG_SUFFIX} in
	(ext2)
	    TOOL=genext2fs
	    DEBIAN_PKG=genext2fs
	    GENTOO_PKG=sys-fs/genext2fs
	    ;;
	(*)
	    printf "Unknown suffix \"${ROOTFS_IMG_SUFFIX}\" in the rootfs image "
	    echo "name \"${ROOTFS_IMG}\", exiting..."
	    exit 1
    esac
    package_check_binary 1 "${TOOL}" "${DEBIAN_PKG}" "${GENTOO_PKG}"

    # Check we can compile (not needed on Gentoo, of course)
    package_check_binary 1 "gcc" "build-essential" ""

    # Checking that Ncurses is installed
    mkdir -p $(dirname ${NCURSE_TMP})
    cat > ${NCURSE_TMP}.c <<-EOF
	#include <curses.h>

	int main()
	{
	  return 0;
	}
	EOF
    gcc -lncurses ${NCURSE_TMP}.c -o ${NCURSE_TMP} &>/dev/null
    if [ $? -ne 0 ]; then
	INSTALL_DEBIAN="${INSTALL_DEBIAN} libncurses5-dev"
	INSTALL_GENTOO="${INSTALL_GENTOO} \">=sys-libs/ncurses-5\""
    fi
    rm -f ${NCURSE_TMP} ${NCURSE_TMP}.c

    # Check we have pkg-config (not needed on Gentoo)
    package_check_binary 1 "pkg-config" "pkg-config" ""

    if ! pkg-config --exists libusb-1.0; then
	INSTALL_DEBIAN="${INSTALL_DEBIAN} libusb-1.0-0-dev"
	INSTALL_GENTOO="${INSTALL_GENTOO} \"dev-libs/libusb\""
    fi

    case "${DISTRO}" in
    Gentoo)
        if [ -n "${INSTALL_GENTOO}" ]; then
            printf "${BOLD}Please install the following packages before "
            printf "continuing:${NORMAL}\n"
            printf "  sudo ${INSTALL_GENTOO_ENV} emerge -av --quiet-build "
	    printf "${INSTALL_GENTOO}\n"
	    exit 1
        fi
        ;;
    Ubuntu|Debian)
        #if [ "x86_64" = "$(uname -m)" ]; then
        #    package_debian_installed gcc-multilib
	#    package_debian_installed binutils-multiarch
	#fi
        if [ -n "${INSTALL_DEBIAN}" ]; then
            printf "${BOLD}Please install the following packages before "
            printf "continuing:${NORMAL}\n"
            printf "  sudo apt-get install ${INSTALL_DEBIAN}\n"
	    exit 1
        fi
        ;;
    *)
        echo "Unknown GNU/Linux distribution"
        exit 1
	;;
    esac
}
