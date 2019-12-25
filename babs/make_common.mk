# Makefile fragment for babs build system

# clear out all suffixes
.SUFFIXES:

# Abort if any of the key env vars is empty
ifeq (,$(SOURCE_DIR))
$(error Variable SOURCE_DIR is empty)
endif
ifeq (,$(BUILD_DIR))
$(error Variable BUILD_DIR is empty)
endif
ifeq (,$(BABS_DIR))
$(error Variable BABS_DIR is empty)
endif

# Determine the top-level module name from the parent Makefile's path
NEW_MODULE_NAME := $(notdir $(patsubst %/,%,$(dir $(abspath $(word $(words $(MAKEFILE_LIST)),x x $(MAKEFILE_LIST))))))
ifeq (,$(NEW_MODULE_NAME))
  $(error Variable NEW_MODULE_NAME is empty)
endif

# Include platform-specific code
include $(BABS_DIR)/platform/platform.mk

# Include the list of modules, if any
-include $(BUILD_DIR)/modules.mk

# Proceed to main part of this .mk file only if modules.mk successfully included
# and if the user didn't intend to remake modules.mk     {
ifneq (,$(MODULES))
ifneq (scanmodules,$(filter scanmodules,$(MAKECMDGOALS)))

# Build flags
DEP_FLAGS = -MMD -MP -MT $@ -MT $(@:.o=.d)
COMMON_COMP_FLAGS_CPP = -g -Wall
COMMON_COMP_FLAGS_C = -g -Wall
#COMMON_COMP_FLAGS_CPP = -g -Wall -k
#COMMON_COMP_FLAGS_C = -g -Wall -k
#COMP_FLAGS =  -Iinc -Wall -DNDEBUG
#COMMON_LINK_FLAGS = $(DEFAULT_LIBS_LINKFLAGS) $(LOCAL_lf)
#COMMON_LINK_LIBS = $(DEFAULT_LIBS_LINKLIBS) $(LOCAL_ll)

# Build tools
COMP_TOOL_CPP = gcc
COMP_TOOL_C = gcc
LINK_TOOL = g++

# Build commands
COMPSRC_CMD_CPP = $(COMP_TOOL_CPP) $(DEP_FLAGS) $(COMMON_COMP_FLAGS_CPP) $(LOCAL_cf_cpp) -o $@ -c $<
COMPSRC_CMD_C = $(COMP_TOOL_C) $(DEP_FLAGS) $(COMMON_COMP_FLAGS_C) $(LOCAL_cf_c) -o $@ -c $<
LINKEXEC_CMD = $(LINK_TOOL) $(LOCAL_lf) -o $@ $(filter %.o,$^) $(LOCAL_ll)
STATICLIB_CMD = ar rcs $@ $(filter %.o,$?)
SHAREDLIB_CMD = $(PLATFORM_SHAREDLIB_CMD)

# Directory where object files will be written (module specific)
OBJ_DIR = $(BUILD_PATH)/$(DEFAULT_SRCPATH)

# Shorthand for all dependencies of a given module
MODULE_DEPENDENCIES = $($(MODULE_NAME)_staticlibs) $($(MODULE_NAME)_sharedlibs) $($(MODULE_NAME)_dllibs) $($(MODULE_NAME)_sourcelibs)

# Shorthand for the module's goal
MODULE_GOAL = $(if $(SHOW_INFO),$(MODULE_NAME)_goalWrapper,$($(MODULE_NAME)_goal))

# The command to run when the run target is invoked at the command line
MODULE_RUNCOMMAND = $(if $($(MODULE_NAME)_runcommand),$($(MODULE_NAME)_runcommand),$($(MODULE_NAME)_goal))

