################################################################################
# \file recipe.mk
#
# \brief
# Set up a set of defines, includes, software components, linker script,
# Pre and Post build steps and call a macro to create a specific ELF file.
#
################################################################################
# \copyright
# (c) 2018-2025, Cypress Semiconductor Corporation (an Infineon company)
# or an affiliate of Cypress Semiconductor Corporation.  All rights reserved.
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

include $(MTB_TOOLS__RECIPE_DIR)/make/toolchains/arm_v8/$(TOOLCHAIN)_cmse.mk

ifeq (CYW20829,$(_MTB_RECIPE__DEVICE_DIE))

# override the memcalc command to run its own flash calc script that prints external flash usage rather than internal.
# this must occur after including recipe_common.mk
ifneq ($(TOOLCHAIN),A_Clang)
_MTB_RECIPE__MEM_CALC=\
	bash --norc --noprofile\
	$(MTB_TOOLS__RECIPE_DIR)/make/scripts/20829/memcalc.bash\
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
	$(if $(findstring normal-non-secure,$(findstring $(DEVICE_LIFE_CYCLE_STATE),normal-non-secure)),$(RECIPE_TRANSITION_NORMAL_NON_SECURE),$(error The only supported DEVICE_LIFE_CYCLE_STATE (replaces DEVICE_MODE) for $(DEVICE) is 'normal-non-secure'))
else
	$(error Missing BSP provision transition files.)
endif


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

# Pass bootstrap size to flash linker script.
ifeq ($(APPTYPE),flash)
ifeq ($(TOOLCHAIN),ARM)
BOOTSTRAP_SIZE?=0x00002400
_MTB_RECIPE__MXSV2_LDFLAGS=--predefine='-DAPP_BOOTSTRAP_SIZE=$(BOOTSTRAP_SIZE)'
else ifeq ($(TOOLCHAIN),IAR)
BOOTSTRAP_SIZE?=0x00003A00
_MTB_RECIPE__MXSV2_LDFLAGS+=--config_def APP_BOOTSTRAP_SIZE=$(BOOTSTRAP_SIZE)
else ifeq ($(TOOLCHAIN),GCC_ARM)
BOOTSTRAP_SIZE?=0x00002400
_MTB_RECIPE__MXSV2_LDFLAGS+=-Wl,--defsym,APP_BOOTSTRAP_SIZE=$(BOOTSTRAP_SIZE)
endif
endif
MTB_RECIPE__LDFLAGS+=$(_MTB_RECIPE__MXSV2_LDFLAGS)

# Postbuilds for l1ram and flash applications for second stage
ifeq ($(APPTYPE),$(filter $(APPTYPE),l1ram flash))

_MTB_RECIPE_20829_SREC_CAT_UTIL=$(CY_TOOL_srec_cat_EXE_ABS)

ifeq ($(_MTB_RECIPE_20829_SREC_CAT_UTIL),)
CY_MESSAGE_srec_cat="srec_cat" could not be found.\
	This is needed to finish running the postbuild steps. Ensure that the module is present to\
	complete the build for this app. The rest of the postbuild steps will now be skipped.
$(eval $(call CY_MACRO_WARNING,CY_MESSAGE_srec_cat,$(CY_MESSAGE_srec_cat)))
else
ifeq ($(APPTYPE),flash)
_MTB_RECIPE__MXSV2_POSTBUILD+=$(MTB_TOOLS__BASH_CMD) $(MTB_TOOLS__RECIPE_DIR)/make/scripts/20829/flash_postbuild.sh "$(TOOLCHAIN)" "$(MTB_TOOLS__OUTPUT_CONFIG_DIR)" "$(APPNAME)" "$(MTB_TOOLCHAIN_GCC_ARM__BASE_DIR)/bin" "$(_MTB_RECIPE_20829_SREC_CAT_UTIL)" "$(BOOTSTRAP_SIZE)";
endif

APP_SLOT_SIZE?= 0x20000
APP_ENCRYPTION?= 0

_MTB_RECIPE__MXSV2_POSTBUILD+=$(MTB_TOOLS__BASH_CMD) $(MTB_TOOLS__RECIPE_DIR)/make/scripts/20829/run_toc2_generator.sh "$(sort $(filter SECURE NON_SECURE,$(VCORE_ATTRS)))" "$(MTB_TOOLS__OUTPUT_CONFIG_DIR)" "$(APPNAME)" "$(APPTYPE)" "$(MTB_TOOLS__TARGET_DIR)" "NONE" "$(MTB_TOOLCHAIN_GCC_ARM__BASE_DIR)" "" $(APP_SLOT_SIZE) $(APP_ENCRYPTION) "" "$(BOOTSTRAP_SIZE)" "$(DEVICE_$(MPN_LIST)_SRAM_KB)";
_MTB_RECIPE__MXSV2_POSTBUILD+=$(_MTB_RECIPE_20829_SREC_CAT_UTIL) $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).final.bin -Binary -offset 0x60000000 -o $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).final.hex -Intel -Output_Block_Size=16;
_MTB_RECIPE__MXSV2_POSTBUILD+=rm -rf $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).bin;cp -f $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).final.hex $(MTB_RECIPE__LAST_CONFIG_DIR)/$(APPNAME).final.hex
endif #($(_MTB_RECIPE_20829_SREC_CAT_UTIL),)

endif # apptype l1ram flash

