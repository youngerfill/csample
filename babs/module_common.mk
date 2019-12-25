# Make file fragment providing default functionality for module.mk files

# Push parent module (if any) onto dependency stack
ifneq (,$(MODULE_NAME))
  DEPENDENCY_STACK := $(MODULE_NAME) $(DEPENDENCY_STACK)
endif

### Check if module is known to babs
ifeq (,$(filter $(NEW_MODULE_NAME), $(MODULES)))
  $(info $(SOURCE_DIR)/$($(MODULE_NAME)_path)/module.mk: Unknown module: $(NEW_MODULE_NAME))
  $(error Build process aborted due to unknown module)
endif

### Set new module name
MODULE_NAME := $(NEW_MODULE_NAME)

### Check for circular dependency
ifneq (,$(filter $(MODULE_NAME),$(DEPENDENCY_STACK)))
  $(info Circular dependency detected:)
  $(info $(SOURCE_DIR)/$($(MODULE_NAME)_path)/module.mk: '$(MODULE_NAME)' is used by:        <=====)
  $(foreach module,$(DEPENDENCY_STACK),\
    $(info $(SOURCE_DIR)/$($(module)_path)/module.mk: '$(module)'\
      $(if $(filter $(lastword $(DEPENDENCY_STACK)),$(module)),,is used by:)\
      $(if $(filter $(MODULE_NAME),$(module)),        <=====,)\
     )\
   )
  $(error Build process aborted due to circular dependency)
endif

### Reset module-specific variables
MODULE_TYPE :=
DEPENDENCIES :=
STATICLIBS :=
SHAREDLIBS :=
DLLIBS :=
SOURCELIBS :=
SRC :=
SRC_CPP :=
SRC_C :=
OBJ :=
COMPFLAGS :=
COMPFLAGS_CPP :=
COMPFLAGS_C :=
#EXTRA_COMPFLAGS:=
LINKFLAGS :=
LINKLIBS :=
SHAREDLIB_VMAJOR := 1
SHAREDLIB_VMINOR := 0
SHAREDLIB_VRELEASE := 0
RUN_ARGS :=
RUN_COMMAND :=

# Directory where all target files go
BUILD_PATH := $(BUILD_DIR)/$($(MODULE_NAME)_path)

### Include makefile fragment of module, this will override some of the values of the module-specific variables
-include $(SOURCE_DIR)/$($(MODULE_NAME)_path)/module.mk

### Ensure module type is not empty
ifeq (,$(MODULE_TYPE))
  MODULE_TYPE := $(DEFAULT_MODULE_TYPE)
endif

MODULE_TYPE := $(strip $(MODULE_TYPE))

### Check if module has already been included
ifneq (,$(filter $(MODULE_NAME), $(INCLUDED_MODULES)))

### If so, check if module types are equal
ifneq ($($(MODULE_NAME)_type),$(MODULE_TYPE))
# If they are not: abort with error
  $(info Module '$(MODULE_NAME)' is being used with different module types)
  PARENT_MODULE := $(firstword $(DEPENDENCY_STACK))
  $(info $(SOURCE_DIR)/$($(PARENT_MODULE)_path)/module.mk: '$(PARENT_MODULE)' uses '$(MODULE_NAME)' as '$(MODULE_TYPE)')
  $(info $(SOURCE_DIR)/$($($(MODULE_NAME)_parent)_path)/module.mk: '$($(MODULE_NAME)_parent)' uses '$(MODULE_NAME)' as '$($(MODULE_NAME)_type)')
  $(error Build process aborted due to ambiguous module type)
endif

### Proceed to main part of .mk file only if the module hasn't been included already {
else

INCLUDED_MODULES := $(MODULE_NAME) $(INCLUDED_MODULES)
$(MODULE_NAME)_type := $(MODULE_TYPE)
(MODULE_NAME)_parent := $(firstword $(DEPENDENCY_STACK))
#$(MODULE_NAME)_runcommand := $(MODULE_RUNCOMMAND)

