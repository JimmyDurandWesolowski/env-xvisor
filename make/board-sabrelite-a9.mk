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
# @file make/board.mk
#


disk: disk-xvisor disk-guests

# boundary u-boot script
$(DISK_DIR)/6x_bootscript: $(XVISOR_DIR)/docs/arm/sabrelite-bootscript \
  $(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE)
	@echo "(generate) Bondary Devices u-Boot script"
	$(Q)$(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE) \
	  -A $(ARCH) -O linux -C none -T script \
	  -a 0 -e 0 -n 'boot script' -d $< $(TMPDIR)/$(@F)
	$(Q)cp $(TMPDIR)/$(@F) $@


$(DISK_DIR)/$(notdir $(XVISOR_UIMAGE)): $(XVISOR_UIMAGE)
	$(call COPY)

$(DISK_DIR)/vmm-$(BOARDNAME).dtb: $(BUILDDIR)/vmm-$(BOARDNAME).dtb
	$(call COPY)

disk-xvisor: $(DISK_DIR)/$(notdir $(XVISOR_UIMAGE)) \
  $(DISK_DIR)/vmm-$(BOARDNAME).dtb $(DISK_DIR)/6x_bootscript

# populate disk with guests information as for qemu image,
# also copy some files to the root dir to ease loading them from xvisor
disk-guests: $(STAMPDIR)/.disk_populate
	$(Q)cp $(DISKB)/nor_flash.list $(DISK_DIR)/nor_flash.list
	$(Q)cp $(DISKA)/$(DTB_IN_IMG).dtb $(DISK_DIR)/$(DTB_IN_IMG).dtb
