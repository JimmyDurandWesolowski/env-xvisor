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

openocd-run: $(HOSTDIR)/bin/openocd $(TOOLCHAIN_DIR) $(BUILDDIR)/loop.bin \
  $(BUILDDIR)/build_xvisor-next-master/vmm.bin \
  | $(CONFDIR)/$(OPENOCD_CONF).cfg $(CONFDIR)/openocd
	$(Q)openocd -f $(CONFDIR)/$(OPENOCD_CONF).cfg -s $(CONFDIR)/openocd ||\
          RET=$$?; \
	  if [ $${RET} -eq 1 -a ! -e $(INSTALLED_RULE) ]; then \
	    echo; \
	    echo "If you have any permission difficulties, copy the file"; \
	    echo "  $(CONF_RULE)"; \
	    echo "to your udev rule directory, and restart the udev daemon"; \
	  fi; \
	  exit $${RET}

GDB_CONF=$(TMPDIR)/gdb.conf

.PHONY: $(GDB_CONF)

$(GDB_CONF): | $(XVISOR_BUILD_DIR)/vmm_tmp.elf
	$(Q)printf "target remote localhost:3333\nfile $|\n" > $@

gdb: $(GDB_CONF) | $(TOOLCHAIN_DIR)/bin/$(TOOLCHAIN_PREFIX)gdb
	$(Q)$| --command=$<

cgdb: $(GDB_CONF) | $(TOOLCHAIN_DIR)/bin/$(TOOLCHAIN_PREFIX)gdb
	$(Q)$@ -d $| -- --command=$<

telnet:
	${Q}telnet localhost 4444

$(BUILDDIR)/loop:
	$(Q)printf ".text\n.globl _start\n_start:\n\t\
	  mov r0, pc\n\tadd r0, #-8\n\tmov pc, r0\n" | \
	  $(TOOLCHAIN_PREFIX)gcc -nostdlib -o $@ -x assembler -

$(BUILDDIR)/loop.bin: $(BUILDDIR)/loop
	$(Q)$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
