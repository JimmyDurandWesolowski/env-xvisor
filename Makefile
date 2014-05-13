BUILDDIR=build/
include $(BUILDDIR)/.env_config
include $(MAKEDIR)/common.mk


.DEFAULT_GOAL=all

%-prepare:
	${Q}VAR=$(subst -prepare,,$@); echo $$VAR

prepare: $(foreach component,$(COMPONENTS),$(component)-prepare)

compile: prepare
	@echo "$@ for $(BOARD)"

run: compile
	@echo "$@ for $(BOARD)"
