$(BUILDDIR)/$(BUSYBOX_PATH)/.config: $(BUSYBOX_CONF)
	@echo "(copy) $@"
	$(Q)mkdir -p $(@D)
	$(Q)cp -f $< $@

$(STAMPDIR)/.target:
	@echo "(make) $@"
	$(Q)$(MAKE) -C $(BUSYBOX_PATH) install

$(ROOTFS_IMG): $(STAMPDIR)/.target $(ROOTFS_EXTRA)
	$(Q)mkdir -p $(@D)
	@echo "(fakeroot) $@"
	$(Q)SIZE=$$(du -b --max-depth=0 $(ROOTFS_TARGET) | cut -f 1); \
		BLK_SZ=1024; SIZE=$$(( $${SIZE} / $${BLK_SZ} + 1024 )); \
		fakeroot /bin/bash -c "genext2fs -b $${SIZE} -N $${BLK_SZ} -D \
		  $(MAKE_PATH)/tests/$(MACH)/busybox_dev.txt \
		  -d $(BUSYBOX_PATH)/_install $@"

busybox-menuconfig:
	@echo "(menuconfig) Busybox"
	$(Q)$(MAKE) -C $(BUSYBOX_PATH) menuconfig

BUSYBOX_configure: $(BUSYBOX_PATH)/.config
