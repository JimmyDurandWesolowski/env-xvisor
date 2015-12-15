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

ANDROID_KERNEL_DIR=$(ANDROID_DIR)/kernel_imx
#This is where we have our custom dts files with lots of components commented
XVISOR_ANDROID_CONF_DIR=$(XVISOR_DIR)/tests/$(XVISOR_ARCH)/$(GUEST_BOARDNAME)/android
#This is were default dts for android are, we use them to link to headers like pinfunc.h
ANDROID_DTS_DIR=$(ANDROID_KERNEL_DIR)/arch/${ARCH}/boot/dts
ANDROID_DTS_PATCH_DIR=$(ANDROID_DTS_DIR)/include
#This is the prebuild coming with Android buid
ANDROID_PREBUILT=$(ANDROID_DIR)/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-


#--------------------- ANDROID COMPILATION
$(ANDROID_BUILD_DIR):
	$(Q)mkdir -p $@

$(ANDROID_KERNEL_DIR)/vmlinux: android-compile

$(ANDROID_BUILD_DIR)/vmlinux: $(ANDROID_KERNEL_DIR)/vmlinux
	$(Q)cp $< $@


#We are building a whole android here. We could build only the kernel for now, but it's done for later.
android-compile:
	        @echo "(make) $(ANDROID_CONF)"
		 $(Q)bash -c "cd $(ANDROID_DIR); source build/envsetup.sh; OUT_DIR=$(ANDROID_BUILD_DIR) lunch $(ANDROID_CONF); \
		 OUT_DIR=$(ANDROID_BUILD_DIR) make -j$(PARALLEL_JOBS)"



#-------------------------- PATCH KERNEL
OBJCOPYFLAGS	:=-O binary -R .comment -S

$(DISK_DIR)/$(DISK_BOARD)/$(KERN_IMG): $(ANDROID_BUILD_DIR)/vmlinux \
  $(XVISOR_DIR)/$(XVISOR_ELF2C) $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH) \
  | $(DISK_DIR)/$(DISK_BOARD)
	@echo "(patch) android kernel"
	$(Q)cp $< $<.bak
	$(XVISOR_DIR)/$(XVISOR_ELF2C) -f $< | $(XVISOR_BUILD_DIR)/$(XVISOR_CPATCH) $< 0
	objcopy $(OBJCOPYFLAGS) $< $@
	$(Q)mv $<.bak $<

#----------------- DTB GENERATION
dtsflags = $(cppflags) -nostdinc -nostdlib -fno-builtin -D__DTS__
dtsflags += -x assembler-with-cpp -I$(XVISOR_ANDROID_CONF_DIR) -I$(ANDROID_DTS_PATCH_DIR) -I$(ANDROID_DTS_DIR)



$(TMPDIR)/$(KERN_DT).pre.dts: $(XVISOR_ANDROID_CONF_DIR)/$(KERN_DT).dts | \
	  $(XVISOR_DIR) $(DISK_DIR)/$(DISK_BOARD)
	        $(Q)sed -re 's|/include/|#include|' $< >$@

$(TMPDIR)/$(KERN_DT).dts: $(TMPDIR)/$(KERN_DT).pre.dts
	        @echo "(cpp) $(KERN_DT)"
		        $(Q)$(ANDROID_PREBUILT)cpp $(dtsflags) $< -o $@

$(DISK_DIR)/$(DISK_BOARD)/$(KERN_DT).dtb: $(TMPDIR)/$(KERN_DT).dts \
	  $(XVISOR_BUILD_DIR)/tools/dtc/dtc
	        @echo "(dtc) $(KERN_DT)"
		        $(Q)$(XVISOR_BUILD_DIR)/tools/dtc/dtc -I dts -O dtb -p 0x800 -o $@ $<
#------------------- DTB GENERATION
