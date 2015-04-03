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
# @file make/kernel.mk
#

BOARDNAME_CONF?=$(shell echo $(GUEST_BOARDNAME) | tr '-' '_')
XVISOR_LINUX_CONF_DIR=$(XVISOR_DIR)/tests/$(XVISOR_ARCH)/$(GUEST_BOARDNAME)/linux
XVISOR_LINUX_CONF_NAME=$(LINUX_PATH)_$(BOARDNAME_CONF)_defconfig
XVISOR_LINUX_CONF=$(XVISOR_LINUX_CONF_DIR)/$(XVISOR_LINUX_CONF_NAME)

$(XVISOR_LINUX_CONF): $(XVISOR_DIR)

$(LINUX_BUILD_DIR):
	$(Q)mkdir -p $@

$(LINUX_BUILD_CONF): $(XVISOR_LINUX_CONF) | $(LINUX_BUILD_DIR) $(LINUX_DIR) TOOLCHAIN-prepare
	@echo "(defconfig) Linux"
	$(Q)cp $< $@
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) oldconfig

$(LINUX_BUILD_DIR)/vmlinux: $(LINUX_BUILD_CONF) | $(LINUX_DIR) $(TOOLCHAIN)
	@echo "(make) Linux"
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) vmlinux

$(DISK_DIR)/$(DISK_BOARD)/$(KERN_IMG): $(LINUX_BUILD_DIR)/vmlinux \
  $(XVISOR_DIR)/$(XVISOR_ELF2C) $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH) \
  | $(DISK_DIR)/$(DISK_BOARD)
	@echo "(patch) Linux"
	$(Q)cp $< $<.bak
	$(Q)$(XVISOR_DIR)/$(XVISOR_ELF2C) -f $< | \
	  $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH) $< 0
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) Image
	$(Q)mv $<.bak $<
	$(Q)mv $(LINUX_BUILD_DIR)/arch/$(ARCH)/boot/Image $@

$(LINUX_BUILD_DIR)/arch/$(ARCH)/boot/zImage: $(LINUX_BUILD_DIR)/vmlinux
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) zImage


$(LINUX_DIR)/arch/$(ARCH)/boot/dts/$(KERN_DT).dts: | $(LINUX_DIR)

$(DISK_DIR)/$(DISK_BOARD)/$(KERN_DT).dtb: $(LINUX_DIR)/arch/$(ARCH)/boot/dts/$(KERN_DT).dts $(XVISOR_BUILD_DIR)/tools/dtc/dtc | $(XVISOR_DIR) $(DISK_DIR)/$(DISK_BOARD)
	@echo "(dtc) $(KERN_DT)"
	$(XVISOR_BUILD_DIR)/tools/dtc/dtc -I dts -O dtb -p 0x800 -o $@ $<

linux-configure: $(LINUX_BUILD_CONF)

linux-oldconfig linux-menuconfig linux-savedefconfig linux-dtbs: | $(LINUX_BUILD_DIR) $(LINUX_DIR) TOOLCHAIN-prepare
	@echo "($(subst linux-,,$@)) Linux"
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) $(subst linux-,,$@)

