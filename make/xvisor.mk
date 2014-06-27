$(XVISOR_DIR)/$(MEMIMG): $(XVISOR_DIR)

$(XVISOR_BUILD_DIR):
	$(Q)mkdir -p $@

$(XVISOR_DIR)/arch/$(ARCH)/configs/$(XVISOR_CONF): $(CONFDIR)/$(XVISOR_CONF) \
  | $(XVISOR_DIR)
	$(call COPY)

$(XVISOR_BUILD_DIR)/tools/dtc/dtc: | $(XVISOR_DIR)
	$(Q)mkdir -p $(@D)
	$(Q)$(MAKE) -C $(XVISOR_DIR)/tools/dtc O=$(@D)

$(XVISOR_BUILD_DIR)/tmpconf: $(XVISOR_BUILD_DIR)/tools/dtc/dtc

$(XVISOR_BUILD_CONF): $(XVISOR_DIR)/arch/$(ARCH)/configs/$(XVISOR_CONF) \
  $(TOOLCHAIN_DIR) | $(XVISOR_BUILD_DIR)/tmpconf
	@echo "(defconfig) xVisor"
	$(Q)$(MAKE) -C $(XVISOR_DIR) O=$(XVISOR_BUILD_DIR) $(XVISOR_CONF)

xvisor-configure: $(XVISOR_BUILD_CONF)

xvisor-dtbs xvisor-menuconfig xvisor-vars: $(XVISOR_DIR) \
  $(XVISOR_BUILD_DIR)/tools/dtc/dtc $(XVISOR_BUILD_CONF)
	@echo "($(subst xvisor-,,$@)) Xvisor"
	$(Q)$(MAKE) -C $(XVISOR_DIR) O=$(XVISOR_BUILD_DIR) $(subst xvisor-,,$@)

xvisor-dtbs: $(TOOLCHAIN_DIR)

$(BUILDDIR)/$(BOARDNAME).dtb: xvisor-dtbs
	$(Q)ln -sf $$(find $(XVISOR_BUILD_DIR)/arch/$(ARCH)/board -name $(DTB))\
	  $@


.PHONY: $(XVISOR_BIN)
$(XVISOR_BIN): $(XVISOR_BUILD_CONF) $(CONF) $(XVISOR_BUILD_DIR)/tools/dtc/dtc \
  | $(XVISOR_DIR) $(XVISOR_BUILD_DIR)/tmpconf
	@echo "(make) xVisor"
	$(Q)$(MAKE) -C $(XVISOR_DIR) O=$(XVISOR_BUILD_DIR) all
	$(Q)cp $(XVISOR_BUILD_DIR)/vmm.bin $@

xvisor-compile: $(XVISOR_BIN)

$(XVISOR_IMX): $(XVISOR_BIN) $(UBOOT_BUILD_DIR)/$(UBOOT_BOARD_CFG).cfgtmp \
  $(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE)
	@echo "(generate) xVisor IMX image"
	$(Q)$(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE) \
          -n $(UBOOT_BUILD_DIR)/$(UBOOT_BOARD_CFG).cfgtmp -T imximage \
	  -e $(ADDR_HYPER) -d $< $(TMPDIR)/$(@F)
	$(Q)cp $(TMPDIR)/$(@F) $@

xvisor-imx: $(XVISOR_IMX)

$(XVISOR_DIR)/$(XVISOR_ELF2C): $(XVISOR_DIR)

$(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH): $(XVISOR_DIR)
	$(Q)$(MAKE) -C $(XVISOR_DIR)/tools/cpatch O=$(@D)

DISKA = $(DISK_DIR)/$(DISK_ARCH)
DISKB = $(DISK_DIR)/$(DISK_BOARD)

$(DISKA) $(DISKB):
	$(Q)mkdir -p $@

$(DISKA)/$(ROOTFS_IMG): $(BUILDDIR)/$(ROOTFS_IMG)
	$(call COPY)

FIRMWARE_DIR = $(XVISOR_BUILD_DIR)/tests/$(XVISOR_ARCH)/$(BOARDNAME)/basic
FIRMWARE = $(FIRMWARE_DIR)/firmware.bin.patched

$(FIRMWARE): $(XVISOR_BUILD_CONF) | $(XVISOR_BUILD_DIR)/tmpconf
	@echo "(make) Xvisor firmware"
	$(Q)$(MAKE) -C $(XVISOR_DIR)/tests/$(XVISOR_ARCH)/$(BOARDNAME)/basic \
	  O=$(XVISOR_BUILD_DIR)

$(DISKB)/$(XVISOR_FW_IMG): $(FIRMWARE)
	$(call COPY)

$(DISKB)/nor_flash.list: $(CONF)
	@echo "(generating) nor_flash.list"
	$(Q)echo "$(ADDRH_FLASH_FW) $(DISK_BOARD)/$(XVISOR_FW_IMG)" > $@
	$(Q)echo "$(ADDRH_FLASH_CMD) $(DISK_BOARD)/cmdlist" >> $@
	$(Q)echo "$(ADDRH_FLASH_KERN) $(DISK_BOARD)/$(KERN_IMG)" >> $@
	$(Q)echo "$(ADDRH_FLASH_RFS) $(DISK_ARCH)/$(ROOTFS_IMG)" >> $@

$(DISKB)/cmdlist: $(CONF) $(DISKB)/$(KERN_IMG) $(DISKA)/$(ROOTFS_IMG)
	@echo "(generating) cmdlist"
	$(Q)printf "copy $(ADDRH_KERN) $(ADDRH_FLASH_KERN) " > $@
	$(Q)$(call FILE_SIZE,$(DISKB)/$(KERN_IMG)) >> $@
	$(Q)printf "copy $(ADDRH_RFS) $(ADDRH_FLASH_RFS) " >> $@
	$(Q)$(call FILE_SIZE,$(DISKA)/$(ROOTFS_IMG)) >> $@
	$(Q)printf "start_linux $(ADDRH_KERN) $(ADDRH_RFS) " >> $@
	$(Q)$(call FILE_SIZE,$(DISKA)/$(ROOTFS_IMG)) >> $@

$(DISK_IMG): $(DISKB)/$(KERN_IMG) $(DISKB)/$(XVISOR_FW_IMG) \
  $(DISKB)/nor_flash.list $(DISKB)/cmdlist $(DISKA)/$(ROOTFS_IMG)
	@echo "(genext2fs) $@"
	$(Q)SIZE=$$(du -b --max-depth=0 $(DISK_DIR) | cut -f 1); \
	 	BLK_SZ=1024; SIZE=$$(( $${SIZE} / $${BLK_SZ} * 5 / 4 )); \
	 	genext2fs -b $${SIZE} -N $${BLK_SZ} -d $(DISK_DIR) $@
