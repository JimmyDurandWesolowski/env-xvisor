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
# @file scripts/options.sh
#



# Terminal escape sequences
NORMAL="\033[0m"
BOLD="\033[1m"

print() {
    if [ ${VERBOSE} -eq 0 ]; then
	return
    fi

    printf "Debug: $*"
}

usage() {
    RET=$1

    if [ -z "${RET}" ]; then
	RET=1
    fi

    if [ ${RET} -eq 1 ]; then
	OUTPUT=/dev/stderr
    else
	OUTPUT=/dev/stdout
    fi

    printf "Usage: ${PROGNAME} [OPTION]\n" > ${OUTPUT}
    printf "Configure the ELA hypervisor build system.\n" >> ${OUTPUT}
    printf "\n" >> ${OUTPUT}
    printf "Options are:\n" >> ${OUTPUT}
    printf "  -b BOARDNAME,--board BOARDNAME\tBuild the " >> ${OUTPUT}
    printf "hypervisor and the required components for the " >> ${OUTPUT}
    printf "board BOARDNAME\n" >> ${OUTPUT}
    printf "  -l, --list\t\t\t\tList the supported boards\n" >> ${OUTPUT}
    printf "  -h, --help\t\t\t\tDisplay this help\n" >> ${OUTPUT}
    printf "  -v, --verbose\t\t\t\tIncrease the build system " >> ${OUTPUT}
    printf "verbosity (implies -s)\n" >> ${OUTPUT}
    printf "  -d, --debug\t\t\t\tBuild system debugging\n" >> ${OUTPUT}
    printf "  -V\t\t\t\t\tIncrease the configuration verbosity\n" >> ${OUTPUT}
    printf "  -j JOB_NB, --jobs JOB_NB\t\tManually set the number of " >> \
	   ${OUTPUT}
    printf "Makefile parallel jobs to JOB_NB (default " >> ${OUTPUT}
    printf "${PARALLEL_JOBS})\n" >> ${OUTPUT}
    printf "  -s, --single-job\t\t\tAvoid using Makefile " >> ${OUTPUT}
    printf "parallel jobs\n" >> ${OUTPUT}
    printf "  -n\t\t\t\t\tEquivalent to \"--board nitrogen6x\"\n" >> ${OUTPUT}
    printf "  -m\t\t\t\t\tEquivalent to \"--board nitrogen6_max\"\n" >> \
	   ${OUTPUT}

    exit ${RET}
}

pre_option_check() {
    # Parallel job number
    CPU_INFO=/proc/cpuinfo
    if [ -n "${PARALLEL_JOBS}" ]; then
	return
    fi

    if [ ! -f ${CPU_INFO} ]; then
	return
    fi


    PROC_MAX_ID=$(grep processor ${CPU_INFO} | tail -n1 | cut -f2 -d':')
    PROC_NB=$(( PROC_MAX_ID + 1 ))
    PARALLEL_JOBS=$(( PROC_NB + 1))
}

option_test_arg() {
    if [ $# -le 1 ]; then
	echo "Missing argument to \"$1\""
	# Usage will exit
	usage 1
    fi
}

option_parse() {
    while [ $# -gt 0 ]; do
	case "$1" in
	    (-b|--board)
		option_test_arg $*
		shift
		BOARDNAME=$1
		;;

	    (-l|--list)
		board_list 0
		break;;

	    (-h|--help)
		usage 0
		break;;

	    (-v|--verbose)
		BUILD_VERBOSE=1
		DISABLE_PARALLEL=1
		;;

	    (-d|--debug)
		BUILD_DEBUG=1
		;;

	    (-V)
		VERBOSE=1
		;;

	    (-s|--single-job)
		DISABLE_PARALLEL=1
		;;

	    (-j|--jobs)
		option_test_arg $*
		shift
		PARALLEL_JOBS=$1
		;;

	    (-n)
		BOARDNAME=nitrogen6x
		;;

	    (-m)
		BOARDNAME=nitrogen6_max
		;;

	    (*)
		printf "Unrecognized option \"$1\"\n" >/dev/stderr
		# Usage will exit
		usage 1
		break;;
	esac
	shift
    done

    if [ -n "${DISABLE_PARALLEL}" ]; then
	if [ ${DISABLE_PARALLEL} -eq 1 ]; then
	    PARALLEL_JOBS=
	fi
    fi
}

option_board_validate() {
    # Check that the board has been
    if [ -z "${BOARDNAME}" ]; then
	usage 1
    fi

    # Check that the board is correct
    case ${BOARDNAME} in
	("nitrogen6x"|"nitrogen6_max")
	    DTB_BOARDNAME=sabrelite-a9
	    GUEST_BOARDNAME=sabrelite-a9
	    XVISOR_CFG_BOARDNAME=nitrogen6x
	    ;;
	("bcm2835-raspi")
	    DTB_BOARDNAME=bcm2835-raspi
	    GUEST_BOARDNAME=realview-eb-mpcore
	    XVISOR_CFG_BOARDNAME=${BOARDNAME}
	    ;;
	("vexpress-a9"|"sabrelite"|"realview-pb-a8"|"realview-eb-mpcore")
	    DTB_BOARDNAME=${BOARDNAME}
	    GUEST_BOARDNAME=${BOARDNAME}
	    XVISOR_CFG_BOARDNAME=${BOARDNAME}
	    ;;
	(*)
	    board_list 1
	    ;;
    esac
}

option_board() {
    BOARD_CONF="${CONFDIR}/${BOARDNAME}.conf"
    print "Sourcing \"${BOARD_CONF}\"\n"
    source ${BOARD_CONF}
    source ${CONFDIR}/${ARCH}.conf
    source ${CONFDIR}/components.conf

    for elt in BUSYBOX UBOOT LOADER OPENOCD LIBFTDI; do
	BOARD_ELT=BOARD_${elt}
	if [ -z "${!BOARD_ELT}" ]; then
	    continue
	fi

	if [ ${!BOARD_ELT} -eq 1 ]; then
	    COMPONENTS="${COMPONENTS} ${elt}"
	fi
    done

    if [ ${BOARD_LOADER} -eq 1 -o ${BOARD_OPENOCD} -eq 1 ]; then
	printf "If you use Kermit, you can find a configuration file example "
	printf "\"${CONFDIR}/kermrc\".\n"
    fi
}

