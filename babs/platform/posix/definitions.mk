
PLATFORM_SHAREDLIB_CMD = $(LINK_TOOL) -shared -Wl,-soname,$@.$(LOCAL_vmajor) -o $@.$(LOCAL_vfull) $(filter %.o,$^);\
                ln -sf $@.$(LOCAL_vfull) $@;ln -sf $@.$(LOCAL_vfull) $@.$(LOCAL_vmajor)

# Default command sequence for the compilation of 1 source file
define PLATFORM_COMPILE_CPP
  @mkdir -p $(dir $@)
  $(strip $(COMPSRC_CMD_CPP))
endef

define PLATFORM_COMPILE_C
  @mkdir -p $(dir $@)
  $(strip $(COMPSRC_CMD_C))
endef

# 
define PLATFORM_ON_DUPLICATES
  $(info There are duplicate modules found:)
  $(foreach module, $(UNIQUE_MODULES), \
    $(if $(word 2,$(filter $(module),$(PLATFORM_MODULES))),
      $(info ) $(info $(module):) \
      $(foreach modulePath,$(filter $(module) %/$(module),$(PLATFORM_MODULE_PATHS)),$(info $(modulePath))),\
     )
   )
  $(info )
  $(error Build process aborted due to duplicate modules)
endef

#
define PLATFORM_WRITE_MODULES_MK
  @mkdir -p $(dir $1)
  @echo MODULES := $(PLATFORM_MODULES)>$1
  @echo>>$1
  @$(foreach modulePath,$(PLATFORM_MODULE_PATHS),echo $(notdir $(modulePath))_path := $(modulePath)>>$1;)
endef

# previous command:
#  PLATFORM_MKFILES_FULLPATHS := $(shell find $(SOURCE_DIR) -name module.mk)
define PLATFORM_FIND_MODULES
  PLATFORM_MKFILES_FULLPATHS := $(shell grep -rl babsmakefile $(SOURCE_DIR))
  $$(if $$(filter $(SOURCE_DIR)/Makefile,$$(PLATFORM_MKFILES_FULLPATHS)),\
    $$(info Found: $(SOURCE_DIR)/Makefile)\
    $$(info No Makefile file is allowed at the top level of SOURCE_DIR ($(SOURCE_DIR)))\
    $$(error Build process aborted due to out-of-place Makefile file ),)
  PLATFORM_MODULE_PATHS := $$(patsubst $(SOURCE_DIR)/%/Makefile,%,$$(PLATFORM_MKFILES_FULLPATHS))
  PLATFORM_MODULES := $$(notdir $$(PLATFORM_MODULE_PATHS))
  UNIQUE_MODULES := $$(sort $$(PLATFORM_MODULES))
endef

# Command sequence for building modules.mk
# Find modules, check for duplicate module names, and write modules.mk if no duplicates
define PLATFORM_MAKE_MODULES_MK
  $(shell rm -f $1)
  $(eval $(call PLATFORM_FIND_MODULES))
  $(if $(filter $(words $(UNIQUE_MODULES)),$(words $(PLATFORM_MODULES))),$(call PLATFORM_WRITE_MODULES_MK,$1),$(call PLATFORM_ON_DUPLICATES))
endef

PLATFORM_SINGLEQUOTE = \'

PLATFORM_GLOBALCLEAN = rm -rf  $(BUILD_DIR)
PLATFORM_MODULE_CLEAN = rm -rf $(LOCAL_buildPath)


