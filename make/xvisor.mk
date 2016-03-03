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
# @file make/xvisor.mk
#

# cmd_xbuild target relative-srcdir relative-outdir
define cmd_xbuild
	$(Q) MAKEFLAGS= $(MAKE) -j$(PARALLEL_JOBS) -C $(XVISOR_DIR)/$2 \
	  VERBOSE=$(BUILD_VERBOSE) O=$(XVISOR_BUILD_DIR)/$3 $1
endef

$(XVISOR_DIR)/$(MEMIMG): XVISOR-prepare
$(XVISOR_DIR)/$(XVISOR_ELF2C): XVISOR-prepare


$(XVISOR_BUILD_DIR):
	$(Q)mkdir -p $@

$(XVISOR_DIR)/arch/$(ARCH)/configs/$(XVISOR_CONF): $(CONFDIR)/$(XVISOR_CONF) \
  | XVISOR-prepare
	$(call COPY)

# remove the V= variable before calling xvisor makefile
$(XVISOR_BUILD_DIR)%: MAKEOVERRIDES := $(filter-out V=%,$(MAKEOVERRIDES))

$(XVISOR_BUILD_DIR)/tools/dtc/dtc: | XVISOR-prepare $(XVISOR_BUILD_DIR)
	$(Q)mkdir -p $(@D)
	$(call cmd_xbuild,,tools/dtc,tools/dtc)

$(XVISOR_BUILD_DIR)/openconf: $(XVISOR_BUILD_DIR)/tools/dtc/dtc

$(XVISOR_BUILD_CONF): $(XVISOR_DIR)/arch/$(ARCH)/configs/$(XVISOR_CONF) \
  | TOOLCHAIN-prepare $(XVISOR_BUILD_DIR)/openconf
	@echo "(defconfig) Xvisor"
	$(call cmd_xbuild,$(XVISOR_CONF))

xvisor-configure: $(XVISOR_BUILD_CONF)

xvisor-dtbs xvisor-modules xvisor-menuconfig xvisor-vars: \
  $(XVISOR_BUILD_DIR)/tools/dtc/dtc $(XVISOR_BUILD_CONF) | XVISOR-prepare
	@echo "($(subst xvisor-,,$@)) Xvisor"
	$(call cmd_xbuild,$(subst xvisor-,,$@))

$(BUILDDIR)/vmm-$(BOARDNAME).dtb: \
  $(shell find $(XVISOR_DIR)/arch/ -name $(patsubst %.dtb,%.dts,$(DTB)))
	@echo "(dtbs) Xvisor"
	$(call cmd_xbuild,dtbs)
	@echo "(Link) $(@F)"
	$(Q)SRC=$$(find $(XVISOR_BUILD_DIR)/arch -name $(DTB)); \
	  [ -z "$${SRC}" ] \
	    && (echo "Could not find \"$(DTB)\" in the DTB directory, " \
	             "exiting"; exit 1) \
	    || ln -sf $${SRC} $@

.PHONY: $(XVISOR_BIN)
$(XVISOR_BIN): $(XVISOR_BUILD_DIR)/vmm.bin
	$(Q)ln -sf $< $@

$(XVISOR_BUILD_DIR)/vmm.bin: $(XVISOR_BUILD_CONF) $(CONF) \
  $(XVISOR_BUILD_DIR)/tools/dtc/dtc | XVISOR-prepare \
  $(XVISOR_BUILD_DIR)/openconf
	@echo "(Make) Xvisor"
	$(call cmd_xbuild)

$(XVISOR_BUILD_DIR)/vmm.elf: $(XVISOR_BIN)
xvisor-compile: $(XVISOR_BIN)

$(XVISOR_IMX): $(realpath $(XVISOR_BIN)) \
  $(UBOOT_BUILD_DIR)/$(UBOOT_BOARD_CFG).cfgtmp \
  $(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE)
	@echo "(Generate) Xvisor IMX image"
	$(Q)$(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE) \
          -n $(UBOOT_BUILD_DIR)/$(UBOOT_BOARD_CFG).cfgtmp -T imximage \
	  -e $(ADDR_HYPER) -d $< $(TMPDIR)/$(@F)
	$(Q)cp $(TMPDIR)/$(@F) $@

xvisor-imx: $(XVISOR_BIN) $(XVISOR_IMX)

$(XVISOR_UIMAGE): $(realpath $(XVISOR_BIN)) $(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE)
	@echo "(Generate) Xvisor u-Boot image"
	$(Q)$(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE) \
          -A $(ARCH) -O linux -C none -T kernel \
	  -a $(ADDR_HYPER) -e $(ADDR_HYPER) \
	  -n 'Xvisor' -d $< $(TMPDIR)/$(@F)
	$(Q)cp -v $(TMPDIR)/$(@F) $@

xvisor-uimage: $(XVISOR_BIN) $(XVISOR_UIMAGE) $(BUILDDIR)/vmm-$(BOARDNAME).dtb


$(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH): | XVISOR-prepare $(XVISOR_BUILD_DIR)
	@echo "(Make) Xvisor cpatch"
	$(Q)mkdir -p $(@D)
	$(call cmd_xbuild,,tools/cpatch,$(dir $(XVISOR_CPATCH)))

DISKA = $(DISK_DIR)/$(DISK_ARCH)
DISKB = $(DISK_DIR)/$(DISK_BOARD)

