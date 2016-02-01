#
# This file is part of Xvisor Build Environment.
# Copyright (C) 2015 Institut de Recherche Technologique SystemX
# Copyright (C) 2015 OpenWide
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
# @file make/loader.mk
#

ifeq ($(BOARD_LOADER),1)
loader-build: $(STAMPDIR)/.loader_build

$(STAMPDIR)/.loader_build: LOADER-prepare | $(STAMPDIR)
	$(Q)$(MAKE) -C $(LOADER_DIR) all
	$(Q)touch $@


IMX_CONF_RULE=$(wildcard $(CONFDIR)/*usb-imx-perm.rules)
IMX_INSTALLED_RULE=$(wildcard /etc/udev/rules.d/*usb-imx-perm.rules)

load-%: | $(STAMPDIR)/.loader_build
	$(Q)echo USB Loading $(notdir $<)
	$(Q)echo make sure the switch are correclty set: D1 ON, D2 OFF
	$(Q)$(LOADER_DIR)/imx_usb $<
	$(Q)if [ -z "$(IMX_INSTALLED_RULE)" -o ! -e $(IMX_INSTALLED_RULE) ]; \
	then \
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
