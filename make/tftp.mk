ifneq ($(TFTPDIR),)
tftp-%:
	$(Q)echo Copying: $(notdir $^)
	$(Q)echo make sure your user has write permissions to '"'$(TFTPDIR)'"'
	$(Q)echo install a tftp server "tftpd-hpa" for instance.
	$(Q)if [ -d $(TFTPDIR) ]; then cp $^ $(TFTPDIR); fi

tftp-uboot: $(UBOOT_BUILD_DIR)/u-boot.imx $(UBOOT_BUILD_DIR)/u-boot.bin

tftp-xvisor: $(XVISOR_IMX) $(XVISOR_BIN) $(XVISOR_UIMAGE) $(BUILDDIR)/$(BOARDNAME).dtb

endif
