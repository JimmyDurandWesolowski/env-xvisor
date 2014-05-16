$(XVISOR_DIR)/$(MEMIMG): $(XVISOR_DIR)
OPENCONF_INPUT=$(XVISOR_DIR)/openconf.cfg


# $(call COPY)
# $(Q)$(MAKE) -C $(XVISOR_BUILD_DIR) O=$(XVISOR_DIR) oldconfig

xvisor-configure $(XVISOR_BUILD_CONF): $(CONFDIR)/$(XVISOR_CONF) $(XVISOR_DIR)
	@echo "(defconfig) xVisor"
	$(Q)mkdir -p $(XVISOR_BUILD_DIR)/tmpconf $(XVISOR_BUILD_DIR)/tools
	$(Q)find $(XVISOR_DIR)/tools/openconf -name "*.h" -exec cp {} $(XVISOR_BUILD_DIR)/tmpconf \;
	$(Q)$(MAKE) -C $(XVISOR_DIR)/tools/openconf openconf_defs.h
	$(Q)cd $(XVISOR_DIR) && \
	  find -name "*.cfg" -exec cp --parent {} $(XVISOR_BUILD_DIR) \;
	$(Q)cd $(XVISOR_BUILD_DIR) && \
          $(XVISOR_DIR)/tools/openconf/conf -D \
	  $(CONFDIR)/$(XVISOR_CONF) $(OPENCONF_INPUT)

xvisor-menuconfig: $(XVISOR_DIR)
	@echo "(menuconfig) Busybox"
	$(Q)$(MAKE) -C $(XVISOR_DIR) O=$(XVISOR_BUILD_DIR) menuconfig

xvisor-dtb: $(XVISOR_BUILD_CONF)
	@echo "(make) xVisor dtb"
	$(Q)$(MAKE) -C $(XVISOR_DIR) O=$(XVISOR_BUILD_DIR) all dtbs

xvisor-compile $(XVISOR_BIN): $(XVISOR_DIR) $(XVISOR_BUILD_CONF) $(CONF) \
  | $(XVISOR_BUILD_DIR)
	@echo "(make) xVisor"
	$(Q)$(MAKE) -C $(XVISOR_DIR) O=$(XVISOR_BUILD_DIR) all


# TODO
# xvisor-imx $(XVISOR_IMX):

# TODO
# $(BUILDDIR)/$(DISK_IMG): $(DISK_DIR) $(KERN_IMG) $(FW_IMG) $(CMDS_IMG) \
#   $(FLASH_IMG)
# 	@echo "(genext2fs) $@"
# 	$(Q)SIZE=$$(du -b --max-depth=0 $(DISK_DIR) | cut -f 1); \
# 		BLK_SZ=1024; SIZE=$$(( $${SIZE} / $${BLK_SZ} * 5 / 4 )); \
# 		genext2fs -b $${SIZE} -N $${BLK_SZ} -d $(DISK_DIR) $@
