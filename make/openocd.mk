# OpenOCD configure is buggy, reconfigure it
$(STAMPDIR)/.openocd_reconf: $(OPENOCD_DIR) | $(STAMPDIR)
	$(Q)cd $< && autoreconf --force --install
	$(Q)touch $@

openocd-configure $(OPENOCD_BUILD_DIR)/Makefile: $(OPENOCD_DIR) \
  $(STAMPDIR)/.openocd_reconf $(CONF)
	$(Q)mkdir -p $(OPENOCD_BUILD_DIR)
	$(Q)cd $(OPENOCD_BUILD_DIR) && \
	  $(OPENOCD_DIR)/configure --enable-ftdi --prefix=$(HOSTDIR)

openocd-compile $(OPENOCD_BUILD_DIR)/src/openocd: $(OPENOCD_BUILD_DIR)/Makefile
	$(Q)$(MAKE) -C $(OPENOCD_BUILD_DIR) all

openocd-install $(HOSTDIR)/bin/openocd: $(OPENOCD_BUILD_DIR)/src/openocd
	$(Q)$(MAKE) -C $(OPENOCD_BUILD_DIR) install

CONF_RULE=$(wildcard $(CONFDIR)/*usb-jtag-perm.rules)
INSTALLED_RULE=$(wildcard /etc/udev/rules.d/*usb-jtag-perm.rules)
OPENOCD_DEPS=$(HOSTDIR)/bin/openocd $(XVISOR_BIN) \
  | $(CONFDIR)/$(OPENOCD_CONF).cfg $(CONFDIR)/openocd


define OPENOCD_LAUNCH
	$(Q)openocd -f $(CONFDIR)/$(OPENOCD_CONF).cfg -s $(CONFDIR)/openocd \
	  -c "$1" ||\
          RET=$$?; \
	  if [ $${RET} -eq 1 -a ! -e $(INSTALLED_RULE) ]; then \
	    echo; \
	    echo "If you have any permission difficulties, copy the file"; \
	    echo "  $(CONF_RULE)"; \
	    echo "to your udev rule directory, and restart the udev daemon"; \
	  fi; \
	  exit $${RET}
endef

openocd-init: $(OPENOCD_DEPS)
	$(call OPENOCD_LAUNCH,reset init)

openocd-debug: $(OPENOCD_DEPS)
	$(call OPENOCD_LAUNCH,reset init; xvisor_init)

openocd-run: $(OPENOCD_DEPS)
	$(call OPENOCD_LAUNCH,reset init; xvisor_launch)

GDB_CONF=$(TMPDIR)/gdb.conf

.PHONY: $(GDB_CONF)

# FIXME: Avoid hard coded values
$(GDB_CONF): $(CURDIR)/Makefile | $(XVISOR_BUILD_DIR)/vmm_tmp.elf
	$(Q)echo "target remote localhost:3333" > $@
	$(Q)echo "set arm force-mode arm" >> $@
	$(Q)echo "file $|" >> $@

gdb: $(GDB_CONF) | $(TOOLCHAIN_DIR)/bin/$(TOOLCHAIN_PREFIX)gdb
	$(Q)$| --command=$<

cgdb: $(GDB_CONF) | $(TOOLCHAIN_DIR)/bin/$(TOOLCHAIN_PREFIX)gdb
	$(Q)$@ -d $| -- --command=$<

telnet:
	${Q}telnet localhost 4444
