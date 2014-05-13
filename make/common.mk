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
  MAKEFLAGS += -j5 --no-print-directory
endif

define COPY
        @echo "(copy) $@"
        $(Q)mkdir -p $(@D)
        $(Q)cp -f $< $@
endef
