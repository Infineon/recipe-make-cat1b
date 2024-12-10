################################################################################
# \file recipe_ide.mk
#
# \brief
# This make file defines the IDE export variables and target.
#
################################################################################
# \copyright
# (c) 2022-2024, Cypress Semiconductor Corporation (an Infineon company)
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

MTB_RECIPE__IDE_SUPPORTED:=eclipse vscode uvision5 ewarm8
include $(MTB_TOOLS__RECIPE_DIR)/make/recipe/interface_version_1/recipe_ide_common.mk

# Path to debug certificatee
CY_DBG_CERTIFICATE_PATH?=./packets/debug_cert.bin

CY_QSPI_FLM_DIR_OUTPUT?=$(CY_QSPI_FLM_DIR)
ifeq ($(CY_QSPI_FLM_DIR_OUTPUT),)
_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER=
_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER_WITH_FLAG=
else
_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER=set QSPI_FLASHLOADER $(MTB_TOOLS__PRJ_DIR)/$(patsubst %/,%,$(CY_QSPI_FLM_DIR_OUTPUT))/CYW208xx_SMIF.FLM
_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER_WITH_FLAG=-c &quot;$(_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER)&quot;&\#13;&\#10;
endif

# Set the output file paths
ifneq (ram,$(APPTYPE))
ifneq ($(CY_BUILD_LOCATION),)
_MTB_RECIPE__ECLIPSE_PROG_FILE=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).final.hex
else
_MTB_RECIPE__ECLIPSE_PROG_FILE=$${cy_prj_path}/$(notdir $(MTB_TOOLS__OUTPUT_BASE_DIR))/$(TARGET)/$(CONFIG)/$(APPNAME).final.hex
endif
endif

# Toolchain specifics
ifeq ($(TOOLCHAIN),ARM)
PC_SYMBOL=__main
SP_SYMBOL_ECLIPSE=Image$$$$ARM_LIB_STACK$$$$ZI$$$$Limit
SP_SYMBOL_VSCODE=Image\$$\$$ARM_LIB_STACK\$$\$$ZI\$$\$$Limit
else ifeq ($(TOOLCHAIN),IAR)
PC_SYMBOL=Reset_Handler
SP_SYMBOL_ECLIPSE=CSTACK$$$$Limit
SP_SYMBOL_VSCODE=CSTACK\$$\$$Limit
else ifeq ($(TOOLCHAIN),GCC_ARM)
PC_SYMBOL=Reset_Handler
SP_SYMBOL_ECLIPSE=__StackTop
SP_SYMBOL_VSCODE=$(SP_SYMBOL_ECLIPSE)
endif

ifeq (ram,$(APPTYPE))
_MTB_RECIPE__ECLIPSE_TEMPLATE_SUBDIR=ram
else
_MTB_RECIPE__ECLIPSE_TEMPLATE_SUBDIR=flash
endif

ifeq ($(filter vscode,$(MAKECMDGOALS)),vscode)
ifneq (ram,$(APPTYPE))
ifneq ($(CY_BUILD_LOCATION),)
_MTB_RECIPE__HEX_FILE=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).final.hex
else
_MTB_RECIPE__HEX_FILE=./$(notdir $(MTB_TOOLS__OUTPUT_BASE_DIR))/$(TARGET)/$(CONFIG)/$(APPNAME).final.hex
endif
endif

ifeq (ram,$(APPTYPE))
CY_VSCODE_JSON_PROCESSING=\
	if [[ $$jsonFile == "launch.json" ]]; then\
		cp -f $(CY_VSCODE_OUT_TEMPLATE_PATH)/$$jsonFile $(CY_VSCODE_OUT_TEMPLATE_PATH)/__$$jsonFile;\
		sed -e '/\/\/flash launches start\/\//,/\/\/flash launches end\/\//d'\
			-e 's/\/\/ram launches start\/\///g' -e 's/\/\/ram launches end\/\///g'\
			$(CY_VSCODE_OUT_TEMPLATE_PATH)/__$$jsonFile >\
			$(CY_VSCODE_OUT_TEMPLATE_PATH)/$$jsonFile;\
		rm $(CY_VSCODE_OUT_TEMPLATE_PATH)/__$$jsonFile;\
	fi;
else

CY_VSCODE_JSON_PROCESSING=\
	if [[ $$jsonFile == "launch.json" ]]; then\
		cp -f $(CY_VSCODE_OUT_TEMPLATE_PATH)/$$jsonFile $(CY_VSCODE_OUT_TEMPLATE_PATH)/__$$jsonFile;\
		sed -e '/\/\/ram launches start\/\//,/\/\/ram launches end\/\//d'\
			-e 's/\/\/flash launches start\/\///g' -e 's/\/\/flash launches end\/\///g'\
			$(CY_VSCODE_OUT_TEMPLATE_PATH)/__$$jsonFile >\
			$(CY_VSCODE_OUT_TEMPLATE_PATH)/$$jsonFile;\
		rm $(CY_VSCODE_OUT_TEMPLATE_PATH)/__$$jsonFile;\
	fi;
