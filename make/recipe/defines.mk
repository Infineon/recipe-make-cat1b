################################################################################
# \file defines.mk
#
# \brief
# Defines, needed for the Player build recipe.
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

include $(CY_INTERNAL_BASELIB_PATH)/make/recipe/defines_common.mk


################################################################################
# General
################################################################################

#
# List the supported toolchains
#
CY_SUPPORTED_TOOLCHAINS=GCC_ARM IAR ARM A_Clang

ifeq ($(TOOLCHAIN),ARM)
PC_SYMBOL=__main
SP_SYMBOL=Image\$$\$$ARM_LIB_STACK\$$\$$ZI\$$\$$Limit
else ifeq ($(TOOLCHAIN),IAR)
PC_SYMBOL=Reset_Handler
SP_SYMBOL=CSTACK\$$\$$Limit
else ifeq ($(TOOLCHAIN),GCC_ARM)
PC_SYMBOL=Reset_Handler
SP_SYMBOL=__StackTop
endif

# Linker script file name
CY_STARTUP=cyw20829

#
# Define the default core
#
CORE?=CM33

# only has external memory
CY_START_FLASH=0
CY_START_SRAM=0x20000000
CY_START_EXTERNAL_FLASH=0x60000000

#
# Core specifics
#
CY_LINKERSCRIPT_SUFFIX=cm33

#
# Architecure specifics
#
CY_PSOC_ARCH=psoc6_02
CY_PSOC_DIE_NAME=PSoC6A2M
CY_OPENOCD_CHIP_NAME=cyw20829
CY_OPENOCD_DEVICE_CFG=cyw20829.cfg
CY_JLINK_DEVICE_CFG=CYW20829_tm

#
# Flash memory specifics
# only has external memory
CY_MEMORY_FLASH?=0

#
# SRAM memory specifics
# 0x20000
CY_MEMORY_SRAM=131072

#
# The max external memory size supported
# This is not the amount that is available on the board
#
CY_MEMORY_EXTERNAL_FLASH=0x08000000

#
# linker scripts
#
CY_LINKER_SCRIPT_NAME=cyw20829_ns_$(APPTYPE)_cbus


################################################################################
# BSP Generation
################################################################################

DEVICE_GEN?=$(DEVICE)

# Paths
CY_BSP_TEMPLATES_DIR=$(CY_CONDITIONAL_DEVICESUPPORT_PATH)/devices/COMPONENT_CAT1B/templates/COMPONENT_MTB
CY_TEMPLATES_DIR=$(CY_BSP_TEMPLATES_DIR)
CY_BSP_DESTINATION_ABSOLUTE=$(abspath $(CY_TARGET_GEN_DIR))

# Command for searching files in the template directory
CY_BSP_SEARCH_FILES_CMD=\
	-name system_cat1b.h \
	-o -name system_cyw20829.h \
	-o -name *$(CY_LINKER_SCRIPT_NAME)\.*

# There is only 1 linker script and startup file. No old files to backup
CY_SEARCH_FILES_CMD=


################################################################################
# Paths
################################################################################

# Paths used in program/debug
ifeq ($(CY_DEVICESUPPORT_PATH),)
CY_ECLIPSE_OPENOCD_SVD_PATH?=$$\{cy_prj_path\}/$(dir $(firstword $(CY_DEVICESUPPORT_SEARCH_PATH)))devices/COMPONENT_CAT1B/svd/$(CY_STARTUP).svd
CY_VSCODE_OPENOCD_SVD_PATH?=$(dir $(firstword $(CY_DEVICESUPPORT_SEARCH_PATH)))devices/COMPONENT_CAT1B/svd/$(CY_STARTUP).svd
else
CY_ECLIPSE_OPENOCD_SVD_PATH?=$$\{cy_prj_path\}/$(CY_DEVICESUPPORT_PATH)/devices/COMPONENT_CAT1B/svd/$(CY_STARTUP).svd
CY_VSCODE_OPENOCD_SVD_PATH?=$(CY_DEVICESUPPORT_PATH)/devices/COMPONENT_CAT1B/svd/$(CY_STARTUP).svd
endif

# Path to debug certificatee
CY_DBG_CERTIFICATE_PATH?=./packets/debug_cert.bin

CY_QSPI_FLM_DIR_OUTPUT?=$(patsubst %/,%,$(CY_QSPI_FLM_DIR))
ifeq ($(CY_QSPI_FLM_DIR_OUTPUT),)
CY_OPENOCD_QSPI_FLASHLOADER=
CY_OPENOCD_QSPI_FLASHLOADER_WITH_FLAG=
else
CY_OPENOCD_QSPI_FLASHLOADER=set QSPI_FLASHLOADER $(CY_INTERNAL_APPLOC)/$(CY_QSPI_FLM_DIR_OUTPUT)/CYW208xx_SMIF.FLM
CY_OPENOCD_QSPI_FLASHLOADER_WITH_FLAG="-c \\\&quot\\\;$(CY_OPENOCD_QSPI_FLASHLOADER)\\\&quot\\\;\\\&\\\#13\\\;\\\&\\\#10\\\;"
endif