################################################################################
# cat1b CYW20289 specific help
################################################################################
CY_HELP_DEVICE_MODE=Deprecated as of recipe-make-cat1b 2.5.0, replaced by "DEVICE_LIFE_CYCLE_STATE".
CY_HELP_DEVICE_MODE_VERBOSE=
CY_HELP_DEVICE_LIFE_CYCLE_STATE=Specifies device lifecycle state for provisioning
CY_HELP_DEVICE_LIFE_CYCLE_STATE_VERBOSE=Device transitioning process initiated by device_transition make target \
					uses the DEVICE_LIFE_CYCLE_STATE variable to set device lifecycle state. \
					The only supported value is 'normal-non-secure'.\
					$(MTB__NEWLINE)$(MTB__NEWLINE)Example Usage: make device_transition DEVICE_LIFE_CYCLE_STATE=normal-non-secure
CY_HELP_APP_SECURITY_TYPE=Specifies device lifecycle state for build process. Deprecated as of recipe-make-cat1b 2.5.0, replaced by "VCORE_ATTRS".
CY_HELP_APP_SECURITY_TYPE_VERBOSE=Post-build script uses this variable to create a secure or non-secure application image. \
					Supported values are: NORMAL_NO_SECURE (default), SECURE.
CY_HELP_APP_SLOT_SIZE=Specifies value for --slot-size parameter of cysecuretools. Default value is 0x20000.
CY_HELP_APP_ENCRYPTION=Enables encryption when set to 1; disables encryption for any other value. Disabled by default.
CY_HELP_BOOTSTRAP_SIZE=Specifies bootstrap size for flash linker script
CY_HELP_BOOTSTRAP_SIZE_VERBOSE=Default values of bootstrap size are: for ARM and GCC_ARM toolchains - 0x00002400, \
					for IAR toolchain - 0x00003A00.

ifeq ($(CY_HELP),)
make-recipe-cat1b-help:
	$(info )
	$(info ==============================================================================)
	$(info $(MTB__SPACE)CYW20829 Postbuild make variables)
	$(info ==============================================================================)
	$(info $(MTB__SPACE)APP_SECURITY_TYPE  $(CY_HELP_APP_SECURITY_TYPE))
	$(info $(MTB__SPACE)APP_SLOT_SIZE      $(CY_HELP_APP_SLOT_SIZE))
	$(info $(MTB__SPACE)APP_ENCRYPTION     $(CY_HELP_APP_ENCRYPTION))
	$(info $(MTB__SPACE)BOOTSTRAP_SIZE     $(CY_HELP_BOOTSTRAP_SIZE))
	$(info )
	$(info ==============================================================================)
	$(info $(MTB__SPACE)CYW20829 Provisioning make variables)
	$(info ==============================================================================)
	$(info $(MTB__SPACE)DEVICE_MODE                 $(CY_HELP_DEVICE_MODE))
	$(info $(MTB__SPACE)DEVICE_LIFE_CYCLE_STATE     $(CY_HELP_DEVICE_LIFE_CYCLE_STATE))
	$(info )

help: make-recipe-cat1b-help
endif #($(CY_HELP),)
endif #(CYW20829,$(_MTB_RECIPE__DEVICE_DIE))

recipe_postbuild: $(MTB_RECIPE__LAST_CONFIG_DIR) $(MTB_RECIPE__LAST_CONFIG_DIR)/$(APPNAME).final.hex

$(MTB_RECIPE__LAST_CONFIG_DIR)/$(APPNAME).final.hex: $(_MTB_RECIPE__PROG_FILE) | $(MTB_RECIPE__LAST_CONFIG_DIR)
	$(_MTB_RECIPE__MXSV2_POSTBUILD)

################################################################################
# Programmer tool
################################################################################

CY_PROGTOOL_FW_LOADER=$(CY_TOOL_fw-loader_EXE_ABS)
progtool:
	$(MTB__NOISE)echo;\
	echo ==============================================================================;\
	echo "Available commands";\
	echo ==============================================================================;\
	echo;\
	"$(CY_PROGTOOL_FW_LOADER)" --help | sed s/'	'/' '/g;\
	echo ==============================================================================;\
	echo "Connected device(s)";\
	echo ==============================================================================;\
	echo;\
	deviceList=$$("$(CY_PROGTOOL_FW_LOADER)" --device-list | grep "FW Version" | sed s/'	'/' '/g);\
	if [[ ! -n "$$deviceList" ]]; then\
		echo "ERROR: Could not find any connected devices";\
		echo;\
		exit 1;\
	else\
		echo "$$deviceList";\
		echo;\
	fi;\
	echo ==============================================================================;\
	echo "Input command";\
	echo ==============================================================================;\
	echo;\
	echo " Specify the command (and optionally the device name).";\
	echo " E.g. --mode kp3-daplink KitProg3 CMSIS-DAP HID-0123456789ABCDEF";\
	echo;\
	read -p " > " -a params;\
	echo;\
	echo ==============================================================================;\
	echo "Run command";\
	echo ==============================================================================;\
	echo;\
	paramsSize=$${#params[@]};\
	if [[ $$paramsSize > 2 ]]; then\
		if [[ $${params[1]} == "kp3-"* ]]; then\
			deviceName="$${params[@]:2:$$paramsSize}";\
			"$(CY_PROGTOOL_FW_LOADER)" $${params[0]} $${params[1]} "$$deviceName" | sed s/'	'/' '/g;\
		else\
			deviceName="$${params[@]:1:$$paramsSize}";\
			"$(CY_PROGTOOL_FW_LOADER)" $${params[0]} "$$deviceName" | sed s/'	'/' '/g;\
		fi;\
	else\
		"$(CY_PROGTOOL_FW_LOADER)" "$${params[@]}" | sed s/'	'/' '/g;\
	fi;

.PHONY: progtool recipe_mxsv2_postbuild
