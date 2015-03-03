
# BOARDNAME: nitrogen6x || sabrelite
ifeq ($(XVISOR_BOARDNAME),sabrelite)

# boundary u-boot script
$(DISK_DIR)/6x_bootscript: $(XVISOR_DIR)/docs/arm/sabrelite-bootscript $(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE)
	@echo "(generate) Bondary Devices u-Boot script"
	$(Q)$(UBOOT_BUILD_DIR)/$(UBOOT_MKIMAGE) \
	  -A $(ARCH) -O linux -C none -T script \
	  -a 0 -e 0 -n 'boot script' -d $< $(TMPDIR)/$(@F)
	$(Q)cp $(TMPDIR)/$(@F) $@


$(DISK_DIR)/$(notdir $(XVISOR_UIMAGE)): $(XVISOR_UIMAGE)
	$(call COPY)

$(DISK_DIR)/vmm-imx6q-$(BOARDNAME).dtb: $(BUILDDIR)/$(XVISOR_BOARDNAME).dtb
	$(call COPY)

disk-xvisor: $(DISK_DIR)/$(notdir $(XVISOR_UIMAGE)) $(DISK_DIR)/vmm-imx6q-$(BOARDNAME).dtb $(DISK_DIR)/6x_bootscript

endif # nitrogen6x || sabrelite
