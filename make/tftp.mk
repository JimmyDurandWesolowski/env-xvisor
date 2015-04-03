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
# @file make/tftp.mk
#

ifneq ($(TFTPDIR),)
tftp-%:
	$(Q)echo Copying: $(notdir $^)
	$(Q)echo make sure your user has write permissions to '"'$(TFTPDIR)'"'
	$(Q)echo install a tftp server "tftpd-hpa" for instance.
	$(Q)if [ -d $(TFTPDIR) ]; then cp $^ $(TFTPDIR); fi

tftp-uboot: $(UBOOT_BUILD_DIR)/u-boot.imx $(UBOOT_BUILD_DIR)/u-boot.bin

tftp-xvisor: $(XVISOR_IMX) $(XVISOR_BIN) $(XVISOR_UIMAGE) $(BUILDDIR)/$(BOARDNAME).dtb

endif
