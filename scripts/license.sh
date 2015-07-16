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
# @file license.sh
#

PROJECT="Xvisor Build Environment"
COMPANY=( "Institut de Recherche Technologique SystemX" "OpenWide" )
LICENSE_HEADER=$(dirname $0)/license_header.txt
COLUMN_MAX=79
testing=${TEST:-0}
filename=
dir=
base=
tmp_name=
output=/dev/stdout

function arg_check() {
    if [ -z "$1" ]; then
	echo "Missing argument: A file argument is required" >>/dev/stderr
	exit 1
    fi

    if [ "${filename}" = "${LICENSE_HEADER}" -o \
		       "${filename}" = "LICENSE.txt" ]; then
	echo "Skipping ${filename}" >>/dev/stderr
	exit 0
    fi

    filename=$1
    dir=$(dirname ${filename})
    base=$(basename ${filename})
    tmp_name="${dir}/.tmp_${base}"

    if [ ${testing} -ne 1 ]; then
	output=${tmp_name}
    fi
}

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


function header_do_write() {
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

function header_write() {
        output=$1

	header_do_write >> ${output}
}

function content_write() {
    content=$1
    shebang=$2
    output=$3

    if [ -n "${shebang}" ]; then
	lines=$(cat ${content} | wc -l)
	lines=$(( lines - 1 ))
	tail -n ${lines} ${content} >> ${output}
    else
	cat "${content}" >> ${output}
    fi
}

function file_prepare() {
    filename=$1
    output=$2

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
	echo ${shebang} > ${output}
    else
	echo -n > ${output}
    fi
}

arg_check $*
file_prepare "${filename}" ${output}
header_write ${output}
content_write "${filename}" "${shebang}" ${output}
if [ ${testing} -eq 1 ]; then
    exit 0
fi

mv "${tmp_name}" "${filename}"
check_exit "Failed to move file"
rm -f "${tmp_name}"
