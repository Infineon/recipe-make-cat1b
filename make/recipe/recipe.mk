################################################################################
# \file recipe.mk
#
# \brief
# Set up a set of defines, includes, software components, linker script,
# Pre and Post build steps and call a macro to create a specific ELF file.
#
################################################################################
# \copyright
# Copyright 2018-2021 Cypress Semiconductor Corporation
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

ifeq ($(WHICHFILE),true)
$(info Processing $(lastword $(MAKEFILE_LIST)))
endif

include $(CY_INTERNAL_BASELIB_PATH)/make/recipe/recipe_common.mk

# override the memcalc command to run its own flash calc script that prints external flash usage rather than internal.
# this must occur after including recipe_common.mk
ifneq ($(TOOLCHAIN),A_Clang)
CY_MEM_CALC=\
	bash --norc --noprofile\
	$(CY_INTERNAL_BASELIB_PATH)/make/scripts/memcalc.bash\
	$(CY_CONFIG_DIR)/$(APPNAME).readelf\
	$(CY_MEMORY_SRAM)\
	$(CY_START_SRAM)\
	$(CY_MEMORY_EXTERNAL_FLASH)\
	$(CY_START_EXTERNAL_FLASH)
endif

#
# linker script construction
#
ifeq ($(LINKER_SCRIPT),)
LINKER_SCRIPT=$(CY_TARGET_DIR)/TOOLCHAIN_$(TOOLCHAIN)/$(CY_LINKER_SCRIPT_NAME).$(CY_TOOLCHAIN_SUFFIX_LS)
endif

ifeq ($(wildcard $(LINKER_SCRIPT)),)
$(call CY_MACRO_ERROR,The specified linker script could not be found at "$(LINKER_SCRIPT)")
endif

ifeq ($(TOOLCHAIN),A_Clang)
include $(LINKER_SCRIPT)
else
CY_RECIPE_LSFLAG=$(CY_TOOLCHAIN_LSFLAGS)$(LINKER_SCRIPT)
endif

# Aclang arguments must match the symbols in the PDL makefile
CY_RECIPE_ACLANG_POSTBUILD=\
	$(CY_TOOLCHAIN_M2BIN)\
	--verbose --vect $(VECT_BASE_CM4) --text $(TEXT_BASE_CM4) --data $(RAM_BASE_CM4) --size $(TEXT_SIZE_CM4)\
	$(CY_CONFIG_DIR)/$(APPNAME).mach_o\
	$(CY_CONFIG_DIR)/$(APPNAME).bin

# Transition the device to normal-non-secure. This command expect the BSP to provide variable CY_BSP_PROVISION_NORMAL_NON_SECURE_BINARIES about where the provisioning binaries blob files are located.
RECIPE_TRANSITION_NORMAL_NON_SECURE=$(CY_INTERNAL_TOOL_openocd_EXE) -s $(CY_INTERNAL_TOOL_openocd_scripts_SCRIPT) -c "source $(CY_INTERNAL_TOOL_openocd_scripts_SCRIPT)/interface/kitprog3.cfg; source $(CY_INTERNAL_TOOL_openocd_scripts_SCRIPT)/target/cyw20829.cfg; provision_no_secure $(CY_INTERNAL_BASELIB_PATH)/make/provision/cyapp_prov_oem_signed_icv0.bin  $(CY_BSP_PROVISION_NORMAL_NON_SECURE_BINARIES); exit"

RECIPE_DEVICE_TRANSITION_TARGET=recipe_device_transition
$(RECIPE_DEVICE_TRANSITION_TARGET):
ifneq (,$(CY_BSP_PROVISION_NORMAL_NON_SECURE_BINARIES))
	$(if $(findstring normal-non-secure,$(findstring $(DEVICE_MODE),normal-non-secure)),$(RECIPE_TRANSITION_NORMAL_NON_SECURE),$(error The only supported DEVICE_MODE for $(DEVICE) is 'normal-non-secure'))
else
	$(error Missing BSP provision transition files.)
endif

ifneq ($(filter $(DEVICE),$(CY_DEVICES_WITH_DIE_CYW20829)),)

ifeq ($(APPTYPE),flash)
DEFINES+=FLASH_BOOT
endif

# Add ; to end existing postbuild command from recipe_common.mk
CY_RECIPE_POSTBUILD+=;

ifeq ($(TOOLCHAIN),ARM)
CY_RECIPE_POSTBUILD+=$(CY_CROSSPATH)/bin/fromelf "$(CY_CONFIG_DIR)/$(APPNAME).elf" --bin --output="$(CY_CONFIG_DIR)/$(APPNAME).bin";

