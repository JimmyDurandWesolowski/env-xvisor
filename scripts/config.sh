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

config_check_git() {
   # Determine whether git exists or not
   which git &> /dev/null
   if [ $? -ne 0 ]; then
      echo "*** Git binary is missing in your PATH" 1>&2
   else # $? -eq 0
      # Determine whether it is a git repository or not
      git --git-dir="${CURDIR}/.git" rev-parse HEAD &> /dev/null
      if [ $? -ne 0 ]; then
         # Not a git repository
         echo "Not using git..."
      else # $? -eq 0

         # Determine the remote of the current repository to use it
         # to checkout other repositories later
         remotes="$(git remote)"
         for remote in ${remotes}; do
            # Search for 'origin'. If origin does not exist, the last one
            # will be retained
            if [ "x${remote}" = "xorigin" ]; then
               break
            fi
         done
         # Get the remote (fetch)
         remote_info="$(git remote -v | grep "${remote}" | grep "(fetch)")"
         remote="$(echo "${remote_info}" | sed -e "s/${remote}\s*//" -e 's/\s*(fetch)//')"

         # Base remote, with format: $GIT_PROTOCOL/$BASE_URL
         GIT_BASE_REMOTE="$(dirname "${remote}")"

         # Determine the current branch to checkout one with a similar name
         # later with other repositories
         git_branch="$(git branch --no-color | grep '\*' | sed 's/\*\s*//')"

         # Set the git branch to be experimental the EXPRIMENTAL only
         # if we have pulled the experimental environment
         if [ x"${git_branch}" = x"${GIT_EXPERIMENTAL_BRANCH}" ]; then
            GIT_BRANCH="${GIT_EXPERIMENTAL_BRANCH}"
         fi

      fi # $? -ne 0
   fi # $? -ne 0
}

config_write() {
    print "${BOLD}Components:${NORMAL} ${COMPONENTS}\n"

    mkdir -p $(dirname ${CONF})

    echo "# Configuration generated on $(date)" > ${CONF}
    echo "# by ${USER} on ${HOSTNAME}" >> ${CONF}
    printf "\n\n" >> ${CONF}

    echo "# Environment configuration" >> ${CONF}
    echo "COMPONENTS=\"${COMPONENTS}\"" >> ${CONF}
    for elt in CURDIR MAKEDIR SCRIPTDIR BUILDDIR TARGETDIR HOSTDIR ARCDIR \
	STAMPDIR TMPDIR CONFDIR PATCHDIR ROOTFS_IMG QEMU_IMG BUILD_VERBOSE \
	BUILD_DEBUG PARALLEL_JOBS TESTDIR TFTPDIR; do
	echo "${elt}=${!elt}" >> ${CONF}
    done

    echo ".DEFAULT_GOAL=${DEFAULT_GOAL}" >> ${CONF}
    printf "\n\n" >> ${CONF}

    echo "# Board configuration" >> ${CONF}
    for elt in BOARDNAME ARCH QEMU_ARCH XVISOR_ARCH BOARD_BUSYBOX \
	BOARD_QEMU BOARD_LOADER BOARD_UBOOT TOOLCHAIN_PREFIX BOARD_LINUX BOARD_ANDROID; do
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
	COMPONENT_REPO_ARG=${component}_REPO_ARG
	COMPONENT_BRANCH=${component}_BRANCH
	COMPONENT_SERVER=${component}_SERVER
	COMPONENT_LOCAL=${component}_LOCAL
	COMPONENT_GREPO=${component}_GREPO

	echo "${COMPONENT_VERSION}=${!COMPONENT_VERSION}" >> ${CONF}
	echo "${COMPONENT_PATH}=${!COMPONENT_PATH}" >> ${CONF}
	echo "${COMPONENT_CONF}=${!COMPONENT_CONF}" >> ${CONF}

	if [ -n "${!COMPONENT_LOCAL}" ]; then
	    echo "${COMPONENT_LOCAL}=${!COMPONENT_LOCAL}" >> ${CONF}
	fi

	if [ -n "${!COMPONENT_GREPO}" ]; then
		echo "${COMPONENT_GREPO}=${!COMPONENT_GREPO}" >> ${CONF}
		if [ -n "${COMPONENT_BRANCH}" ]; then
			echo "${COMPONENT_BRANCH}=${!COMPONENT_BRANCH}" >> ${CONF}
		fi

		if [ -n "${COMPONENT_TARGET}" ]; then
			echo "${COMPONENT_TARGET}=${!COMPONENT_TARGET}" >> ${CONF}
		fi
	else
		# If the component is on a git repository, get its path...
		if [ -n "${!COMPONENT_REPO}" ]; then
		    echo "${COMPONENT_REPO}=${!COMPONENT_REPO}" >> ${CONF}
		    echo "${COMPONENT_REPO_ARG}=${!COMPONENT_REPO_ARG}" >> ${CONF}
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
	fi
	echo "${component}_DIR=${BUILDDIR}/${!COMPONENT_PATH}" >> ${CONF}
	printf "${component}_BUILD_DIR=${BUILDDIR}/build_" >> ${CONF}
	printf "${!COMPONENT_PATH}\n" >> ${CONF}

	if [ -n "$(echo LINUX BUSYBOX UBOOT | grep "${component}")" ]; then
	    printf "${component}_BUILD_CONF=${BUILDDIR}/build_" >> ${CONF}
	    printf "${!COMPONENT_PATH}/.config\n" >> ${CONF}
	fi

	if [ XVISOR = "${component}" ]; then
	    printf "XVISOR_BUILD_CONF=${BUILDDIR}/build_" >> ${CONF}
	    printf "${!COMPONENT_PATH}/tmpconf/.config\n" >> ${CONF}
	fi
	echo >> ${CONF}
    done

    for elt in GUEST_BOARDNAME MEMIMG XVISOR_BIN XVISOR_IMX \
	KERN_IMG DISK_DIR DISK_IMG \
	DISK_ARCH DISK_BOARD UBOOT_BOARD_CFG UBOOT_BOARDNAME UBOOT_MKIMAGE \
	XVISOR_ELF2C XVISOR_CPATCH XVISOR_FW_IMG BUSYBOX_XVISOR_DEV DTB \
	DTB_DIR USE_KERN_DT KERN_DT DTB_IN_IMG BOARDNAME_CONF TEST_NAME \
	XVISOR_UIMAGE ROOTFS_LOCAL; do
	[ -n "${!elt}" ] && echo "${elt}=${!elt}" >> ${CONF}
    done
    printf "\n" >> ${CONF}
}
