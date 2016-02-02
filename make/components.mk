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
# @file make/components.mk
#

# Remove the double quotes from COMPONENTS value, which are interpreted as is
# by the Makefile
COMPONENTS:=$(shell echo $(COMPONENTS))

#
# Fetch rule for each component, i.e. the step to get the component sources
# $1: The component name (TOOLCHAIN, LINUX, ...)
#
define FETCH_RULE
 ifneq ($($1_LOCAL),)
$(BUILDDIR)/$($1_PATH): $($1_LOCAL)
	@echo "(Link) $$@"
	$(Q)ln -s $$^ $$@

 else #  $($1_LOCAL) empty or unset

  # This rule only exists for archived components (i.e. the kernel)
  ifeq ($($1_REPO),)
	    # The component server and file must be set
  endif # !$1_REPO

  # Check if the component repo repository is defined
  ifneq ($($1_GREPO),)
$(BUILDDIR)/$($1_PATH):
	@echo "(Repo clone) $$@"
	mkdir -p $$@; cd $$@; $(SCRIPTDIR)/repo init -u $$($1_GREPO) -b $$($1_BRANCH); $(SCRIPTDIR)/repo sync -c -q -f
  # Check if the component git repository is defined
  else
    ifneq ($($1_REPO),)
$(BUILDDIR)/$($1_PATH):
	@echo "(Clone) $$@"
	$(Q)git clone $$($1_REPO_ARG) -q $$($1_REPO) -b $$($1_BRANCH) $$@

  # The component is not fetch with a git repository
    else # $($1_REPO) empty or unset

      # Check if the component can be downloaded
      ifneq ($($1_SERVER),)
        ifneq ($($1_FILE),)
$(ARCDIR)/$($1_FILE): | $(TMPDIR)
	@echo "(Download) $$(@F)"
	$(Q)wget --no-check-certificate --no-verbose $($1_SERVER)/$$(@F) -O $(TMPDIR)/$$(@F)
	$(Q)mkdir -p $$(@D)
	$(Q)mv $(TMPDIR)/$$(@F) $$@

$(BUILDDIR)/$($1_PATH): $(ARCDIR)/$($1_FILE) | ${TMPDIR}
	@echo "(Decompress) $$(<F)"
        # Extraction depend on the suffix, and extract in a temporary directory
        # first, in case of interruption
        ifeq ($(suffix $($1_FILE)),.zip)
        # Extract it quietly, without keeping timestamps
	$(Q)unzip -qDx $$< -d $(TMPDIR)
        else # $1_FILE suffix is not .zip
	$(Q)tar mxf $$< -C $(TMPDIR)
        endif # $1_FILE suffix
	$(Q)mv $(TMPDIR)/$$(@F) $$@

      else
      # $1_FILE has been set, we cannot fetch the component
$(BUILDDIR)/$($1_PATH):
	@echo "$1 file has not been set, exiting..."
	$(Q)exit 1
      endif # $1_FILE

    # Nor $1_SERVER nor $1_REPO has been set, we cannot fetch the component
    else # $1_SERVER empty or unset
$(BUILDDIR)/.$($1_PATH):
	@echo "$1 server or repository has not been set, exiting... "
	$(Q)exit 1
    endif # $1_SERVER
  endif # $1_REPO
  endif # $1_GREPO
 endif # $1_LOCAL
endef


#
# Patch rule for each component, i.e. the step to patch the component name
# if necessary
# $1: The component name (TOOLCHAIN, LINUX, ...)
#
define PATCH_RULE
 $(STAMPDIR)/.$1_patch: $(wildcard $(PATCHDIR)/$($1_PATH)) | $($1_DIR) \
  $(STAMPDIR)
	@echo "(Patching) $($1_PATH)"
	$(Q)[ -d $(PATCHDIR)/$($1_PATH) ] && (cd $($1_DIR) &&		\
	  for patchfile in						\
	  $$$$(echo "$(PATCHDIR)/$($1_PATH)/*.patch"); do		\
		patch -p1 < $$$${patchfile} &&				\
		  echo $$$${patchfile} >> $$@;				\
	  done) || touch $$@
endef


$(foreach component,$(COMPONENTS),\
  $(eval $(component)-fetch: $($1_DIR)))

$(foreach component,$(COMPONENTS),\
  $(eval $(component)-prepare: $(STAMPDIR)/.$(component)_patch))

.PHONY: $(foreach component,$(COMPONENTS),$(component)-fetch \
  $(component)-prepare)

# Generate the preparation rules for each component, depending on the fetching
# method (git repository cloning or archive download) and patching
$(foreach component,$(COMPONENTS),$(eval $(call FETCH_RULE,$(component))))
$(foreach component,$(COMPONENTS),$(eval $(call PATCH_RULE,$(component))))
