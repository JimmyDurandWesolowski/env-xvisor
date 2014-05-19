ifneq ($(BOARD_UBOOT),)
  $(UBOOT_DIR)/$(UBOOT_BOARD_CFG): $(UBOOT_DIR)

  # At this time, there is no other way to generate the .cfgtmp than building
  # the whole u-boot project...
  $(UBOOT_BUILD_DIR)/$(UBOOT_BOARD_CFG).cfgtmp: $(UBOOT_DIR)/$(UBOOT_BOARD_CFG)
	$(MAKE) -C $(UBOOT_DIR) O=$(UBOOT_BUILD_DIR)

  $(UBOOT_BUILD_DIR)/include/config.h: $(UBOOT_DIR)
	$(MAKE) -C $(UBOOT_DIR) O=$(UBOOT_BUILD_DIR) $(UBOOT_BOARDNAME)_config

  uboot-configure: $(UBOOT_BUILD_DIR)/include/config.h

  mkimage $(UBOOT_MKIMAGE): $(UBOOT_BUILD_DIR)/include/config.h
	$(MAKE) -C $(UBOOT_DIR) O=$(UBOOT_BUILD_DIR) tools
endif
