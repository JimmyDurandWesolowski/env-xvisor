
# BOARDNAME: nitrogen6x || sabrelite
ifeq ($(XVISOR_BOARDNAME),sabrelite)
disk: disk-xvisor disk-guests

ifeq ($(DTBS_IN_IMG),)
DTBS_IN_IMG=$(foreach dtb,$(DTB_IN_IMG),$(DISKA)/$(dtb).dtb)
endif

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

# populate disk with guests information as for qemu image,
# also copy some files to the root dir to ease loading them from xvisor
disk-guests: $(STAMPDIR)/.disk_populate
	$(Q)cp $(DISKB)/nor_flash.list $(DISKB)/nor_flash_fw.list $(DISK_DIR)/
	$(Q)cp $(DTBS_IN_IMG) $(DISK_DIR)/

endif # nitrogen6x || sabrelite
