################################################################################
# \file recipe_ide.mk
#
# \brief
# This make file defines the IDE export variables and target.
#
################################################################################
# \copyright
# Copyright 2022-2024 Cypress Semiconductor Corporation
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
include $(MTB_TOOLS__RECIPE_DIR)/make/recipe/interface_version_3/recipe_ide_common.mk

# Path to debug certificatee
ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))
ifneq ($(CY_DBG_CERTIFICATE_PATH),)
CY_DBG_CERTIFICATE_PATH_APPLICATION:=$(CY_DBG_CERTIFICATE_PATH)
else
CY_DBG_CERTIFICATE_PATH:=./packets/debug_token.bin
CY_DBG_CERTIFICATE_PATH_APPLICATION:=./packets/debug_token.bin
ifneq (,$(_MTB_RECIPE__IS_MULTI_CORE_APPLICATION))
CY_DBG_CERTIFICATE_PATH:=../packets/debug_token.bin
endif
endif # ifneq ($(CY_DBG_CERTIFICATE_PATH),)
else # ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))
CY_DBG_CERTIFICATE_PATH?=./packets/debug_cert.bin
endif

CY_QSPI_FLM_DIR_OUTPUT?=$(CY_QSPI_FLM_DIR)
ifeq ($(CY_QSPI_FLM_DIR_OUTPUT),)
_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER=
_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER_WITH_FLAG=
else
_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER=set QSPI_FLASHLOADER $(patsubst %/,%,$(CY_QSPI_FLM_DIR_OUTPUT))/CYW208xx_SMIF.FLM
_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER_WITH_FLAG=-c &quot;$(_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER)&quot;&\#13;&\#10;
endif

# Toolchain specifics
ifeq ($(TOOLCHAIN),ARM)
PC_SYMBOL=__main
SP_SYMBOL=Image$$$$ARM_LIB_STACK$$$$ZI$$$$Limit
else ifeq ($(TOOLCHAIN),IAR)
PC_SYMBOL=Reset_Handler
SP_SYMBOL=CSTACK$$$$Limit
else ifeq ($(TOOLCHAIN),GCC_ARM)
PC_SYMBOL=Reset_Handler
SP_SYMBOL=__StackTop
endif

##############################################
# Eclipse VSCode
##############################################
_MTB_RECIPE__IDE_TEXT_DATA_FILE=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/recipe_ide_text_data.txt
_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE:=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/recipe_ide_template_meta_data.txt
_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE:=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/recipe_vscode_template_regex_data.txt
_MTB_RECIPE__IDE_TEMPLATE_DIR:=$(MTB_TOOLS__RECIPE_DIR)/make/scripts/interface_version_3
_MTB_RECIPE__VSCODE_TASKS_TEMPLATE=tasks_internal.json

ifeq ($(firstword $(MTB_APPLICATION_SUBPROJECTS)),$(_MTB_RECIPE__IDE_PRJ_DIR_NAME))
_MTB_RECIPE__IS_FIRST_PRJ=1
endif
ifeq ($(lastword $(MTB_APPLICATION_SUBPROJECTS)),$(_MTB_RECIPE__IDE_PRJ_DIR_NAME))
_MTB_RECIPE__IS_LAST_PRJ=1
endif

ifeq (ram,$(APPTYPE))
_MTB_RECIPE__IDE_TEMPLATE_SUBDIR:=ram/20829
ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))
_MTB_RECIPE__IDE_TEMPLATE_SUBDIR:=ram/PSC3
endif
else
ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))
ifeq ($(BITFILE_PROVISIONED),false)
_MTB_RECIPE__IDE_TEMPLATE_SUBDIR:=flash/PSC3/virgin
else
_MTB_RECIPE__IDE_TEMPLATE_SUBDIR:=flash/PSC3/normal
endif
else
_MTB_RECIPE__IDE_TEMPLATE_SUBDIR:=flash/20829
endif
endif