endif

$(MTB_RECIPE__IDE_RECIPE_DATA_FILE)_vscode:
	$(MTB__NOISE)echo "s|&&PC_SYMBOL&&|$(PC_SYMBOL)|g;" > $(MTB_RECIPE__IDE_RECIPE_DATA_FILE);\
	echo "s|&&SP_SYMBOL&&|$(SP_SYMBOL_VSCODE)|g;" >> $(MTB_RECIPE__IDE_RECIPE_DATA_FILE);\
	echo "s|&&_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER&&|$(_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER)|g;" >> $(MTB_RECIPE__IDE_RECIPE_DATA_FILE);\
	echo "s|&&_MTB_RECIPE__JLINK_CFG&&|$(_MTB_RECIPE__JLINK_DEVICE_CFG)|g;" >> $(MTB_RECIPE__IDE_RECIPE_DATA_FILE);\
	echo "s|&&_MTB_RECIPE__QSPI_CFG_PATH&&|$(_MTB_RECIPE__OPENOCD_QSPI_CFG_PATH)|g;" >> $(MTB_RECIPE__IDE_RECIPE_DATA_FILE);\
	echo "s|&&_MTB_RECIPE__DBG_CERTIFICATE_PATH&&|$(CY_DBG_CERTIFICATE_PATH)|g;" >> $(MTB_RECIPE__IDE_RECIPE_DATA_FILE);
endif

ifeq ($(filter eclipse,$(MAKECMDGOALS)),eclipse)

eclipse_textdata_file:
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),&&_MTB_RECIPE__JLINK_CFG&&=$(_MTB_RECIPE__JLINK_DEVICE_CFG))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),&&PC_SYMBOL&&=$(PC_SYMBOL))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),&&SP_SYMBOL&&=$(SP_SYMBOL_ECLIPSE))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),&&_MTB_RECIPE__QSPI_CFG_PATH&&=$(_MTB_RECIPE__OPENOCD_QSPI_CFG_PATH_WITH_FLAG))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),&&_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER&&=$(_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER_WITH_FLAG))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),&&_MTB_RECIPE__DBG_CERTIFICATE_PATH&&=$(CY_DBG_CERTIFICATE_PATH))

_MTB_ECLIPSE_TEMPLATE_RECIPE_SEARCH:=$(MTB_TOOLS__RECIPE_DIR)/make/scripts/interface_version_1/eclipse/$(_MTB_RECIPE__ECLIPSE_TEMPLATE_SUBDIR)
_MTB_ECLIPSE_TEMPLATE_RECIPE_APP_SEARCH:=$(MTB_TOOLS__RECIPE_DIR)/make/scripts/interface_version_1/eclipse/Application

eclipse_recipe_metadata_file:
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_METADATA_FILE),RECIPE_TEMPLATE=$(_MTB_ECLIPSE_TEMPLATE_RECIPE_SEARCH))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_METADATA_FILE),RECIPE_APP_TEMPLATE=$(_MTB_ECLIPSE_TEMPLATE_RECIPE_APP_SEARCH))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_METADATA_FILE),PROJECT_UUID=&&PROJECT_UUID&&)
endif

ewarm8_recipe_data_file:
	$(call mtb__file_write,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),$(DEVICE))

ewarm8: ewarm8_recipe_data_file

ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))
_MTB_RECIPE__CMSIS_ARCH_NAME:=CAT1B_DFP
else
_MTB_RECIPE__CMSIS_ARCH_NAME:=AIROC_DFP
endif
_MTB_RECIPE__CMSIS_VENDOR_NAME:=Infineon
_MTB_RECIPE__CMSIS_VENDOR_ID:=7

_MTB_RECIPE__CMSIS_PNAME:=Cortex-M33

_MTB_RECIPE__CMSIS_LDFLAGS:=

uvision5_recipe_data_file:
	$(call mtb__file_write,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),$(_MTB_RECIPE__CMSIS_ARCH_NAME))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),$(_MTB_RECIPE__CMSIS_VENDOR_NAME))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),$(_MTB_RECIPE__CMSIS_VENDOR_ID))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),$(_MTB_RECIPE__CMSIS_PNAME))
	$(call mtb__file_append,$(MTB_RECIPE__IDE_RECIPE_DATA_FILE),$(_MTB_RECIPE__CMSIS_LDFLAGS))

uvision5: uvision5_recipe_data_file
