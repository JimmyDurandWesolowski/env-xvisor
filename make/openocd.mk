# OpenOCD configure is buggy, reconfigure it
$(STAMPDIR)/.openocd_reconf: $(OPENOCD_DIR) | $(STAMPDIR)
	$(Q)cd $< && autoreconf --force --install
	$(Q)touch $@

$(BUILDDIR)/generated_$(OPENOCD_CONF): $(XVISOR_BIN) $(CONF) \
  $(XVISOR_BUILD_DIR)/vmm.elf $(TOOLCHAIN) $(BUILDDIR)/$(BOARDNAME).dtb \
  $(SCRIPTDIR)/openocd_gen_xvisor.sh
	@echo "(generate) $(OPENOCD_CONF)"
	$(Q)TOOLCHAIN_PREFIX=$(TOOLCHAIN_PREFIX) \
	  BUILD_DEBUG=$(BUILD_DEBUG) \
	  BASE_ADDR=$(ADDR_HYPER) \
	  RAM_BASE=$(RAM_BASE) \
	  BOARD=$(BOARDNAME) \
	  $(SCRIPTDIR)/openocd_gen_xvisor.sh $(XVISOR_BUILD_DIR)/vmm.elf \
	    $(XVISOR_BIN) $(BUILDDIR)/$(BOARDNAME).dtb $@

openocd-configure $(OPENOCD_BUILD_DIR)/Makefile: $(STAMPDIR)/.openocd_reconf \
  $(CONF) | $(OPENOCD_DIR)
	$(Q)mkdir -p $(OPENOCD_BUILD_DIR)
	$(Q)cd $(OPENOCD_BUILD_DIR) && \
	  $(OPENOCD_DIR)/configure --enable-ftdi --prefix=$(HOSTDIR)

openocd-compile $(OPENOCD_BUILD_DIR)/src/openocd: | $(OPENOCD_BUILD_DIR)/Makefile
	$(Q)$(MAKE) -C $(OPENOCD_BUILD_DIR) all

openocd-install $(HOSTDIR)/bin/openocd: $(OPENOCD_BUILD_DIR)/src/openocd
	$(Q)$(MAKE) -C $(OPENOCD_BUILD_DIR) install

CONF_RULE=$(wildcard $(CONFDIR)/*usb-jtag-perm.rules)
INSTALLED_RULE=$(wildcard /etc/udev/rules.d/*usb-jtag-perm.rules)
OPENOCD_DEPS=$(HOSTDIR)/bin/openocd $(XVISOR_BIN) $(BUILDDIR)/$(BOARDNAME).dtb\
  $(BUILDDIR)/generated_$(OPENOCD_CONF) | $(CONFDIR)/$(OPENOCD_CONF) \
  $(CONFDIR)/openocd


define OPENOCD_LAUNCH
	$(Q)openocd -f $(BUILDDIR)/generated_$(OPENOCD_CONF) \
          -f $(CONFDIR)/$(OPENOCD_CONF) -s $(CONFDIR)/openocd \
	  -c "$1" ||\
          RET=$$?; \
	  if [ $${RET} -eq 1 -a ! -e \"$(INSTALLED_RULE)\" ]; then \
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
$(GDB_CONF): $(CURDIR)/Makefile | $(XVISOR_BUILD_DIR)/vmm.elf
	$(Q)echo "target remote localhost:3333" > $@
	$(Q)echo "set arm force-mode arm" >> $@
	$(Q)[ -e "$(CURDIR)/gdb_extra.conf" ] && \
	  cat "$(CURDIR)/gdb_extra.conf" >> $@ || true
	$(Q)echo "file $|" >> $@

gdb: $(GDB_CONF) | $(TOOLCHAIN_DIR)/bin/$(TOOLCHAIN_PREFIX)gdb
	$(Q)$| --command=$<

cgdb: $(GDB_CONF) | $(TOOLCHAIN_DIR)/bin/$(TOOLCHAIN_PREFIX)gdb
	$(Q)$@ -d $| -- --command=$<

telnet:
	${Q}telnet localhost 4444