# Set the output file paths
ifeq (,$(_MTB_RECIPE__IS_DIE_PSC3))
ifneq ($(CY_BUILD_LOCATION),)
_MTB_RECIPE__ECLIPSE_PROG_FILE=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME)$(_MTB_RECIPE__PROG_FILE_SUFFIX).$(MTB_RECIPE__SUFFIX_PROGRAM)
_MTB_RECIPE__ECLIPSE_STATIC_SECTION=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(SS_BIN_FILE)
_MTB_RECIPE__VSCODE_STATIC_SECTION=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(SS_BIN_FILE)
_MTB_RECIPE__VSCODE_FINAL_HEX_FILE=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME)$(_MTB_RECIPE__PROG_FILE_SUFFIX).$(MTB_RECIPE__SUFFIX_PROGRAM)
else
_MTB_RECIPE__ECLIPSE_PROG_FILE=$${cy_prj_path}/$(_MTB_RECIPE__IDE_BUILD_PATH_RELATIVE)/$(APPNAME)$(_MTB_RECIPE__PROG_FILE_SUFFIX).$(MTB_RECIPE__SUFFIX_PROGRAM)
_MTB_RECIPE__ECLIPSE_STATIC_SECTION=$${cy_prj_path}/$(_MTB_RECIPE__IDE_BUILD_PATH_RELATIVE)/$(SS_BIN_FILE)
_MTB_RECIPE__VSCODE_STATIC_SECTION=./$(_MTB_RECIPE__IDE_BUILD_PATH_RELATIVE)/$(SS_BIN_FILE)
_MTB_RECIPE__VSCODE_FINAL_HEX_FILE=./$(_MTB_RECIPE__IDE_BUILD_PATH_RELATIVE)/$(APPNAME)$(_MTB_RECIPE__PROG_FILE_SUFFIX).$(MTB_RECIPE__SUFFIX_PROGRAM)
endif
endif

##############################################
# Eclipse
##############################################

eclipse_generate: recipe_eclipse_text_replacement_data_file recipe_eclipse_meta_replacement_data_file
eclipse_generate: MTB_CORE__EXPORT_CMDLINE += -textdata $(_MTB_RECIPE__IDE_TEXT_DATA_FILE)  -metadata $(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE)

recipe_eclipse_meta_replacement_data_file:
	$(call mtb__file_write,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),UUID=&&PROJECT_UUID&&)
ifneq (,$(_MTB_RECIPE__IS_MULTI_CORE_APPLICATION))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),APPLICATION_UUID=&&APPLICATION_UUID&&)
ifneq (,$(_MTB_RECIPE__IS_FIRST_PRJ))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),UUID=&&PROJECT_UUID_1&&)
endif
ifneq (,$(_MTB_RECIPE__IS_LAST_PRJ))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),UUID=&&PROJECT_UUID_2&&)
endif #(,$(_MTB_RECIPE__IS_LAST_PRJ))
ifneq (,$(_MTB_RECIPE__IS_FIRST_PRJ))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/eclipse/Application/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)=../.mtbLaunchConfigs)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(MTB_TOOLS__RECIPE_DIR)/make/recipe/interface_version_3/App/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/internal=../.mtbLaunchConfigs)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),UPDATE_APPLICATION_PREF_FILE=1)
else
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=../.mtbLaunchConfigs=../.mtbLaunchConfigs)
endif #(,$(_MTB_RECIPE__IS_FIRST_PRJ))
else #(,$(_MTB_RECIPE__IS_MULTI_CORE_APPLICATION))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/eclipse/CM33/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/single=.mtbLaunchConfigs)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(MTB_TOOLS__RECIPE_DIR)/make/recipe/interface_version_3/Proj/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/single/internal=.mtbLaunchConfigs)
endif #(,$(_MTB_RECIPE__IS_MULTI_CORE_APPLICATION))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/eclipse/CM33/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/any=.mtbLaunchConfigs)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(MTB_TOOLS__RECIPE_DIR)/make/recipe/interface_version_3/Proj/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/any=.mtbLaunchConfigs)

