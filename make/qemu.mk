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
# @file make/qemu.mk
#

ifeq ($(BOARD_QEMU),1)
define QEMU
	qemu-system-$(ARCH) -M $(BOARDNAME) -m 256M $1 \
	  -kernel $(BUILDDIR)/$(QEMU_IMG) -dtb $(BUILDDIR)/$(BOARDNAME).dtb
endef

QEMU_DISPLAY?=-display none
QEMU_MONITOR?=-monitor telnet:127.0.0.1:1234,server,nowait
QEMU_EXTRA?=

qemu-run: $(BUILDDIR)/$(QEMU_IMG) $(BUILDDIR)/$(BOARDNAME).dtb
	@echo "$@ for $(BOARDNAME)"
	$(call QEMU,$(QEMU_DISPLAY) -serial stdio $(QEMU_MONITOR) $(QEMU_EXTRA),$<)

$(BUILDDIR)/$(QEMU_IMG): $(XVISOR_DIR)/$(MEMIMG) $(XVISOR_BIN) $(DISK_IMG)
	@echo "(memimg) $(QEMU_IMG)"
	$(Q)$< -a $(ADDR_HYPER) -o $@ $(XVISOR_BIN)@$(ADDR_HYPER) \
		$(DISK_IMG)@$(ADDR_DISK)

ifeq ($(USE_KERN_DT),1)
  QEMU_KERN_DTB = -dtb $(DISKB_KERN_DTB)
endif

qemu-guest-run: $(LINUX_BUILD_DIR)/arch/$(ARCH)/boot/zImage $(DISKB_KERN_DTB) $(BUILDDIR)/$(ROOTFS_IMG)
	qemu-system-$(ARCH) -M $(BOARDNAME) -m 256M $1 \
	  -kernel $(LINUX_BUILD_DIR)/arch/$(ARCH)/boot/zImage \
	  $(QEMU_KERN_DTB) \
	  -initrd $(BUILDDIR)/$(ROOTFS_IMG) \
	  -append "root=/dev/ram rw earlyprintk console=ttyAMA0" \
	  -serial stdio \
	  $(QEMU_DISPLAY) \
	  $(QEMU_MONITOR) \
	  $(QEMU_EXTRA)
endif
