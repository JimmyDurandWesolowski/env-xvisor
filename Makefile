#
# This file is part of Xvisor Build Environment.
# Copyright (C) 2015-2016 Institut de Recherche Technologique SystemX
# Copyright (C) 2015-2016 OpenWide
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this Xvisor Build Environment. If not, see
# <http://www.gnu.org/licenses/>.
#
# @file Makefile
#

BUILDDIR=build
CONF=$(BUILDDIR)/.env_config

.PHONY: components-% xvisor-% busybox-% openocd-% qemu-% uboot-% \
  prepare compile rootfs rootfs-img xvisor openocd debug qemu-img \
  test clean% distclean% mrproper help

# If the configuration file does not exist
ifeq ($(wildcard $(CONF)),)
  # If this is not a cleaning rule
  ifeq ($(findstring clean,$(MAKECMDGOALS)),)
    $(error Configuration file not found. You must run the "configure" script first)
  endif
endif

-include $(CONF)
-include $(MAKEDIR)/common.mk
-include $(MAKEDIR)/components.mk
-include $(MAKEDIR)/xvisor.mk
-include $(MAKEDIR)/busybox.mk
-include $(MAKEDIR)/openocd.mk
-include $(MAKEDIR)/qemu.mk
-include $(MAKEDIR)/uboot.mk
-include $(MAKEDIR)/loader.mk
-include $(MAKEDIR)/tftp.mk
-include $(MAKEDIR)/board-$(GUEST_BOARDNAME).mk
ifeq ($(BOARD_ANDROID),1)
	-include $(MAKEDIR)/android.mk
else
	-include $(MAKEDIR)/kernel.mk
endif

export PATH := $(TOOLCHAIN_DIR)/bin:$(HOSTDIR)/bin/:$(PATH)
export ARCH
export CROSS_COMPILE=$(TOOLCHAIN_PREFIX)

# Prepare all the components, the prepare rule depend on each component path
# to be ready
fetch: $(foreach component,$(COMPONENTS),$(component)-fetch)
prepare: $(foreach component,$(COMPONENTS),$(component)-prepare)
compile: xvisor-compile
rootfs: busybox-install
rootfs-img: $(BUILDDIR)/$(ROOTFS_IMG)
xvisor: xvisor-compile
qemu-img:

ifeq ($(BOARD_QEMU),1)
  run: qemu-run
else # BOARD_QEMU != 1
  run: openocd-run
  debug: openocd-debug
  openocd: openocd-compile
  init: openocd-init
  tftp: xvisor-tftp
endif # BOARD_QEMU

test: $(.DEFAULT_GOAL)
ifneq ($(TEST_NAME),)
	$(Q)$(TESTDIR)/$(TEST_NAME) $(BUILDDIR)/$(TEST_NAME).log
endif

clean:
	$(Q)find . -name "*~" -delete

distclean-prepare:
	$(Q)rm -rf $(foreach component,$(COMPONENTS),\
		$(BUILDDIR)/\$($(component)_PATH))

distclean:
	$(Q)rm -rf $(BUILDDIR)

mrproper: distclean clean
	$(Q)$(RM) local.conf
	$(Q)if [ -d ".git/" ]; then git clean -dfx; fi

help:
	@printf "Board			$(BOARDNAME)\n"
	@printf "Toolchain:		$(TOOLCHAIN_PREFIX)\n"
	@printf "Enabled components:	$(COMPONENTS)\n"
	@printf "\n"
	@printf "Available rules:\n"
	@printf "  prepare		- Get component source code\n"
	@printf "  configure		- Configure components\n"
	@printf "  compile		- Compile components\n"
ifeq ($(BOARD_BUSYBOX),1)
	@printf "  rootfs		- Generate the rootfs\n"
	@printf "  rootfs-img		- Generate the rootfs\n"
endif
ifeq ($(BOARD_QEMU),1)
	@printf "  run			- Start the board emulation\n"
endif
ifeq ($(BOARD_LOADER),1)
	@printf "  load			- Load Xvisor on the board\n"
endif
ifneq ($(TEST_NAME),)
	@printf "  test			- Run automatic test\n"
endif
	@printf "\n"
	@printf "  [COMPONENT]_prepare	- Get the component COMPONENT source "
	@printf "code\n"
	@printf "  [COMPONENT]_configure	- Configure the component\n"
	@printf "  [COMPONENT]_compile	- Compile the component\n"
	@printf "\n"
	@printf "  clean			- remove built file.\n"
	@printf "  distclean		- remove all non source file.\n"
