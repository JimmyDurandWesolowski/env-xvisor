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
# @file make/uboot.mk
#

ifeq ($(BOARD_UBOOT),1)
  $(UBOOT_DIR)/$(UBOOT_BOARD_CFG): UBOOT-prepare

  # At this time, there is no other way to generate the .cfgtmp than building
  # the whole u-boot project...
  $(UBOOT_BUILD_DIR)/$(UBOOT_BOARD_CFG).cfgtmp: \
    $(UBOOT_DIR)/$(UBOOT_BOARD_CFG) | TOOLCHAIN-prepare
	@echo "(defconfig) U-Boot"
	$(Q)$(MAKE) -C $(UBOOT_DIR) O=$(UBOOT_BUILD_DIR) $(UBOOT_BOARDNAME)

  $(UBOOT_BUILD_DIR)/include/config.h: | UBOOT-prepare TOOLCHAIN-prepare
	$(Q)$(MAKE) -C $(UBOOT_DIR) O=$(UBOOT_BUILD_DIR) $(UBOOT_BOARDNAME)

  uboot-configure: $(UBOOT_BUILD_DIR)/include/config.h

  mkimage $(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE): $(UBOOT_BUILD_DIR)/include/config.h
	$(Q)$(MAKE) -C $(UBOOT_DIR) O=$(UBOOT_BUILD_DIR) all tools

  $(UBOOT_BUILD_DIR)/u-boot.imx: $(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE)
endif
