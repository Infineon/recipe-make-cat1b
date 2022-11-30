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

include $(MTB_TOOLS__RECIPE_DIR)/make/recipe/recipe_common.mk

# override the memcalc command to run its own flash calc script that prints external flash usage rather than internal.
# this must occur after including recipe_common.mk
ifneq ($(TOOLCHAIN),A_Clang)
_MTB_RECIPE__MEM_CALC=\
	bash --norc --noprofile\
	$(MTB_TOOLS__RECIPE_DIR)/make/scripts/memcalc.bash\
	$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).readelf\
	$(CY_MEMORY_EXTERNAL_FLASH)\
	$(CY_START_EXTERNAL_FLASH)
endif

# Aclang arguments must match the symbols in the PDL makefile
_MTB_RECIPE__ACLANG_POSTBUILD=\
	$(MTB_TOOLS__RECIPE_DIR)/make/scripts/m2bin \
	--verbose --vect $(VECT_BASE_CM4) --text $(TEXT_BASE_CM4) --data $(RAM_BASE_CM4) --size $(TEXT_SIZE_CM4)\
	$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).mach_o\
	$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).bin

# Transition the device to normal-non-secure. This command expect the BSP to provide variable CY_BSP_PROVISION_NORMAL_NON_SECURE_BINARIES about where the provisioning binaries blob files are located.
RECIPE_TRANSITION_NORMAL_NON_SECURE=$(CY_TOOL_openocd_EXE_ABS) -s $(CY_TOOL_openocd_scripts_SCRIPT_ABS) -c "source $(CY_TOOL_openocd_scripts_SCRIPT_ABS)/interface/kitprog3.cfg; source $(CY_TOOL_openocd_scripts_SCRIPT_ABS)/target/cyw20829.cfg; provision_no_secure $(MTB_TOOLS__RECIPE_DIR)/make/provision/cyapp_prov_oem_signed_icv0.bin  $(CY_BSP_PROVISION_NORMAL_NON_SECURE_BINARIES); exit"

RECIPE_DEVICE_TRANSITION_TARGET=recipe_device_transition
$(RECIPE_DEVICE_TRANSITION_TARGET):
ifneq (,$(CY_BSP_PROVISION_NORMAL_NON_SECURE_BINARIES))
	$(if $(findstring normal-non-secure,$(findstring $(DEVICE_MODE),normal-non-secure)),$(RECIPE_TRANSITION_NORMAL_NON_SECURE),$(error The only supported DEVICE_MODE for $(DEVICE) is 'normal-non-secure'))
else
	$(error Missing BSP provision transition files.)
endif

ifeq (CYW20829,$(_MTB_RECIPE__DEVICE_DIE))

ifeq ($(APPTYPE),flash)
MTB_RECIPE__DEFINES+=-DFLASH_BOOT -DCY_PDL_FLASH_BOOT
endif

ifeq ($(TOOLCHAIN),ARM)
_MTB_RECIPE__MXSV2_POSTBUILD+=$(MTB_TOOLCHAIN_ARM__BASE_DIR)/bin/fromelf $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).elf --bin --output=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).bin;
else ifeq ($(TOOLCHAIN),IAR)
ifeq ($(APPTYPE),flash)
_MTB_RECIPE_20829_POSTBUILD_PARAM=--bin-multi
else
_MTB_RECIPE_20829_POSTBUILD_PARAM=--bin
endif
_MTB_RECIPE__MXSV2_POSTBUILD+=$(MTB_TOOLCHAIN_IAR__BASE_DIR)/bin/ielftool $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).elf $(_MTB_RECIPE_20829_POSTBUILD_PARAM) $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).bin; \
					$(MTB_TOOLCHAIN_IAR__BASE_DIR)/bin/ielfdumparm  -a $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).elf > $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).dis;

