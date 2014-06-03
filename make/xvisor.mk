$(XVISOR_DIR)/$(MEMIMG): $(XVISOR_DIR)


$(XVISOR_DIR)/arch/$(ARCH)/configs/$(XVISOR_CONF): $(CONFDIR)/$(XVISOR_CONF) \
  | $(XVISOR_DIR)
	$(call COPY)

$(XVISOR_BUILD_DIR)/tmpconf: $(XVISOR_BUILD_DIR)

xvisor-configure $(XVISOR_BUILD_CONF) $(XVISOR_BUILD_DIR)/tmpconf: \
  $(XVISOR_DIR)/arch/$(ARCH)/configs/$(XVISOR_CONF)
	@echo "(defconfig) xVisor"
	$(Q)$(MAKE) -C $(XVISOR_DIR) O=$(XVISOR_BUILD_DIR) $(XVISOR_CONF)

xvisor-dtbs xvisor-menuconfig xvisor-vars: $(XVISOR_DIR) \
  $(XVISOR_DIR)/arch/$(ARCH)/configs/$(XVISOR_CONF)
	@echo "($(subst xvisor-,,$@)) Xvisor"
	$(Q)$(MAKE) -C $(XVISOR_DIR) O=$(XVISOR_BUILD_DIR) $(subst xvisor-,,$@)

xvisor-dtbs: $(TOOLCHAIN_DIR)

.PHONY: $(XVISOR_BIN)
$(XVISOR_BIN): $(XVISOR_DIR) $(XVISOR_BUILD_CONF) $(CONF) \
  $(XVISOR_BUILD_DIR)/tmpconf | $(XVISOR_BUILD_DIR)
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


# TODO
# $(BUILDDIR)/$(DISK_IMG): $(DISK_DIR) $(KERN_IMG) $(FW_IMG) $(CMDS_IMG) \
#   $(FLASH_IMG)
# 	@echo "(genext2fs) $@"
# 	$(Q)SIZE=$$(du -b --max-depth=0 $(DISK_DIR) | cut -f 1); \
# 		BLK_SZ=1024; SIZE=$$(( $${SIZE} / $${BLK_SZ} * 5 / 4 )); \
# 		genext2fs -b $${SIZE} -N $${BLK_SZ} -d $(DISK_DIR) $@
