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
# @file make/busybox.mk
#

define busybox_build
	$(Q)$(MAKE) -C $(BUSYBOX_DIR) O=$(BUSYBOX_BUILD_DIR) $1
endef

$(BUSYBOX_BUILD_DIR):
	$(Q)mkdir -p $@

busybox-configure $(BUSYBOX_BUILD_CONF): $(CONFDIR)/$(BUSYBOX_CONF) | \
  BUSYBOX-prepare
	$(call COPY)

busybox-menuconfig: TOOLCHAIN-prepare BUSYBOX-prepare $(BUSYBOX_BUILD_DIR)
	@echo "(menuconfig) Busybox"
	$(call busybox_build,menuconfig)
	rm $(STAMPDIR)/.target_compile
	rm $(STAMPDIR)/.target

ifeq ($(ROOTFS_LOCAL),)
$(STAMPDIR)/.target_compile: $(BUSYBOX_BUILD_CONF) $(CONF) \
  | $(BUSYBOX_BUILD_DIR) $(STAMPDIR) TOOLCHAIN-prepare
	@echo "(make) busybox"
	$(call busybox_build,all)
	$(Q)touch $@

busybox-compile: $(STAMPDIR)/.target_compile

$(STAMPDIR)/.target: $(STAMPDIR)/.target_compile
	@echo "(install) $@"
	$(call busybox_build,CONFIG_PREFIX=$(TARGETDIR) install)
	$(Q)mkdir -p $(TARGETDIR)/dev
	$(Q)mkdir -p $(TARGETDIR)/proc
	$(Q)mkdir -p $(TARGETDIR)/sys
	$(Q)mkdir -p $(TARGETDIR)/mnt
	$(Q)mkdir -p $(TARGETDIR)/etc/init.d
	$(Q)ln -sf /sbin/init $(TARGETDIR)/init
	$(Q)cp -f $(XVISOR_DIR)/tests/common/busybox/fstab $(TARGETDIR)/etc/fstab
	$(Q)cp -f $(XVISOR_DIR)/tests/common/busybox/rcS $(TARGETDIR)/etc/init.d/rcS
	$(Q)cp -f $(XVISOR_DIR)/tests/common/busybox/motd $(TARGETDIR)/etc/motd
	$(Q)touch $@

BUSYBOX-install: $(STAMPDIR)/.target
endif

$(XVISOR_DIR)/$(BUSYBOX_XVISOR_DEV): XVISOR-prepare

ifeq ($(ROOTFS_LOCAL),)
# $(BUILDDIR)/$(ROOTFS_IMG) for ext2
$(BUILDDIR)/%.ext2: $(STAMPDIR)/.target $(ROOTFS_EXTRA) \
  $(XVISOR_DIR)/$(BUSYBOX_XVISOR_DEV)
	@echo "(fakeroot/genext2fs) $@"
	$(Q)SIZE=$$(du -b --max-depth=0 $(TARGETDIR) | cut -f 1); \
		BLK_SZ=1024; SIZE=$$(( $${SIZE} / $${BLK_SZ} + 1024 )); \
		fakeroot /bin/bash -c "genext2fs -b $${SIZE} -N $${BLK_SZ} -D \
		  $(CONFDIR)/$(BUSYBOX_XVISOR_DEV) -d $(TARGETDIR) $@"
else
$(BUILDDIR)/%.ext2: $(ROOTFS_LOCAL)
	cp $(ROOTFS_LOCAL) $@
endif

$(BUILDDIR)/$(INITRD): $(STAMPDIR)/.target \
	$(XVISOR_DIR)/$(BUSYBOX_XVISOR_DEV)
	$(Q)cd $(TARGETDIR) &&  find . | cpio -o -H newc > $@
