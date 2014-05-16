$(BUILDDIR)/qemu.img: $(XVISOR_DIR)/$(MEMIMG) $(XVISOR_BIN) $(DISK_IMG)
	echo $^
	$(Q)$< -a $(ADDR_HYPER) -o $@ $(XVISOR_IMG)@$(ADDR_HYPER) \
		$(DISK_IMG)@$(ADDR_DISK)
