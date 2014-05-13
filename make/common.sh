#! /bin/sh


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
    printf "Configure the ELA hypervisor build system.\n" > ${OUTPUT}
    printf "If no board is selected, the Versatile Express A9 will be "
    printf "set.\n" > ${OUTPUT}
    printf "\n" > ${OUTPUT}
    printf "Options are:\n" > ${OUTPUT}
    printf "  --board BOARDNAME\t\tBuild the hypervisor and the " > ${OUTPUT}
    printf "required components for the board BOARDNAME\n" > ${OUTPUT}
    printf "  -l, --list\t\t\tList the supported boards\n" > ${OUTPUT}
    printf "  -h, --help\t\t\tDisplay this help\n" > ${OUTPUT}
    printf "  -v, --verbose\t\t\tIncrease the build system " > ${OUTPUT}
    printf "verbosity\n" > ${OUTPUT}
    printf "  -n\t\t\t\tEquivalent to \"--board nitrogen6x\"\n" > ${OUTPUT}

    exit ${RET}
}

option_parse() {
    while [ $# -gt 0 ]; do
	case "$1" in
	    (--board)
		shift
		BOARDNAME=$1
		;;

	    (-n)
		BOARDNAME=nitrogen6x
		;;

	    (-l|--list)
		board_list 0
		break;;

	    (-h|--help)
		usage 0
		break;;

	    (-v|--verbose)
		VERBOSE=1
		;;

	    (*)
		printf "Unrecognized option \"$1\"\n" >/dev/stderr
		usage 1
		break;;
	esac
	shift
    done

    # Check that the board has been
    if [ -z "${BOARDNAME}" ]; then
	usage 1
    fi

    # Check that the board is correct
    case ${BOARDNAME} in
	("vexpress-a9"|"nitrogen6x")
	    break;;
	(*)
	    board_list 1
	    break;;
    esac
}