recipe_eclipse_text_replacement_data_file:
	$(call mtb__file_write,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__JLINK_CFG&&=$(_MTB_RECIPE__JLINK_DEVICE_CFG))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__JLINK_CFG_ATTACH&&=$(_MTB_RECIPE__JLINK_CFG_ATTACH))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&PC_SYMBOL&&=$(PC_SYMBOL))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&SP_SYMBOL&&=$(SP_SYMBOL))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__QSPI_CFG_PATH&&=$(_MTB_RECIPE__OPENOCD_QSPI_CFG_PATH_WITH_FLAG))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER&&=$(_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER_WITH_FLAG))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__DBG_CERTIFICATE_PATH&&=$(CY_DBG_CERTIFICATE_PATH))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__DBG_CERTIFICATE_APPLICATION_PATH&&=$(CY_DBG_CERTIFICATE_PATH_APPLICATION))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__ECLIPSE_LAUNCH_APP_COMMANDS&&=$(_MTB_RECIPE__ECLIPSE_LAUNCH_APP_COMMANDS))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__PREBUILT_SECURE_APP&&=$(_MTB_RECIPE__PREBUILT_SECURE_APP))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__ECLIPSE_POST_CONNECT_COMMANDS&&=$(_MTB_RECIPE__ECLIPSE_POST_CONNECT_COMMANDS))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__ECLIPSE_OTHER_RUN_COMMANDS&&=$(_MTB_RECIPE__ECLIPSE_OTHER_RUN_COMMANDS))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__ECLIPSE_PROGRAM_CONFIG_CMD&&=$(_MTB_RECIPE__ECLIPSE_PROGRAM_CONFIG_CMD))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__ECLIPSE_JLINK_OTHER_RUN_COMMANDS&&=$(_MTB_RECIPE__ECLIPSE_JLINK_OTHER_RUN_COMMANDS))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__ECLIPSE_JLINK_OTHER_RUN_COMMANDS&&=$(_MTB_RECIPE__ECLIPSE_JLINK_OTHER_RUN_COMMANDS))
ifneq ($(filter NON_SECURE,$(VCORE_ATTRS)),)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__SYM_FILE_NS&&=$(_MTB_RECIPE__ECLIPSE_SYM_FILE))
else
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__SYM_FILE_S&&=$(_MTB_RECIPE__ECLIPSE_SYM_FILE))
endif

##############################################
# VSCode
##############################################

vscode_generate: recipe_vscode_text_replacement_data_file recipe_vscode_meta_replacement_data_file recipe_vscode_regex_replacement_data_file
vscode_generate: MTB_CORE__EXPORT_CMDLINE += -textdata $(_MTB_RECIPE__IDE_TEXT_DATA_FILE)  -metadata $(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE) -textregexdata $(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE)

recipe_vscode_text_replacement_data_file:
	$(call mtb__file_write,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__FINAL_HEX_FILE&&=$(_MTB_RECIPE__VSCODE_FINAL_HEX_FILE))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__JLINK_CFG&&=$(_MTB_RECIPE__JLINK_DEVICE_CFG))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__JLINK_CFG_ATTACH&&=$(_MTB_RECIPE__JLINK_CFG_ATTACH))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&PC_SYMBOL&&=$(PC_SYMBOL))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&SP_SYMBOL&&=$(SP_SYMBOL))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__QSPI_CFG_PATH&&=$(_MTB_RECIPE__OPENOCD_QSPI_CFG_PATH))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER&&=$(_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__DBG_CERTIFICATE_PATH&&=$(CY_DBG_CERTIFICATE_PATH))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__DBG_CERTIFICATE_APPLICATION_PATH&&=$(CY_DBG_CERTIFICATE_PATH_APPLICATION))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__FAMILY_NAME&&=$(_MTB_RECIPE__DEVICE_DIE))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__PREBUILT_SECURE_APP&&=$(_MTB_RECIPE__PREBUILT_SECURE_APP))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__READ_STATIC_SECT&&=$(_MTB_RECIPE__READ_STATIC_SECT))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__VSCODE_PROGRAM_STATIC_SECT_CMD&&=$(_MTB_RECIPE__VSCODE_PROGRAM_STATIC_SECT_CMD))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__RESTORE_STATIC_SECT&&=$(_MTB_RECIPE__RESTORE_STATIC_SECT))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__VSCODE_JLINK_PROGRAM_STATIC_SECT&&=restore $(_MTB_RECIPE__VSCODE_STATIC_SECTION) binary $(SS_START_LMA))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_PRJ_NAME&&=$(APPNAME))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__OPENOCD_TARGET_VAR&&=$(_MTB_RECIPE__OPENOCD_TARGET_VAR))