# Default relative path to source subfolder in module
DEFAULT_SRCPATH = src
DEFAULT_SRCDIR = $(SOURCE_DIR)/$($(MODULE_NAME)_path)/$(DEFAULT_SRCPATH)
# Default method for finding source files
DEFAULT_SRC_CPP = $(wildcard $(DEFAULT_SRCDIR)/*.cpp)
DEFAULT_SRC_C = $(wildcard $(DEFAULT_SRCDIR)/*.c)

DEFAULT_DEPENDENCIES_COMPFLAGS = $(foreach lib_name,$($(MODULE_NAME)_staticlibs) $($(MODULE_NAME)_sharedlibs) $($(MODULE_NAME)_dllibs) $($(MODULE_NAME)_sourcelibs),-I$(SOURCE_DIR)/$($(lib_name)_path))
DEFAULT_COMPFLAGS_CPP = $(SHAREDLIB_CF) -I$(SOURCE_DIR)/$($(MODULE_NAME)_path)/$(MODULE_NAME) $(DEFAULT_DEPENDENCIES_COMPFLAGS)
DEFAULT_COMPFLAGS_C = $(SHAREDLIB_CF) -I$(SOURCE_DIR)/$($(MODULE_NAME)_path)/$(MODULE_NAME) $(DEFAULT_DEPENDENCIES_COMPFLAGS)
DEFAULT_LIBS_LINKFLAGS = $(foreach lib_name,$($(MODULE_NAME)_staticlibs) $($(MODULE_NAME)_sharedlibs),-L$(BUILD_DIR)/$($(lib_name)_path) $($(lib_name)_def_libs_lf))
DEFAULT_LIBS_LINKLIBS = $(foreach lib_name,$($(MODULE_NAME)_staticlibs) $($(MODULE_NAME)_sharedlibs),-l$(lib_name) $($(lib_name)_def_libs_ll))

# Default method for obtaining object filenames from source filenames
DEFAULT_OBJ = \
	$(patsubst $(DEFAULT_SRCDIR)/%.cpp,$(BUILD_PATH)/$(DEFAULT_SRCPATH)/%.o, $(SRC_CPP)) \
	$(patsubst $(DEFAULT_SRCDIR)/%.c,$(BUILD_PATH)/$(DEFAULT_SRCPATH)/%.o, $(SRC_C))

# Default module type, to be used when no module type is explicitly given
DEFAULT_MODULE_TYPE := executable

# Variables related to info messages
SHOW_INFO :=
HEADER_MESSAGE = ---------- Making module $(PLATFORM_SINGLEQUOTE)$(MODULE_NAME)$(PLATFORM_SINGLEQUOTE) ----------
FOOTER_MESSAGE = ---------- Module $(PLATFORM_SINGLEQUOTE)$(MODULE_NAME)$(PLATFORM_SINGLEQUOTE) done. ----------

# Function to include dependency module and set right goal type
define INCLUDE_DEPENDENCY
  NEW_MODULE_NAME := $1
  MODULE_TYPE := $2
  include $(BABS_DIR)/module_common.mk
endef

# Include global configuration file (if any)
-include $(SOURCE_DIR)/config.mk

# Include makefile code for the top-level module and all its dependencies
include $(BABS_DIR)/module_common.mk
.DEFAULT_GOAL := $(MODULE_GOAL)

.PHONY: clean
clean : $(MODULE_NAME)_clean

.PHONY: cleanall
cleanall : $(MODULE_NAME)_cleanall

.PHONY: globalclean
globalclean :
	$(PLATFORM_GLOBALCLEAN)

.PHONY: build
build: clean $(.DEFAULT_GOAL)

.PHONY: buildall
buildall : cleanall $(.DEFAULT_GOAL)

ifeq (executable,$(strip $($(MODULE_NAME)_type)))
.PHONY: run
run: $(.DEFAULT_GOAL)
	$(MODULE_RUNCOMMAND)
#	echo $(BUILD_DIR)/$($(MODULE_NAME)_path)
#	echo $($(MODULE_NAME)_goal)
else
.PHONY: run
run:
	@echo "Error: cannot run. MODULE_TYPE of this module equals: '$(strip $($(MODULE_NAME)_type))'"
endif

ifneq (,$(SHOW_INFO))
.PHONY: $(addsuffix _infoheader,MODULES)
%_infoheader:
	$(HEADER_CMD)

.PHONY: $(addsuffix _infofooter,MODULES)
%_infofooter:
	$(FOOTER_CMD)
endif

# End of main part that depends on successful inclusion of modules.mk
endif
endif
# }

$(BUILD_DIR)/modules.mk:
	$(call PLATFORM_MAKE_MODULES_MK,$@)

.PHONY: scanmodules
scanmodules :
	$(call PLATFORM_MAKE_MODULES_MK,$(BUILD_DIR)/modules.mk)
