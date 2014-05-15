xvisor-configure $(XVISOR_BUILD_CONF): $(CONFDIR)/$(XVISOR_CONF) $(XVISOR_DIR)
	$(call COPY)

xvisor-compile: $(XVISOR_DIR) $(XVISOR_BUILD_CONF) $(CONF) \
  | $(XVISOR_BUILD_DIR)
	$(Q)$(MAKE) -C $(XVISOR_DIR) all

xvisor-menuconfig: $(XVISOR_DIR)
	@echo "(menuconfig) Busybox"
	$(Q)$(MAKE) -C $(XVISOR_BUILD_DIR) menuconfig