else ifeq ($(TOOLCHAIN),IAR)
ifeq ($(APPTYPE),flash)
_MTB_RECIPE_20829_POSTBUILD_PARAM=--bin-multi
else
_MTB_RECIPE_20829_POSTBUILD_PARAM=--bin
endif
CY_RECIPE_POSTBUILD+="$(CY_CROSSPATH)/bin/ielftool" "$(CY_CONFIG_DIR)/$(APPNAME).elf" $(_MTB_RECIPE_20829_POSTBUILD_PARAM) "$(CY_CONFIG_DIR)/$(APPNAME).bin"; \
					"$(CY_CROSSPATH)/bin/ielfdumparm"  -a "$(CY_CONFIG_DIR)/$(APPNAME).elf" >  "$(CY_CONFIG_DIR)/$(APPNAME).dis";

else ifeq ($(TOOLCHAIN),GCC_ARM)
CY_RECIPE_POSTBUILD+="$(CY_TOOLCHAIN_ELF2BIN)" "$(CY_CONFIG_DIR)/$(APPNAME).elf" -S -O binary "$(CY_CONFIG_DIR)/$(APPNAME).bin";
endif

# Python required below
CY_PYTHON_REQUIREMENT=true

# Postbuilds for l1ram and flash applications for second stage
ifeq ($(APPTYPE),$(filter $(APPTYPE),l1ram flash))
ifeq ($(CY_SECONDSTAGE),true)

ifeq ($(wildcard $(CY_INTERNAL_TOOL_python_EXE)),)
ifneq ($(CY_WHICH_CYGPATH),)
_MTB_RECIPE_20829_PYTHON_EXE_PATH=$(call CY_MACRO_DIR,$(shell cygpath -m --absolute $$(which python)))
else
_MTB_RECIPE_20829_PYTHON_EXE_PATH=$(call CY_MACRO_DIR,$(shell which python))
endif
else
_MTB_RECIPE_20829_PYTHON_EXE_PATH=$(call CY_MACRO_DIR,$(CY_PYTHON_PATH))
endif

_MTB_RECIPE_20829_PYTHON_BIN2HEX_PATH=$(strip $(call CY_MACRO_SEARCH,bin2hex.py,$(_MTB_RECIPE_20829_PYTHON_EXE_PATH)))
_MTB_RECIPE_20829_PYTHON_SCRIPT_PATH=$(call CY_MACRO_DIR,$(_MTB_RECIPE_20829_PYTHON_BIN2HEX_PATH))

ifeq ($(_MTB_RECIPE_20829_PYTHON_BIN2HEX_PATH),)
CY_MESSAGE_bin2hex="bin2hex.py" could not be found.\
	This is needed to finish running the postbuild steps. Ensure that the module is present to\
	complete the build for this app. The rest of the postbuild steps will now be skipped.
$(eval $(call CY_MACRO_WARNING,CY_MESSAGE_bin2hex,$(CY_MESSAGE_bin2hex)))
else
ifeq ($(APPTYPE),flash)
CY_RECIPE_POSTBUILD+=$(CY_BASH) $(CY_INTERNAL_BASELIB_PATH)/make/scripts/20829/flash_postbuild.sh "$(TOOLCHAIN)" "$(CY_CONFIG_DIR)" "$(APPNAME)" "$(CY_PYTHON_PATH)" "$(_MTB_RECIPE_20829_PYTHON_SCRIPT_PATH)" "$(CY_COMPILER_GCC_ARM_DIR)/bin";
endif

APP_SLOT_SIZE?= 0x20000
APP_ENCRYPTION?= 0

CY_RECIPE_POSTBUILD+=$(CY_BASH) $(CY_INTERNAL_BASELIB_PATH)/make/scripts/20829/run_toc2_generator.sh "$(APP_SECURITY_TYPE)" "$(CY_CONFIG_DIR)" "$(APPNAME)" "$(APPTYPE)" "$(CY_TARGET_DIR)" "NONE" "$(CY_COMPILER_GCC_ARM_DIR)" "" $(APP_SLOT_SIZE) $(APP_ENCRYPTION) "";
CY_RECIPE_POSTBUILD+=$(CY_PYTHON_PATH) $(_MTB_RECIPE_20829_PYTHON_BIN2HEX_PATH) --offset=0x60000000 $(CY_CONFIG_DIR)/$(APPNAME).final.bin $(CY_CONFIG_DIR)/$(APPNAME).final.hex;
CY_RECIPE_POSTBUILD+=rm -rf $(CY_CONFIG_DIR)/$(APPNAME).bin;
endif #($(_MTB_RECIPE_20829_PYTHON_SCRIPT_PATH),)

endif
endif # apptype l1ram flash

endif #($(filter $(DEVICE),$(CY_DEVICES_WITH_DIE_CYW20829)),)
