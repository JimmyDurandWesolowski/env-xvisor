BUSYBOX_DIR=$(BUILDDIR)/$(BUSYBOX_PATH)
BUSYBOX_BUILD_DIR=$(BUILDDIR)/build_$(BUSYBOX_PATH)
BUSYBOX_BUILD_CONF=$(BUSYBOX_BUILD_DIR)/.config

$(BUSYBOX_BUILD_DIR):
	$(Q)mkdir -p $@

BUSYBOX-configure $(BUSYBOX_BUILD_CONF): $(CONFDIR)/$(BUSYBOX_CONF) \
  | $(BUSYBOX_BUILD_DIR)
	@echo "(copy) $@"
	$(Q)cp -f $< $@

BUSYBOX-compile: $(BUSYBOX_BUILD_CONF) | $(BUSYBOX_BUILD_DIR)
	$(Q)$(MAKE) -C $(BUSYBOX_DIR) O=$(BUSYBOX_BUILD_DIR) all

$(STAMPDIR)/.target: BUSYBOX-compile | $(STAMPDIR)
	@echo "(make) $@"
	$(Q)$(MAKE) -C $(BUSYBOX_DIR) O=$(BUSYBOX_BUILD_DIR) \
	  CONFIG_PREFIX=$(TARGETDIR) install
	$(Q)touch $@

BUSYBOX-install: $(STAMPDIR)/.target


$(BUILDDIR)/%.ext2: $(STAMPDIR)/.target $(ROOTFS_EXTRA)
	@echo "(fakeroot/genext2fs) $@"
	$(Q)SIZE=$$(du -b --max-depth=0 $(TARGETDIR) | cut -f 1); \
		BLK_SZ=1024; SIZE=$$(( $${SIZE} / $${BLK_SZ} + 1024 )); \
		fakeroot /bin/bash -c "genext2fs -b $${SIZE} -N $${BLK_SZ} -D \
		  $(CONFDIR)/busybox_dev.txt -d $(TARGETDIR) $@"

busybox-menuconfig:
	@echo "(menuconfig) Busybox"
	$(Q)$(MAKE) -C $(BUSYBOX_BUILD_DIR) menuconfig