### Set the module-specific variables:

# The list of static libraries this module depends on
$(MODULE_NAME)_staticlibs := $(STATICLIBS) $(if $(filter staticlib,$(DEFAULT_MODULE_TYPE)),$(DEPENDENCIES),)

# The list of shared libraries this module depends on
$(MODULE_NAME)_sharedlibs := $(SHAREDLIBS) $(if $(filter sharedlib,$(DEFAULT_MODULE_TYPE)),$(DEPENDENCIES),)

# The list of DL libraries this module depends on
$(MODULE_NAME)_dllibs := $(DLLIBS) $(if $(filter dllib,$(DEFAULT_MODULE_TYPE)),$(DEPENDENCIES),)

# The list of source libraries this module depends on
$(MODULE_NAME)_sourcelibs := $(SOURCELIBS) $(if $(filter sourcelib,$(DEFAULT_MODULE_TYPE)),$(DEPENDENCIES),)

# Compilation flags in this module
ifneq (,$(COMPFLAGS))
  COMPFLAGS_CPP := $(COMPFLAGS)
  COMPFLAGS_C := $(COMPFLAGS)
endif

# Source files in this module
ifeq (,$(SRC))
  SRC_CPP := $(DEFAULT_SRC_CPP)
  SRC_C := $(DEFAULT_SRC_C)
else
  SRC_CPP := $(filter %.cpp,$(SRC))
  SRC_C := $(filter %.c,$(SRC))
endif

# Object files to make
ifeq (,$(OBJ))
  OBJ := $(DEFAULT_OBJ)
endif

### Include platform-dependent parts of rules
include $(BABS_DIR)/platform/$(PLATFORM_HOST_OS)/rules.mk

### From here on, $(MODULE_NAME)_goal has a value

### Run command of this module
# If RUN_COMMAND is non-empty then this value will be used
# and RUN_ARGS is ignored.
# Else, if RUN_ARGS is non-empty its value is used to construct
# a module-specific run command.
ifneq (,$(RUN_COMMAND))
  $(MODULE_NAME)_runcommand := $(RUN_COMMAND)
else
  ifneq (,$(RUN_ARGS))
    $(MODULE_NAME)_runcommand := $($(MODULE_NAME)_goal) $(RUN_ARGS)
  endif
endif

ifneq (,$(SHOW_INFO))
### Construct header and footer info here
$(MODULE_NAME)_goalWrapper: HEADER_CMD := @echo $(HEADER_MESSAGE)
$(MODULE_NAME)_goalWrapper: FOOTER_CMD := @echo $(FOOTER_MESSAGE)
endif

### Pattern rules for making object files from source files
$(OBJ_DIR)/%.o : LOCAL_cf_cpp := $(DEFAULT_COMPFLAGS_CPP) $(COMPFLAGS_CPP)
$(OBJ_DIR)/%.o : LOCAL_cf_c := $(DEFAULT_COMPFLAGS_C) $(COMPFLAGS_C)
$(OBJ_DIR)/%.o : $(SOURCE_DIR)/$($(MODULE_NAME)_path)/$(DEFAULT_SRCPATH)/%.cpp
	$(PLATFORM_COMPILE_CPP)
$(OBJ_DIR)/%.o : $(SOURCE_DIR)/$($(MODULE_NAME)_path)/$(DEFAULT_SRCPATH)/%.c
	$(PLATFORM_COMPILE_C)

### Include source file dependencies
-include $(OBJ:.o=.d)

# Rule for building this module by specifying its name
.PHONY: $(MODULE_NAME)
$(MODULE_NAME): $(MODULE_GOAL)

# Clean rules for this module
.PHONY:	$(MODULE_NAME)_clean
$(MODULE_NAME)_clean: LOCAL_buildPath := $(BUILD_PATH)
$(MODULE_NAME)_clean:
	$(PLATFORM_MODULE_CLEAN)

