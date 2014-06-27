$(BUSYBOX_BUILD_DIR):
	$(Q)mkdir -p $@

busybox-configure $(BUSYBOX_BUILD_CONF): $(CONFDIR)/$(BUSYBOX_CONF) \
  $(BUSYBOX_DIR)
	$(call COPY)

$(STAMPDIR)/.target_compile: $(TOOLCHAIN_DIR) $(BUSYBOX_BUILD_CONF) $(CONF) \
  | $(BUSYBOX_BUILD_DIR) $(STAMPDIR)
	@echo "(make) busybox"
	$(Q)$(MAKE) -C $(BUSYBOX_DIR) O=$(BUSYBOX_BUILD_DIR) all
	$(Q)touch $@

busybox-compile: $(STAMPDIR)/.target_compile

$(STAMPDIR)/.target: $(STAMPDIR)/.target_compile
	@echo "(install) $@"
	$(Q)$(MAKE) -C $(BUSYBOX_DIR) O=$(BUSYBOX_BUILD_DIR) \
	  CONFIG_PREFIX=$(TARGETDIR) install
	$(Q)touch $@

BUSYBOX-install: $(STAMPDIR)/.target

$(XVISOR_DIR)/$(BUSYBOX_XVISOR_DEV): $(XVISOR_DIR)

# $(BUILDDIR)/$(ROOTFS_IMG) for ext2
$(BUILDDIR)/%.ext2: $(STAMPDIR)/.target $(ROOTFS_EXTRA) \
  $(XVISOR_DIR)/$(BUSYBOX_XVISOR_DEV)
	@echo "(fakeroot/genext2fs) $@"
	$(Q)SIZE=$$(du -b --max-depth=0 $(TARGETDIR) | cut -f 1); \
		BLK_SZ=1024; SIZE=$$(( $${SIZE} / $${BLK_SZ} + 1024 )); \
		fakeroot /bin/bash -c "genext2fs -b $${SIZE} -N $${BLK_SZ} -D \
		  $(XVISOR_DIR)/$(BUSYBOX_XVISOR_DEV) -d $(TARGETDIR) $@"

busybox-menuconfig: $(BUSYBOX_DIR)
	@echo "(menuconfig) Busybox"
	$(Q)$(MAKE) -C $(BUSYBOX_BUILD_DIR) menuconfig

