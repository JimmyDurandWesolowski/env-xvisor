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