ifneq ($(filter NON_SECURE,$(VCORE_ATTRS)),)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__ELF_FILE_NS&&=$(_MTB_RECIPE__VSCODE_ELF_FILE_APPLICATION))
else
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEXT_DATA_FILE),&&_MTB_RECIPE__ELF_FILE_S&&=$(_MTB_RECIPE__VSCODE_ELF_FILE_APPLICATION))
endif

recipe_vscode_regex_replacement_data_file:
ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))
	$(call mtb__file_write,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^(.*)//PSC3 Only//(.*)$$=\1\2)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//20829 Only//.*$$=)
ifneq (,$(_MTB_RECIPE__IS_MULTI_CORE_APPLICATION))
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//PSC3 NON_SECURE Only//.*$$=)
else
ifneq ($(filter NON_SECURE,$(VCORE_ATTRS)),)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^(.*)//PSC3 NON_SECURE Only//(.*)$$=\1\2)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//PSC3 SECURE Only//.*$$=)
else
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^(.*)//PSC3 SECURE Only//(.*)$$=\1\2)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//PSC3 NON_SECURE Only//.*$$=)
endif
endif
else #(,$(_MTB_RECIPE__IS_DIE_PSC3))
	$(call mtb__file_write,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^(.*)//20829 Only//(.*)$$=\1\2)
ifeq ($(VS_ERASE),1)
ifeq ($(SS_CONFIG),1)
# program application, program static section
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^(.*)//prebuild SS//(.*)$$=\1\2)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//backup SS//.*$$=)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//restore SS//.*$$=)
else
# Read static section, program application and restore static section
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^(.*)//backup SS//(.*)$$=\1\2)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//prebuild SS//.*$$=)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^(.*)//restore SS//(.*)$$=\1\2)
endif #($(SS_CONFIG),1)
else #($(VS_ERASE),1)
ifeq ($(SS_CONFIG),1)
# program application, program static section
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^(.*)//prebuild SS//(.*)$$=\1\2)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//backup SS//.*$$=)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//restore SS//.*$$=)
else
# program application only
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//backup SS//.*$$=)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//prebuild SS//.*$$=)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_TEMPLATE_REGEX_DATA_FILE),^.*//restore SS//.*$$=)
endif
endif
endif

recipe_vscode_meta_replacement_data_file:
ifneq (,$(_MTB_RECIPE__IS_MULTI_CORE_APPLICATION))
	$(call mtb__file_write,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/vscode/CM33/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/launch_multicore.json=.vscode/launch.json)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_CORE__IDE_TEMPLATE_DIR)/vscode/dependencies_tasks.json=.vscode/tasks.json)
ifneq (,$(_MTB_RECIPE__IS_FIRST_PRJ))
ifeq ($(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR),KitProg3)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/vscode/Application/openocd.tcl=../openocd.tcl)
endif
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/vscode/Application/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/launch.json=../.vscode/launch.json)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(MTB_TOOLS__CORE_DIR)/make/scripts/interface_version_3/vscode/$(_MTB_RECIPE__VSCODE_TASKS_TEMPLATE)=../.vscode/tasks.json)
else
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=../.vscode=../.vscode)
endif
else #(,$(_MTB_RECIPE__IS_MULTI_CORE_APPLICATION))
	$(call mtb__file_write,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/vscode/CM33/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/launch.json=.vscode/launch.json)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(MTB_TOOLS__CORE_DIR)/make/scripts/interface_version_3/vscode/$(_MTB_RECIPE__VSCODE_TASKS_TEMPLATE)=.vscode/tasks.json)
