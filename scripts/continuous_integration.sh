#! /usr/bin/env sh
#
# This file is part of Xvisor Build Environment.
# Copyright (C) 2015-2016 Institut de Recherche Technologique SystemX
# Copyright (C) 2015-2016 OpenWide
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
# @file scripts/continuous_integration.sh
#

set -e
set -u
set -x

err() {
   echo "*** $@" 1>&2
}

if [ $# -ne 2 ]; then
   err "Missing parameters"
   err "Usage: $0 BOARD_NAME XVISOR_REVISION"
   exit 1
fi

BOARDNAME="$1"
REVISION="$2"

cd "$(dirname "$0")/.."
rm -rf build

# default to nitrogen6x (for now)
if [ -z "${BOARDNAME}" ]; then
  ./configure -l
  echo
  BOARDNAME=nitrogen6x
  echo "No target board defined, using ${BOARDNAME}."
fi

#Configure env-xvisor for ${BOARDNAME}
./configure -b "${BOARDNAME}" --xvisor "$REVISION"

#Tests
echo "Running tests..."
case "${BOARDNAME}" in
  ("nitrogen6x"|"sabrelite")
    make V=1
    make V=1 disk
    ;;
  (*)
    make V=1 test
    ;;
esac
