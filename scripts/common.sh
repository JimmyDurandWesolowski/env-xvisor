#! /usr/bin/env bash


# COMMON TOOLS

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
    printf "  -j JOB_NB, --jobs JOB_NB\t\tManually set the number of " >> ${OUTPUT}
    printf "Makefile parallel jobs to JOB_NB (default " >> ${OUTPUT}
    printf "${PARALLEL_JOBS})\n" >> ${OUTPUT}
    printf "  -s, --single-job\t\t\tAvoid using Makefile " >> ${OUTPUT}
    printf "parallel jobs\n" >> ${OUTPUT}
    printf "  -n\t\t\t\t\tEquivalent to \"--board nitrogen6x\"\n" >> ${OUTPUT}

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
