PROJECT="Xvisor Build Environment"
COMPANY=( "Institut de Recherche Technologique SystemX" "OpenWide" )
LICENSE_HEADER=$(dirname $0)/license_header.txt
COLUMN_MAX=79


function check_exit() {
    if [ $? -ne 0 ]; then
	echo $1
	exit 1
    fi
}


function header_write_top() {
    comment=$1

    printf "${comment[0]}\n"
}


function header_write_line() {
    comment=$1
    line=$2

    if [ -z "${line}" ]; then
	printf "${comment[1]}\n"
    else
	printf "${comment[1]} ${line}\n"
    fi
}


function header_write_end() {
    comment=$1

    printf "${comment[2]}\n"
}


function header_write() {
    header_write_top "${comment}"
    header_write_line "${comment}" "This file is part of ${PROJECT}."
    for i in $(seq 0 $(( ${#COMPANY[*]} - 1))); do
	header_write_line "${comment}" "Copyright (C) $(date +%G) ${COMPANY[$i]}"
    done
    header_write_line "${comment}" "All rights reserved."
    header_write_line "${comment}" ""
    while read headerl; do
	header_write_line "${comment}" "${headerl}"
    done < ${LICENSE_HEADER}
    header_write_line "${comment}" ""
    header_write_line "${comment}" "@file ${filename}"
    header_write_end "${comment}"
    echo

    return 0
}

function content_write() {
    content=$1
    shebang=$2

    if [ -n "${shebang}" ]; then
	lines=$(cat ${content} | wc -l)
	lines=$(( lines - 1 ))
	tail -n ${lines} ${content}
    else
	cat "${content}"
    fi
}

function file_prepare() {
    filename=$1
    fline=$(head -1 ${filename})
    start=${fline:0:2}
    extension="${filename##*.}"

    # Test for shebang
    if [ "${start}" = "#!" ]; then
	echo "${filename}: Shebang detected" >>/dev/stderr
	shebang=${fline}
    fi

    case ${extension} in
	"c" | "h")
	    comment=( "/*" " *" " */" )
	    ;;
	"sh" | "cfg" | "conf" | *)
	    comment=( '#' '#' '#' )
	    ;;
    esac

    if [ -n "$(head -n5 "${filename}" | grep "${PROJECT}")" ]; then
	echo "${filename}: Already done" >>/dev/stderr
	exit 0
    fi

    if [ -n "${shebang}" ]; then
	echo ${shebang}
    fi
}

testing=${TEST:-0}
filename=$1
dir=$(dirname ${filename})
base=$(basename ${filename})
tmp_name="${dir}/.tmp_${base}"

if [ -z "$1" ]; then
    echo "Missing argument: A file argument is required" >>/dev/stderr
    exit 1
fi

if [ "${filename}" = "${LICENSE_HEADER}" -o \
    "${filename}" = "LICENSE.txt" ]; then
    echo "Skipping ${filename}" >>/dev/stderr
    exit 0
fi

if [ ${testing} -eq 1 ]; then
    output=/dev/stdout
else
    output=${tmp_name}
fi

file_prepare "${filename}" >${output}
header_write "${filename}" >>${output}
content_write "${filename}" "${shebang}" >>${output}
if [ ${testing} -eq 1 ]; then
    exit 0
fi

mv "${tmp_name}" "${filename}"
check_exit "Failed to move file"
rm -f "${tmp_name}"
