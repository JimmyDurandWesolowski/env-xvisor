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
# @file make/android.mk
#


XVISOR_ANDROID_CONF_DIR=$(XVISOR_DIR)/tests/$(XVISOR_ARCH)/$(GUEST_BOARDNAME)/android
ANDROID_DTS_PATCH_DIR=$(ANDROID_DIR)/kernel_imx/arch/${ARCH}/boot/dts/include
ANDROID_DTS_DIR=$(ANDROID_DIR)/kernel_imx/arch/${ARCH}/boot/dts
ANDROID_KERNEL_DIR=$(ANDROID_DIR)/kernel_imx

ANDROID_DTB_TARGET=imx6q-nitrogen6x.dtb


$(ANDROID_BUILD_DIR):
	$(Q)mkdir -p $@




$(DISK_DIR)/$(DISK_dddBOARD)/$(KERN_DT).dtb: $(TMPDIR)/$(KERN_DT).dts $(XVISOR_BUILD_DIR)/tools/dtc/dtc 
	@echo "(dtc) $(KERN_DT)" 
	$(Q)$(XVISOR_BUILD_DIR)/tools/dtc/dtc -I dts -O dtb -p 0x800 -o $@ $< 

android-compile:
	@echo "(make) $(ANDROID_CONF)"
	$(Q)cd $(ANDROID_DIR); source build/envsetup.sh; OUT_DIR=$(ANDROID_BUILD_DIR) lunch $(ANDROID_CONF); \
	OUT_DIR=$(ANDROID_BUILD_DIR) make -j$(PARALLEL_JOBS); cd -

android-patch-dts: $(XVISOR_ANDROID_CONF_DIR) 
	$(Q)cp $^/* $(ANDROID_DTS_DIR)

android-dtbs: android-patch-dts android-sed
	@echo "(make) android-dtbs"
	cd $(ANDROID_KERNEL_DIR); make $(ANDROID_DTB_TARGET); cd -


android-sed:
	$(Q)sed -r  s/TARGET_BOARD_DTS_CONFIG=imx6q:imx6q-nitrogen6x.dtb\ /TARGET_BOARD_DTS_CONFIG=imx6q:imx6q-nitrogen6x.dtb#\ / -i  build/android/device/boundary/nitrogen6x/AndroidBoard.mk

$(DISK_DIR)/$(DISK_BOARD)/Image: android-imx
	$(Q)cp $(ANDROID_KERNEL_DIR)/arch/$(ARCH)/boot/Image $@

$(DISK_DIR)/$(DISK_BOARD)/$(ANDROID_DTB_TARGET): android-imx
	$(Q)cp $(ANDROID_KERNEL_DIR)/arch/$(ARCH)/boot/dts/$(ANDROID_DTB_TARGET) $@


android-imx: xvisor-imx android-compile android-dtbs



