BUILDDIR=build/
CONF=$(BUILDDIR)/.env_config
include $(CONF)
include $(MAKEDIR)/common.mk

# Remove the double quotes from COMPONENTS value, which are interpreted as is
# by the Makefile
COMPONENTS:=$(shell echo $(COMPONENTS))


.DEFAULT_GOAL=all


# Generate the preparation rules for each component, depending on the fetching
# method (git repository cloning or archive download)
$(foreach component,$(COMPONENTS),$(eval $(call PREPARE_RULE,$(component))))

# The prepare rule depend on each component path to be ready
prepare: $(foreach component,$(COMPONENTS),$(BUILDDIR)/$($(component)_PATH))

compile: prepare
	@echo "$@ for $(BOARD)"

run: compile
	@echo "$@ for $(BOARD)"

clean:
	$(Q)find . -name "*~" -delete

distclean:
	$(Q)rm -rf $(BUILDDIR)
