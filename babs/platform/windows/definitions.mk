# Function to convert all forward slashes in a string into backslashes
fs_bs = $(subst /,\,$1)

# Function to convert all backslashes in a string into forward slashes
bs_fs = $(subst \,/,$1)

# Replicates 'mkdir -p' behavior in Windows
define MKDIRP
  @if not exist $1 mkdir $(patsubst %\,%,$(call fs_bs,$1))
endef

PLATFORM_SHAREDLIB_CMD = $(call fs_bs,$(LINK_TOOL) $(LOCAL_lf) -shared -o $@ $(filter %.o,$^) $(LOCAL_ll))

# Default command sequence for the compilation of 1 source file
define PLATFORM_COMPILE_CPP
  $(call MKDIRP,$(dir $@))
  $(call fs_bs,$(strip $(COMPSRC_CMD_CPP)))
endef

define PLATFORM_COMPILE_C
  $(call MKDIRP,$(dir $@))
  $(call fs_bs,$(strip $(COMPSRC_CMD_C)))
endef

# 
define PLATFORM_ON_DUPLICATES
  $(info There are duplicate modules found:)
  $(foreach module, $(UNIQUE_MODULES), \
    $(if $(word 2,$(filter $(module),$(PLATFORM_MODULES))),
      $(info ) $(info $(module):) \
      $(foreach modulePath,$(filter $(module) %\$(module),$(PLATFORM_MODULE_PATHS)),$(info $(modulePath))),\
     )
   )
  $(info )
  $(error Build process aborted due to duplicate modules)
endef

#
define PLATFORM_WRITE_MODULES_MK
  $(call MKDIRP,$(dir $1))
  @echo MODULES := $(PLATFORM_MODULES)>$1
  @echo.>>$1
  $(foreach modulePath,$(PLATFORM_MODULE_PATHS),@echo $(notdir $(modulePath))_path := $(call bs_fs,$(modulePath))>>$1&)
endef

#
define PLATFORM_FIND_MODULES
  PLATFORM_MKFILES_FULLPATHS := $(shell dir /b /s $(SOURCE_DIR)\module.mk)
  $$(if $$(filter $(SOURCE_DIR)\module.mk,$$(PLATFORM_MKFILES_FULLPATHS)),\
    $$(info Found: $(SOURCE_DIR)\module.mk)\
    $$(info No module.mk file is allowed at the top level of SOURCE_DIR ($(SOURCE_DIR)))\
    $$(error Build process aborted due to out-of-place module.mk file ),)
  PLATFORM_MODULE_PATHS := $$(patsubst $(SOURCE_DIR)\\%\module.mk,%,$$(PLATFORM_MKFILES_FULLPATHS))
  PLATFORM_MODULES := $$(notdir $$(PLATFORM_MODULE_PATHS))
  UNIQUE_MODULES := $$(sort $$(PLATFORM_MODULES))
endef

# Command sequence for building modules.mk
# Find modules, check for duplicate module names, and write modules.mk if no duplicates
define PLATFORM_MAKE_MODULES_MK
  $(shell if exist $1 del /F /Q $1)
  $(eval $(call PLATFORM_FIND_MODULES))
  $(if $(filter $(words $(UNIQUE_MODULES)),$(words $(PLATFORM_MODULES))),$(call PLATFORM_WRITE_MODULES_MK,$1),$(call PLATFORM_ON_DUPLICATES))
endef

PLATFORM_SINGLEQUOTE = '

PLATFORM_GLOBALCLEAN = if exist $(BUILD_DIR) rmdir /S /Q $(BUILD_DIR)
PLATFORM_MODULE_CLEAN = if exist $(call fs_bs,$(LOCAL_buildPath)) rmdir /S /Q $(call fs_bs,$(LOCAL_buildPath))