$(DISKA) $(DISKB):
	$(Q)mkdir -p $@

$(DISKA)/$(ROOTFS_IMG): $(BUILDDIR)/$(ROOTFS_IMG) | $(DISKA)
	$(call COPY)

$(DISKA)/$(DTB_IN_IMG).dtb: $(XVISOR_DIR)/tests/$(XVISOR_ARCH)/$(GUEST_BOARDNAME)/$(DTB_IN_IMG).dts \
  $(XVISOR_BUILD_DIR)/tools/dtc/dtc | $(DISKA)
	@echo "(DTC) $(DTB_IN_IMG)"
	$(Q)$(XVISOR_BUILD_DIR)/tools/dtc/dtc -I dts -O dtb -o $@ $<

FIRMWARE_DIR = $(XVISOR_BUILD_DIR)/tests/$(XVISOR_ARCH)/$(GUEST_BOARDNAME)/basic
FIRMWARE = $(FIRMWARE_DIR)/firmware.bin.patched

xvisor-firmware $(FIRMWARE): $(XVISOR_BUILD_CONF) | \
  $(XVISOR_BUILD_DIR)/openconf $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH)
	@echo "(Make) Xvisor $(GUEST_BOARDNAME) firmware"
	$(call cmd_xbuild,,tests/$(XVISOR_ARCH)/$(GUEST_BOARDNAME)/basic)

$(DISKB)/$(XVISOR_FW_IMG): $(FIRMWARE) | $(DISKB)
	$(call COPY)

$(DISKB)/nor_flash.list: $(CONF) | $(DISKB)
	@echo "(Generating) nor_flash.list"
	$(Q)echo "$(ADDRH_FLASH_FW) /$(DISK_BOARD)/$(XVISOR_FW_IMG)" > $@
	$(Q)echo "$(ADDRH_FLASH_CMD) /$(DISK_BOARD)/cmdlist" >> $@
	$(Q)echo "$(ADDRH_FLASH_KERN) /$(DISK_BOARD)/$(KERN_IMG)" >> $@
ifeq ($(USE_KERN_DT),1)
	$(Q)echo "$(ADDRH_FLASH_KERN_DT) /$(DISK_BOARD)/$(KERN_DT).dtb" >> $@
endif
	$(Q)echo "$(ADDRH_FLASH_RFS) /$(DISK_ARCH)/$(ROOTFS_IMG)" >> $@


ifeq ($(USE_KERN_DT),1)
  DISKB_KERN_DTB = $(DISKB)/$(KERN_DT).dtb
endif

$(DISKB)/cmdlist: $(CONF) $(DISKB)/$(KERN_IMG) $(DISKA)/$(ROOTFS_IMG) $(DISKB_KERN_DTB)
	@echo "(Generating) cmdlist"
	$(Q)printf "copy $(ADDRH_KERN) $(ADDRH_FLASH_KERN) " > $@
	$(Q)$(call FILE_SIZE,$(DISKB)/$(KERN_IMG)) >> $@
ifeq ($(USE_KERN_DT),1)
	$(Q)printf "copy $(ADDRH_KERN_DT) $(ADDRH_FLASH_KERN_DT) " >> $@
	$(Q)$(call FILE_SIZE,$(DISKB_KERN_DTB)) >> $@
endif
	$(Q)printf "copy $(ADDRH_RFS) $(ADDRH_FLASH_RFS) " >> $@
	$(Q)$(call FILE_SIZE,$(DISKA)/$(ROOTFS_IMG)) >> $@
ifeq ($(USE_KERN_DT),1)
	$(Q)printf "start_linux_fdt $(ADDRH_KERN) $(ADDRH_KERN_DT) $(ADDRH_RFS) " >> $@
	$(Q)$(call FILE_SIZE,$(DISKA)/$(ROOTFS_IMG)) >> $@
else
	$(Q)printf "start_linux $(ADDRH_KERN) $(ADDRH_RFS) " >> $@
	$(Q)$(call FILE_SIZE,$(DISKA)/$(ROOTFS_IMG)) >> $@
endif

$(DISK_IMG): $(STAMPDIR)/.disk_populate
	@echo "(Genext2fs) $@"
	$(Q)SIZE=$$(du -b --max-depth=0 $(DISK_DIR) | cut -f 1); \
	 	BLK_SZ=1024; SIZE=$$(( $${SIZE} / $${BLK_SZ} * 5 / 4 )); \
	 	genext2fs -b $${SIZE} -N $${BLK_SZ} -d $(DISK_DIR) $@

$(STAMPDIR)/.disk_populate: $(DISKB)/$(KERN_IMG) $(DISKB)/$(XVISOR_FW_IMG) \
  $(DISKB)/nor_flash.list $(DISKB)/cmdlist $(DISKA)/$(ROOTFS_IMG) \
  $(DISKA)/$(DTB_IN_IMG).dtb $(DISKB_KERN_DTB) $(STAMPDIR)
	$(Q)touch $@


xvisor-dump: $(XVISOR_BUILD_DIR)/vmm.elf
	@echo "(Disassemble) $<"
	$(Q)$(TOOLCHAIN_PREFIX)objdump -dS $< > $(BUILDDIR)/vmm.dis


xvisor-clean:
	$(Q)$(call cmd_xbuild,clean)


xvisor-distclean:
	$(Q)$(call cmd_xbuild,distclean)
