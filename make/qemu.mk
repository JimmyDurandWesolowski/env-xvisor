define QEMU
	qemu-system-$(ARCH) -M $(BOARDNAME) -m 256M $1 \
	  -kernel $(BUILDDIR)/$(QEMU_IMG) -dtb $(BUILDDIR)/$(BOARDNAME).dtb
endef

qemu-run: $(BUILDDIR)/$(QEMU_IMG) $(BUILDDIR)/$(BOARDNAME).dtb
	@echo "$@ for $(BOARDNAME)"
	$(call QEMU,-display none -serial stdio,$<)

$(BUILDDIR)/$(QEMU_IMG): $(XVISOR_DIR)/$(MEMIMG) $(XVISOR_BIN) $(DISK_IMG)
	@echo "(memimg) $(QEMU_IMG)"
	$(Q)$< -a $(ADDR_HYPER) -o $@ $(XVISOR_BIN)@$(ADDR_HYPER) \
		$(DISK_IMG)@$(ADDR_DISK)
