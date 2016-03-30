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
XVISOR_LINUX_CONF_NAME=$(LINUX_PATH)_defconfig
XVISOR_LINUX_CONF=$(XVISOR_LINUX_CONF_DIR)/$(XVISOR_LINUX_CONF_NAME)

$(XVISOR_LINUX_CONF): XVISOR-prepare

$(LINUX_BUILD_DIR):
	$(Q)mkdir -p $@

$(LINUX_BUILD_CONF): $(XVISOR_LINUX_CONF) | $(LINUX_BUILD_DIR) LINUX-prepare \
  TOOLCHAIN-prepare
	@echo "(defconfig) Linux"
	$(Q)cp $< $@
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) oldconfig

$(LINUX_BUILD_DIR)/vmlinux: $(LINUX_BUILD_CONF) | LINUX-prepare \
  TOOLCHAIN-prepare
	@echo "(make) Linux"
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) vmlinux

$(DISK_DIR)/$(DISK_BOARD)/$(KERN_IMG): $(LINUX_BUILD_DIR)/vmlinux \
  $(XVISOR_DIR)/$(XVISOR_ELF2C) $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH) \
  | $(DISK_DIR)/$(DISK_BOARD)
	@echo "(patch) Linux"
	$(Q)cp $< $<.unpatched
	$(Q)$(XVISOR_DIR)/$(XVISOR_ELF2C) -f $< | \
	  $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH) $< 0
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) Image
	$(Q)cp $(LINUX_BUILD_DIR)/arch/$(ARCH)/boot/Image $@

$(LINUX_BUILD_DIR)/arch/$(ARCH)/boot/zImage: $(LINUX_BUILD_DIR)/vmlinux
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) zImage


$(LINUX_DIR)/arch/$(ARCH)/boot/dts/$(KERN_DT).dts: | LINUX-prepare

dtsflags = $(cppflags) -nostdinc -nostdlib -fno-builtin -D__DTS__
dtsflags += -x assembler-with-cpp -I$(XVISOR_LINUX_CONF_DIR)
dtsflags += -I$(LINUX_DIR)/include -I$(LINUX_DIR)/arch/$(ARCH)/boot/dts


$(TMPDIR)/$(KERN_DT).pre.dts: $(XVISOR_LINUX_CONF_DIR)/$(KERN_DT).dts | \
  XVISOR-prepare $(DISK_DIR)/$(DISK_BOARD)
	$(Q)sed -re 's|/include/|#include|' $< >$@

$(TMPDIR)/$(KERN_DT).dts: $(TMPDIR)/$(KERN_DT).pre.dts
	@echo "(cpp) $(KERN_DT)"
	$(Q)$(CROSS_COMPILE)cpp $(dtsflags) $< -o $@

$(DISK_DIR)/$(DISK_BOARD)/$(KERN_DT).dtb: $(TMPDIR)/$(KERN_DT).dts \
  $(XVISOR_BUILD_DIR)/tools/dtc/dtc
	@echo "(dtc) $(KERN_DT)"
	$(Q)$(XVISOR_BUILD_DIR)/tools/dtc/dtc -I dts -O dtb -p 0x800 -o $@ $<

linux-configure: $(LINUX_BUILD_CONF)

linux-modules: $(LINUX_BUILD_CONF) | LINUX-prepare TOOLCHAIN-prepare
	@echo "(modules) Linux"
	$(Q)$(MAKE) -C $(LINUX_DIR) -j 5 O=$(LINUX_BUILD_DIR) modules

linux-oldconfig linux-menuconfig linux-savedefconfig linux-dtbs: | \
  $(LINUX_BUILD_DIR) LINUX-prepare TOOLCHAIN-prepare
	@echo "($(subst linux-,,$@)) Linux"
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) $(subst linux-,,$@)

linux-clean:
	$(Q)$(RM) $(LINUX_BUILD_DIR)/vmlinux
	$(Q)$(RM) $(LINUX_BUILD_DIR)/vmlinux.o
	$(Q)$(RM) $(LINUX_BUILD_DIR)/vmlinux.unpatched

linux-mrproper: linux-clean
	$(Q)$(RM) -r $(LINUX_BUILD_DIR)
