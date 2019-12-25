### Filename of the goal and command used to build the goal.
# Depends on module type

# Handle invalid module types
ifeq (,$(filter $(MODULE_TYPE), executable staticlib sharedlib dllib sourcelib))
  $(info $(SOURCE_DIR)/$($(MODULE_NAME)_path)/module.mk: Invalid module type:'$(MODULE_TYPE)')
  $(error Build process aborted due to invalid module type)
endif

ifeq ($(MODULE_TYPE), executable)
  $(MODULE_NAME)_goal := $(BUILD_PATH)/$(MODULE_NAME).exe
  MINGW_DLLS = $(BUILD_PATH)/libgcc_s_dw2-1.dll $(BUILD_PATH)/libstdc++-6.dll
$(MINGW_DLLS):
	$(call fs_bs,copy "$(BABS_DIR)/platform/windows/$(@F)" "$@")
$($(MODULE_NAME)_goal): $(OBJ) $(MINGW_DLLS)
	$(call fs_bs,$(strip $(LINKEXEC_CMD)))
endif

ifeq ($(MODULE_TYPE), staticlib)
  $(MODULE_NAME)_goal := $(BUILD_PATH)/lib$(MODULE_NAME).a
$($(MODULE_NAME)_goal): $(OBJ)
	$(call fs_bs,$(STATICLIB_CMD))
endif

ifneq (,$(filter $(MODULE_TYPE),sharedlib dllib))
  SHAREDLIB_CF := 
  $(MODULE_NAME)_goal := $(BUILD_PATH)/$(MODULE_NAME).dll
  $($(MODULE_NAME)_goal): LOCAL_vmajor := $(SHAREDLIB_VMAJOR)
  $($(MODULE_NAME)_goal): LOCAL_vfull := $(SHAREDLIB_VMAJOR).$(SHAREDLIB_VMINOR).$(SHAREDLIB_VRELEASE)
$($(MODULE_NAME)_goal): $(OBJ)
	$(strip $(SHAREDLIB_CMD))
else
  SHAREDLIB_CF :=
endif

ifeq ($(MODULE_TYPE), sourcelib)
  $(MODULE_NAME)_obj := $(OBJ)
endif