else ifeq ($(TOOLCHAIN),GCC_ARM)
_MTB_RECIPE__MXSV2_POSTBUILD+=$(MTB_TOOLCHAIN_GCC_ARM__ELF2BIN) $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).elf -S -O binary $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).bin;
endif

# Python required below
CY_PYTHON_REQUIREMENT=true

# Postbuilds for l1ram and flash applications for second stage
ifeq ($(APPTYPE),$(filter $(APPTYPE),l1ram flash))
ifeq ($(CY_SECONDSTAGE),true)

ifeq ($(wildcard $(CY_TOOL_python_EXE_ABS)),)
ifneq ($(_MTB_TOOLS__WHICH_CYGPATH),)
_MTB_RECIPE_20829_PYTHON_EXE_PATH=$(call mtb__get_dir,$(shell cygpath -m --absolute $$(which python)))
else
_MTB_RECIPE_20829_PYTHON_EXE_PATH=$(call mtb__get_dir,$(shell which python))
endif
else
_MTB_RECIPE_20829_PYTHON_EXE_PATH=$(call mtb__get_dir,$(CY_PYTHON_PATH))
endif

_MTB_RECIPE_20829_PYTHON_BIN2HEX_PATH=$(strip $(call mtb__get_file_path,,bin2hex.py,bin2hex.py))
_MTB_RECIPE_20829_PYTHON_SCRIPT_PATH=$(call mtb__get_dir,$(_MTB_RECIPE_20829_PYTHON_BIN2HEX_PATH))

ifeq ($(_MTB_RECIPE_20829_PYTHON_BIN2HEX_PATH),)
CY_MESSAGE_bin2hex="bin2hex.py" could not be found.\
	This is needed to finish running the postbuild steps. Ensure that the module is present to\
	complete the build for this app. The rest of the postbuild steps will now be skipped.
$(eval $(call CY_MACRO_WARNING,CY_MESSAGE_bin2hex,$(CY_MESSAGE_bin2hex)))
else
ifeq ($(APPTYPE),flash)
_MTB_RECIPE__MXSV2_POSTBUILD+=$(MTB_TOOLS__BASH_CMD) $(MTB_TOOLS__RECIPE_DIR)/make/scripts/20829/flash_postbuild.sh "$(TOOLCHAIN)" "$(MTB_TOOLS__OUTPUT_CONFIG_DIR)" "$(APPNAME)" "$(CY_PYTHON_PATH)" "$(_MTB_RECIPE_20829_PYTHON_SCRIPT_PATH)" "$(MTB_TOOLCHAIN_GCC_ARM__BASE_DIR)/bin";
endif

APP_SLOT_SIZE?= 0x20000
APP_ENCRYPTION?= 0

_MTB_RECIPE__MXSV2_POSTBUILD+=$(MTB_TOOLS__BASH_CMD) $(MTB_TOOLS__RECIPE_DIR)/make/scripts/20829/run_toc2_generator.sh "$(APP_SECURITY_TYPE)" "$(MTB_TOOLS__OUTPUT_CONFIG_DIR)" "$(APPNAME)" "$(APPTYPE)" "$(MTB_TOOLS__TARGET_DIR)" "NONE" "$(MTB_TOOLCHAIN_GCC_ARM__BASE_DIR)" "" $(APP_SLOT_SIZE) $(APP_ENCRYPTION) "";
_MTB_RECIPE__MXSV2_POSTBUILD+=$(CY_PYTHON_PATH) $(_MTB_RECIPE_20829_PYTHON_BIN2HEX_PATH) --offset=0x60000000 $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).final.bin $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).final.hex;
_MTB_RECIPE__MXSV2_POSTBUILD+=rm -rf $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).bin;
endif #($(_MTB_RECIPE_20829_PYTHON_SCRIPT_PATH),)

endif
endif # apptype l1ram flash

endif #(CYW20829,$(_MTB_RECIPE__DEVICE_DIE))

recipe_postbuild:
	$(_MTB_RECIPE__MXSV2_POSTBUILD)
