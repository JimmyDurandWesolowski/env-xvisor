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

$(ANDROID_KERNEL_DIR)/arch/${ARCH}/boot/compressed/vmlinux: android-imx


$(ANDROID_BUILD_DIR)/vmlinux: $(ANDROID_KERNEL_DIR)/arch/${ARCH}/boot/compressed/vmlinux
	$(Q)cp $< $@





OBJCOPYFLAGS	:=-O binary -R .comment -S

$(DISK_DIR)/$(DISK_BOARD)/$(KERN_IMG): $(ANDROID_BUILD_DIR)/vmlinux \
  $(XVISOR_DIR)/$(XVISOR_ELF2C) $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH) \
  | $(DISK_DIR)/$(DISK_BOARD)
	@echo "(patch) android kernel"
	$(Q)cp $< $<.bak
	$(Q)$(XVISOR_DIR)/$(XVISOR_ELF2C) -f $< | $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH) $< 0
	objcopy $(OBJCOPYFLAGS) $< $@
	$(Q)mv $<.bak $<


android-compile:
	@echo "(make) $(ANDROID_CONF)"
	$(Q)bash -c "cd $(ANDROID_DIR); source build/envsetup.sh; OUT_DIR=$(ANDROID_BUILD_DIR) lunch $(ANDROID_CONF); \
		        OUT_DIR=$(ANDROID_BUILD_DIR) make -j$(PARALLEL_JOBS)"

#replace dts modified in aosp build
android-patch-dts: $(XVISOR_ANDROID_CONF_DIR) 
	$(Q)cp $^/* $(ANDROID_DTS_DIR)


#disable non needed board in AndroidBoard.mk, as copy of custom dts and dtsi will break other boards.
android-sed:
	$(Q)sed -r  s/TARGET_BOARD_DTS_CONFIG=imx6q:imx6q-nitrogen6x.dtb\ /TARGET_BOARD_DTS_CONFIG=imx6q:imx6q-nitrogen6x.dtb#\ / -i  build/android/device/boundary/nitrogen6x/AndroidBoard.mk

android-unpatch-dtbs:
	$(Q)sed -r  s/TARGET_BOARD_DTS_CONFIG=imx6q:imx6q-nitrogen6x.dtb#\ /TARGET_BOARD_DTS_CONFIG=imx6q:imx6q-nitrogen6x.dtb\ / -i  build/android/device/boundary/nitrogen6x/AndroidBoard.mk

android-dtbs: android-patch-dts android-sed
	@echo "(make) android-dtbs"
	cd $(ANDROID_KERNEL_DIR); make $(ANDROID_DTB_TARGET); cd -





	
#$(DISK_DIR)/$(DISK_BOARD)/$(KERN_IMG): android-imx
#	@echo "(copy) android kernel: $(DISK_DIR)/$(DISK_BOARD)/$(KERN_IMG)"
#	$(Q)mkdir -p $(DISK_DIR)/$(DISK_BOARD)
#	$(Q)cp $(ANDROID_BUILD_DIR)/Image $@

#$(DISK_DIR)/$(DISK_BOARD)/$(ANDROID_DTB_TARGET): android-imx
#	@echo "(copy) android dtb: $(DISK_DIR)/$(DISK_BOARD)/$(ANDROID_DTB_TARGET)"
#	$(Q)cp $(ANDROID_KERNEL_DIR)/arch/$(ARCH)/boot/dts/$(ANDROID_DTB_TARGET) $@

android-imx: android-compile android-dtbs 












dtsflags = $(cppflags) -nostdinc -nostdlib -fno-builtin -D__DTS__
dtsflags += -x assembler-with-cpp -I$(XVISOR_ANDROID_CONF_DIR) -I$(ANDROID_DTS_PATCH_DIR) -I$(ANDROID_DTS_DIR)



$(TMPDIR)/$(KERN_DT).pre.dts: $(XVISOR_ANDROID_CONF_DIR)/$(KERN_DT).dts | \
	  $(XVISOR_DIR) $(DISK_DIR)/$(DISK_BOARD)
	        $(Q)sed -re 's|/include/|#include|' $< >$@

$(TMPDIR)/$(KERN_DT).dts: $(TMPDIR)/$(KERN_DT).pre.dts
	        @echo "(cpp) $(KERN_DT)"
		        $(Q)$(CROSS_COMPILE)cpp $(dtsflags) $< -o $@

$(DISK_DIR)/$(DISK_BOARD)/$(ANDROID_DTB_TARGET): $(TMPDIR)/$(KERN_DT).dts \
	  $(XVISOR_BUILD_DIR)/tools/dtc/dtc
	        @echo "(dtc) $(KERN_DT)"
		        $(Q)$(XVISOR_BUILD_DIR)/tools/dtc/dtc -I dts -O dtb -p 0x800 -o $@ $<