################################################################################
# IDE specifics
################################################################################

# Set the output file paths
ifneq (ram,$(APPTYPE))
ifneq ($(CY_BUILD_LOCATION),)
CY_PROG_FILE=$(CY_INTERNAL_BUILD_LOC)/$(TARGET)/$(CONFIG)/$(APPNAME).final.hex
else
CY_PROG_FILE=\$$\{cy_prj_path\}/$(notdir $(CY_INTERNAL_BUILD_LOC))/$(TARGET)/$(CONFIG)/$(APPNAME).final.hex
endif
endif

ifeq (ram,$(APPTYPE))
CY_ECLIPSE_TEMPLATES_WILDCARD=ram/*
else
CY_ECLIPSE_TEMPLATES_WILDCARD=flash/*
endif

ifeq ($(filter vscode,$(MAKECMDGOALS)),vscode)
ifneq (ram,$(APPTYPE))
ifneq ($(CY_BUILD_LOCATION),)
CY_HEX_FILE=$(CY_INTERNAL_BUILD_LOC)/$(TARGET)/$(CONFIG)/$(APPNAME).final.hex
else
CY_HEX_FILE=./$(notdir $(CY_INTERNAL_BUILD_LOC))/$(TARGET)/$(CONFIG)/$(APPNAME).final.hex
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

CY_VSCODE_ARGS+="s|&&PC_SYMBOL&&|$(PC_SYMBOL)|g;"\
				"s|&&SP_SYMBOL&&|$(SP_SYMBOL)|g;"\
				"s|&&CY_OPENOCD_QSPI_FLASHLOADER&&|$(CY_OPENOCD_QSPI_FLASHLOADER)|g;"\
				"s|&&CY_JLINK_CFG&&|$(CY_JLINK_DEVICE_CFG)|g;"\
				"s|&&CY_QSPI_CFG_PATH&&|$(CY_OPENOCD_QSPI_CFG_PATH)|g;"\
				"s|&&CY_DBG_CERTIFICATE_PATH&&|$(CY_DBG_CERTIFICATE_PATH)|g;"
endif

ifeq ($(filter eclipse,$(MAKECMDGOALS)),eclipse)
CY_ECLIPSE_ARGS+="s|&&CY_JLINK_CFG&&|$(CY_JLINK_DEVICE_CFG)|;"\
				"s|&&PC_SYMBOL&&|$(PC_SYMBOL)|;"\
				"s|&&SP_SYMBOL&&|$(SP_SYMBOL)|;"\
				"s|&&CY_QSPI_CFG_PATH&&|$(CY_OPENOCD_QSPI_CFG_PATH_WITH_FLAG)|g;"\
				"s|&&CY_OPENOCD_QSPI_FLASHLOADER&&|$(CY_OPENOCD_QSPI_FLASHLOADER_WITH_FLAG)|g;"\
				"s|&&CY_DBG_CERTIFICATE_PATH&&|$(CY_DBG_CERTIFICATE_PATH)|g;"
endif

CY_IAR_DEVICE_NAME=$(DEVICE)

CY_CMSIS_ARCH_NAME=AIROC_DFP
CY_CMSIS_VENDOR_NAME=Infineon
CY_CMSIS_VENDOR_ID=7
CY_CMSIS_SPECIFY_CORE=1

################################################################################
# Tools specifics
################################################################################

CY_SUPPORTED_TOOL_TYPES+=\
	qspi-configurator

# Player smartio also uses the .modus extension
modus_DEFAULT_TYPE+=device-configurator smartio-configurator

# Player capsense-tuner shares its existence with capsense-configurator
CY_OPEN_NEWCFG_XML_TYPES+=capsense-tuner

CY_SUPPORTED_TOOL_TYPES+=\
	device-configurator\
	seglcd-configurator\
	smartio-configurator\
	dfuh-tool

ifneq (,$(findstring $(DEVICE),$(CY_DEVICES_WITH_BLE)))
CY_SUPPORTED_TOOL_TYPES+=bt-configurator
CY_OPEN_bt_configurator_DEVICE=--device 43xxx
endif

ifneq ($(filter $(DEVICE),$(CY_DEVICES_WITH_DIE_CYW20829)),)
# Always overwrite VFP_SELECT for 20829 devices
VFP_SELECT:=softfloat
endif
