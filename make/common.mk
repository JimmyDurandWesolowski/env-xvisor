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
# @file make/common.mk
#

ifdef V
  ifneq (V,)
    BUILD_VERBOSE = 1
  endif # V != ''
endif # V

ifndef BUILD_VERBOSE
  BUILD_VERBOSE = 0
endif

ifeq ($(BUILD_VERBOSE),1)
  Q =
else
  Q = @
endif


ifneq (D,)
  BUILD_DEBUG = $(D)
endif

ifndef BUILD_DEBUG
  BUILD_DEBUG = 0
endif

ifneq ($(BUILD_DEBUG),1)
  MAKEFLAGS += --no-print-directory

  # ifneq ($(PARALLEL_JOBS),)
  #   # TODO: Correct this, this should not be set here
  #   MAKEFLAGS += -j$(PARALLEL_JOBS)
  # endif
endif

define COPY
        @echo "(copy) $@"
        $(Q)mkdir -p $(@D)
        $(Q)cp -f $< $@
endef


$(TMPDIR) $(STAMPDIR):
	$(Q)mkdir -p $@

define FILE_SIZE
	printf "0x%X\n" $(shell stat -c "%s" $1)
endef

define DIR_SIZE
	$(shell du -b --max-depth=0 $1 | cut -f 1)
endef