endif#(,$(_MTB_RECIPE__IS_MULTI_CORE_APPLICATION))
ifeq ($(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR),KitProg3)
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/vscode/CM33/openocd.tcl=openocd.tcl)
endif
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_TEMPLATE_META_DATA_FILE),MERGE_LAUNCH_JSON=.vscode/launch.json=.vscode/launch.json)

.PHONY: recipe_vscode_text_replacement_data_file recipe_vscode_meta_replacement_data_file recipe_vscode_regex_replacement_data_file

##############################################
# EW UV
##############################################
_MTB_RECIPE__IDE_BUILD_DATA_FILE:=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/recipe_ide_build_data.txt

ewarm8 uvision5: MTB_CORE__EXPORT_CMDLINE += -build_data $(_MTB_RECIPE__IDE_BUILD_DATA_FILE)
ewarm8 uvision5: recipe_ide_build_data_file

recipe_ide_build_data_file:
	$(call mtb__file_write,$(_MTB_RECIPE__IDE_BUILD_DATA_FILE),LINKER_SCRIPT=$(MTB_RECIPE__LINKER_SCRIPT))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_BUILD_DATA_FILE),LDFLAGS=$(_MTB_RECIPE__MXSV2_LDFLAGS))

.PHONY: recipe_ide_build_data_file

##############################################
# UV
##############################################
ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))
_MTB_RECIPE__CMSIS_ARCH_NAME:=CAT1B_DFP
else
_MTB_RECIPE__CMSIS_ARCH_NAME:=AIROC_DFP
endif
_MTB_RECIPE__CMSIS_VENDOR_NAME:=Infineon
_MTB_RECIPE__CMSIS_VENDOR_ID:=7
_MTB_RECIPE__CMSIS_PNAME:=Cortex-M33

_MTB_RECIPE__IDE_DFP_DATA_FILE:=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/recipe_ide_dfp_data.txt

uvision5: recipe_uvision5_dfp_data_file
uvision5: MTB_CORE__EXPORT_CMDLINE += -dfp_data $(_MTB_RECIPE__IDE_DFP_DATA_FILE)

recipe_uvision5_dfp_data_file:
	$(call mtb__file_write,$(_MTB_RECIPE__IDE_DFP_DATA_FILE),DEVICE=$(DEVICE))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_DFP_DATA_FILE),DFP_NAME=$(_MTB_RECIPE__CMSIS_ARCH_NAME))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_DFP_DATA_FILE),VENDOR_NAME=$(_MTB_RECIPE__CMSIS_VENDOR_NAME))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_DFP_DATA_FILE),VENDOR_ID=$(_MTB_RECIPE__CMSIS_VENDOR_ID))
	$(call mtb__file_append,$(_MTB_RECIPE__IDE_DFP_DATA_FILE),PNAME=$(_MTB_RECIPE__CMSIS_PNAME))

uvision5: recipe_uvision5_dfp_data_file


##############################################
# Combiner/Signer Integration
##############################################

ifneq ($(COMBINE_SIGN_JSON),)
_MTB_RECIPE__IDE_PRJ_DIR_NAME:=$(notdir $(realpath $(MTB_TOOLS__PRJ_DIR)))

_MTB_RECIPE__VSCODE_COMBINE_SIGN_MEATA_DATA_FILE=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/vscode_combine_sign_meta_data.txt

vscode_generate: MTB_CORE__EXPORT_CMDLINE += -metadata $(_MTB_RECIPE__VSCODE_COMBINE_SIGN_MEATA_DATA_FILE)
vscode_generate: recipe_vscode_combine_sign_meta

recipe_vscode_combine_sign_meta:
	$(call mtb__file_write,$(_MTB_RECIPE__VSCODE_COMBINE_SIGN_MEATA_DATA_FILE))
