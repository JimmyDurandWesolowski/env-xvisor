BOARDNAME_CONF?=$(shell echo $(BOARDNAME) | tr '-' '_')
XVISOR_LINUX_CONF_DIR=$(XVISOR_DIR)/tests/$(XVISOR_ARCH)/$(BOARDNAME)/linux
XVISOR_LINUX_CONF_NAME=$(LINUX_PATH)_$(BOARDNAME_CONF)_defconfig
XVISOR_LINUX_CONF=$(XVISOR_LINUX_CONF_DIR)/$(XVISOR_LINUX_CONF_NAME)

$(XVISOR_LINUX_CONF): $(XVISOR_DIR)

$(LINUX_BUILD_DIR):
	$(Q)mkdir -p $@

$(LINUX_BUILD_CONF): $(XVISOR_LINUX_CONF) | $(LINUX_BUILD_DIR) $(LINUX_DIR) TOOLCHAIN-prepare
	@echo "(defconfig) Linux"
	$(Q)cp $< $@
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) oldconfig

$(LINUX_BUILD_DIR)/vmlinux: $(LINUX_BUILD_CONF) | $(LINUX_DIR) $(TOOLCHAIN)
	@echo "(make) Linux"
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) vmlinux

$(DISK_DIR)/$(DISK_BOARD)/$(KERN_IMG): $(LINUX_BUILD_DIR)/vmlinux \
  $(XVISOR_DIR)/$(XVISOR_ELF2C) $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH) \
  | $(DISK_DIR)/$(DISK_BOARD)
	@echo "(patch) Linux"
	$(Q)mv $< $<.bak
	$(Q)$(XVISOR_DIR)/$(XVISOR_ELF2C) -f $< | \
	  $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH) $< 0
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) Image
	$(Q)mv $<.bak $<
	$(Q)mv $(LINUX_BUILD_DIR)/arch/$(ARCH)/boot/Image $@

$(LINUX_BUILD_DIR)/arch/$(ARCH)/boot/zImage: $(LINUX_BUILD_DIR)/vmlinux
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) zImage


$(LINUX_DIR)/arch/$(ARCH)/boot/dts/$(KERN_DT).dts: | $(LINUX_DIR)

$(DISK_DIR)/$(DISK_BOARD)/$(KERN_DT).dtb: $(LINUX_DIR)/arch/$(ARCH)/boot/dts/$(KERN_DT).dts $(XVISOR_BUILD_DIR)/tools/dtc/dtc | $(XVISOR_DIR) $(DISK_DIR)/$(DISK_BOARD)
	@echo "(dtc) $(KERN_DT)"
	$(XVISOR_BUILD_DIR)/tools/dtc/dtc -I dts -O dtb -p 0x800 -o $@ $<

linux-configure: $(LINUX_BUILD_CONF)

linux-oldconfig linux-menuconfig linux-dtbs: | $(LINUX_BUILD_DIR) $(LINUX_DIR) TOOLCHAIN-prepare
	@echo "($(subst linux-,,$@)) Linux"
	$(Q)$(MAKE) -C $(LINUX_DIR) O=$(LINUX_BUILD_DIR) $(subst linux-,,$@)