.PHONY:	$(MODULE_NAME)_cleanall
$(MODULE_NAME)_cleanall: $(MODULE_NAME)_clean $(foreach module,$(MODULE_DEPENDENCIES),$(module)_cleanall)

.PHONY:	$(MODULE_NAME)_build
$(MODULE_NAME)_build: $(MODULE_NAME)_clean $(MODULE_GOAL)

.PHONY:	$(MODULE_NAME)_buildall
$(MODULE_NAME)_buildall: $(MODULE_NAME)_cleanall $(MODULE_GOAL)

### Include dependencies
# Static libraries
$(foreach module,$($(MODULE_NAME)_staticlibs),$(eval $(call INCLUDE_DEPENDENCY,$(module),staticlib)))
# Shared libraries
$(foreach module,$($(MODULE_NAME)_sharedlibs),$(eval $(call INCLUDE_DEPENDENCY,$(module),sharedlib)))
# DL libraries
$(foreach module,$($(MODULE_NAME)_dllibs),$(eval $(call INCLUDE_DEPENDENCY,$(module),dllib)))
# Source libraries
$(foreach module,$($(MODULE_NAME)_sourcelibs),$(eval $(call INCLUDE_DEPENDENCY,$(module),sourcelib)))

# Define variables that will pass on linker options to parent modules
ifneq (,$(filter $($(MODULE_NAME)_type),staticlib sharedlib))
  $(MODULE_NAME)_def_libs_lf := $(DEFAULT_LIBS_LINKFLAGS)
  $(MODULE_NAME)_def_libs_ll := $(DEFAULT_LIBS_LINKLIBS)
endif

# Safeguard linker options into target-specific variables
ifneq (,$(filter $($(MODULE_NAME)_type),executable sharedlib dllib))
  $($(MODULE_NAME)_goal): LOCAL_lf := $(DEFAULT_LIBS_LINKFLAGS) $(LINKFLAGS)
  $($(MODULE_NAME)_goal): LOCAL_ll := $(DEFAULT_LIBS_LINKLIBS) $(LINKLIBS)
endif

# The goals of the static library modules that this module depends on
STATICLIBS_GOALS := $(foreach module,$($(MODULE_NAME)_staticlibs),$(if $(SHOW_INFO),$(module)_goalWrapper,$($(module)_goal)))

# The goals of the shared library modules that this module depends on
SHAREDLIBS_GOALS := $(foreach module,$($(MODULE_NAME)_sharedlibs),$(if $(SHOW_INFO),$(module)_goalWrapper,$($(module)_goal)))

# The goals of the DL library modules that this module depends on
DLLIBS_GOALS := $(foreach module,$($(MODULE_NAME)_dllibs),$(if $(SHOW_INFO),$(module)_goalWrapper,$($(module)_goal)))

# The objects of the source library modules that this module depends on
SOURCELIBS_OBJ := $(foreach module,$($(MODULE_NAME)_sourcelibs),$($(module)_obj))

# Add the goals of the dependencies to the prerequisites of the module goal
ifeq (,$(SHOW_INFO))
$($(MODULE_NAME)_goal) : $(STATICLIBS_GOALS) $(SHAREDLIBS_GOALS) $(DLLIBS_GOALS) $(SOURCELIBS_OBJ)
else
$(MODULE_NAME)_goalWrapper: $(MODULE_NAME)_infoheader $(STATICLIBS_GOALS) $(SHAREDLIBS_GOALS) $(DLLIBS_GOALS) $($(MODULE_NAME)_goal) $(MODULE_NAME)_infofooter
$($(MODULE_NAME)_goal): $(SOURCELIBS_OBJ)
endif

# End of main part of .mk file }
endif

# Pop the parent module from the dependency stack
ifneq (,$(strip $(DEPENDENCY_STACK)))
  MODULE_NAME := $(firstword $(DEPENDENCY_STACK))
  DEPENDENCY_STACK := $(filter-out $(MODULE_NAME),$(DEPENDENCY_STACK))
endif