ifneq ($(wildcard $(_MTB_RECIPE__IDE_TEMPLATE_DIR)/vscode/$(MTB_RECIPE__CORE)/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/launch_combine_sign.json),)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_COMBINE_SIGN_MEATA_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/vscode/$(MTB_RECIPE__CORE)/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/launch_combine_sign.json=.vscode/launch_&&IDX&&.json)
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_COMBINE_SIGN_MEATA_DATA_FILE),TEMPLATE_REPEAT=.vscode/launch_&&IDX&&.json=$(MTB_COMBINE_SIGN_$(_MTB_RECIPE__IDE_PRJ_DIR_NAME)_HEX_FILES))
	$(call mtb__file_append,$(_MTB_RECIPE__VSCODE_COMBINE_SIGN_MEATA_DATA_FILE),MERGE_LAUNCH_JSON=.vscode/launch.json=$(foreach index,$(MTB_COMBINE_SIGN_$(_MTB_RECIPE__IDE_PRJ_DIR_NAME)_HEX_FILES),.vscode/launch_$(index).json))
endif


_MTB_RECIPE__ECLIPSE_COMBINE_SIGN_MEATA_DATA_FILE=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/eclipse_combine_sign_meta_data.txt

eclipse_generate: MTB_CORE__EXPORT_CMDLINE += -metadata $(_MTB_RECIPE__ECLIPSE_COMBINE_SIGN_MEATA_DATA_FILE)
eclipse_generate: recipe_eclipse_combine_sign_meta

recipe_eclipse_combine_sign_meta:
	$(call mtb__file_write,$(_MTB_RECIPE__ECLIPSE_COMBINE_SIGN_MEATA_DATA_FILE))
ifneq ($(wildcard $(_MTB_RECIPE__IDE_TEMPLATE_DIR)/eclipse/$(MTB_RECIPE__CORE)/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/combine_sign/Debug.launch),)
	$(call mtb__file_append,$(_MTB_RECIPE__ECLIPSE_COMBINE_SIGN_MEATA_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/eclipse/$(MTB_RECIPE__CORE)/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/combine_sign/Debug.launch=.mtbLaunchConfigs/&&MTB_COMBINE_SIGN_&&IDX&&_CONFIG_NAME&& Debug $(_MTB_RECIPE__PROGRAM_INTERFACE_LAUNCH_SUFFIX).launch)
	$(call mtb__file_append,$(_MTB_RECIPE__ECLIPSE_COMBINE_SIGN_MEATA_DATA_FILE),TEMPLATE_REPLACE=$(_MTB_RECIPE__IDE_TEMPLATE_DIR)/eclipse/$(MTB_RECIPE__CORE)/$(_MTB_RECIPE__IDE_TEMPLATE_SUBDIR)/$(_MTB_RECIPE__PROGRAM_INTERFACE_SUBDIR)/combine_sign/Attach.launch=.mtbLaunchConfigs/&&MTB_COMBINE_SIGN_&&IDX&&_CONFIG_NAME&& Attach $(_MTB_RECIPE__PROGRAM_INTERFACE_LAUNCH_SUFFIX).launch)
	$(call mtb__file_append,$(_MTB_RECIPE__ECLIPSE_COMBINE_SIGN_MEATA_DATA_FILE),TEMPLATE_REPEAT=.mtbLaunchConfigs/&&MTB_COMBINE_SIGN_&&IDX&&_CONFIG_NAME&& Debug $(_MTB_RECIPE__PROGRAM_INTERFACE_LAUNCH_SUFFIX).launch=$(MTB_COMBINE_SIGN_$(_MTB_RECIPE__IDE_PRJ_DIR_NAME)_HEX_FILES))
	$(call mtb__file_append,$(_MTB_RECIPE__ECLIPSE_COMBINE_SIGN_MEATA_DATA_FILE),TEMPLATE_REPEAT=.mtbLaunchConfigs/&&MTB_COMBINE_SIGN_&&IDX&&_CONFIG_NAME&& Attach $(_MTB_RECIPE__PROGRAM_INTERFACE_LAUNCH_SUFFIX).launch=$(MTB_COMBINE_SIGN_$(_MTB_RECIPE__IDE_PRJ_DIR_NAME)_HEX_FILES))
endif

endif