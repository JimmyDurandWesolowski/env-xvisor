define QEMU
	DTB=$$(find $(XVISOR_BUILD_DIR)/arch/$(ARCH)/board -name $(DTB)); \
	qemu-system-$(ARCH) -M $(BOARDNAME) -m 256M $1 \
	  -kernel $(BUILDDIR)/$(QEMU_IMG) -dtb $${DTB}
endef

$(BUILDDIR)/$(QEMU_IMG): $(XVISOR_DIR)/$(MEMIMG) $(XVISOR_BIN) $(DISK_IMG)
	@echo "(memimg) $(QEMU_IMG)"
	$(Q)$< -a $(ADDR_HYPER) -o $@ $(XVISOR_BIN)@$(ADDR_HYPER) \
		$(DISK_IMG)@$(ADDR_DISK)
