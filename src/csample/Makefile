# babsmakefile

# Walk up the dir tree to find SETENVFILE
# Adapted from "The GNU Make Book" by John Graham-Cumming (https://www.nostarch.com/gnumake)
sp :=
sp +=
_walk = $(if $1,$(wildcard /$(subst $(sp),/,$1)/$2) $(call _walk,$(wordlist 2,$(words $1),x $1),$2))
_find = $(firstword $(call _walk,$(strip $(subst /, ,$1)),$2))

SETENVFILE:=setenv.mk
PROJECT_ROOT := $(patsubst %/$(SETENVFILE),%,$(call _find,$(CURDIR),$(SETENVFILE)))

ifneq (,$(ComSpec)$(COMSPEC))
  HOME := $(HOMEPATH)
endif

ifneq (,$(PROJECT_ROOT))
  include $(PROJECT_ROOT)/$(SETENVFILE)
else
  $(error Could not find $(SETENVFILE))
endif

include $(BABS_DIR)/make_common.mk
