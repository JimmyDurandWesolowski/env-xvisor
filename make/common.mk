ifneq (V,)
  BUILD_VERBOSE = $(V)
endif

ifndef BUILD_VERBOSE
  BUILD_VERBOSE = 0
endif

ifeq ($(BUILD_VERBOSE),1)
  Q =
else
  Q = @
endif


ifneq (D,)
  BUILD_DEBUG = $(D)
endif

ifndef BUILD_DEBUG
  BUILD_DEBUG = 0
endif

# ifneq ($(BUILD_DEBUG),1)
#   MAKEFLAGS += -j5 --no-print-directory
# endif

define COPY
        @echo "(copy) $@"
        $(Q)mkdir -p $(@D)
        $(Q)cp -f $< $@
endef


$(ARC_DIR)/%:
	@printf "[Download]\t$(@F)\n"
	$(Q)mkdir -p $(@D)
	$(Q)wget $(FILE_SERVER)/$(@F) -O $@


#
# Prepare rule for each component, i.e. the step to get the component sources
# $1: The component name (TOOLCHAIN, LINUX, ...)
#
define PREPARE_RULE
  # Check if the component git repository is defined
  ifneq ($($1_REPO),)
$(BUILDDIR)/$($1_PATH):
	@printf "[Clone]\t$$@\n"
	$(Q)git clone $$($1_REPO) $$@

  # The component is not fetch with a git repository
  else # $($1_REPO) empty or unset

    # Check if the component can be downloaded
    ifneq ($($1_FILE),)
$(BUILDDIR)/$($1_PATH): $(ARC_DIR)/$($1_FILE)
	@printf "[Decompress]\t$$(<F)\n"

      # If the downloaded file is a ZIP archive
      ifeq ($(suffix $($1_FILE)),.zip)
	$(Q)unzip -qx $$< -d $$(@D)

      # Otherwise consider it as a TAR archive
      else # $1_FILE suffix is not .zip
	$(Q)tar xf $$< -C $$(@D)
      endif # $1_FILE suffix

    # Nor $1_FILE nor $1_REPO has been set, we cannot fetch the component
    else # $1_FILE empty or unset
$(BUILDDIR)/$($1_PATH): $(ARC_DIR)/$($1_FILE)
	@printf $1 file or repository has not been set, exiting...
	$(Q)exit 1
    endif # $1_FILE
  endif # $1_REPO
endef
