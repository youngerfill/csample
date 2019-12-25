ifneq (,$(ComSpec)$(COMSPEC))
  PLATFORM_HOST_OS := windows
else
  PLATFORM_HOST_OS := posix
endif

include $(BABS_DIR)/platform/$(PLATFORM_HOST_OS)/definitions.mk

