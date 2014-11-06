ifeq ($(BOARD_LOADER),1)
loader-build: $(STAMPDIR)/.loader_build

$(STAMPDIR)/.loader_build: $(LOADER_DIR) | $(STAMPDIR)
	$(Q)$(MAKE) -C $(LOADER_DIR) all
	$(Q)touch $@


IMX_CONF_RULE=$(wildcard $(CONFDIR)/*usb-imx-perm.rules)
IMX_INSTALLED_RULE=$(wildcard /etc/udev/rules.d/*usb-imx-perm.rules)

load-%: | $(STAMPDIR)/.loader_build
	$(Q)echo USB Loading $(notdir $<)
	$(Q)echo make sure the switch are correclty set: D1 ON, D2 OFF
	$(Q)$(LOADER_DIR)/imx_usb $<
	$(Q)if [ -z "$(IMX_INSTALLED_RULE)" -o ! -e $(IMX_INSTALLED_RULE) ]; then \
	  echo; \
	  echo "If you have any permission difficulties, copy the file"; \
	  echo "  $(IMX_CONF_RULE)"; \
	  echo "to your udev rule directory, and restart the udev daemon"; \
	fi; \

loadcheck:
	$(Q)lsusb |grep 'Freescale Semiconductor'

load-uboot: $(UBOOT_BUILD_DIR)/u-boot.imx

load-xvisor: $(XVISOR_IMX)

endif
