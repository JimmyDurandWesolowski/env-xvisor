ifneq (V,)
  BUILD_VERBOSE = $(V)
  # Ensure compatibility with 
  VB=$(V)
  undefine V
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

ifneq ($(BUILD_DEBUG),1)
  MAKEFLAGS += --no-print-directory

  ifneq ($(PARALLEL_JOBS),)
    MAKEFLAGS += -j$(PARALLEL_JOBS)
  endif
endif

define COPY
        @echo "(copy) $@"
        $(Q)mkdir -p $(@D)
        $(Q)cp -f $< $@
endef


$(TMPDIR) $(STAMPDIR):
	$(Q)mkdir -p $@

define FILE_SIZE
	printf "0x%X\n" $(shell stat -c "%s" $1)
endef

define DIR_SIZE
	$(shell du -b --max-depth=0 $1 | cut -f 1)
endef
