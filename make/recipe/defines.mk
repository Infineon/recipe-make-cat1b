################################################################################
# \file defines.mk
#
# \brief
# Defines, needed for the AIROC(TM) CYW20829 and PSC3 build recipe.
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

include $(MTB_TOOLS__RECIPE_DIR)/make/recipe/defines_common.mk

ifeq (CYW20829,$(_MTB_RECIPE__DEVICE_DIE))
_MTB_RECIPE__IS_DIE_CYW20829=true
else
_MTB_RECIPE__IS_DIE_PSC3=true
endif

################################################################################
# General
################################################################################
_MTB_RECIPE__PROGRAM_INTERFACE_SUPPORTED:=KitProg3 JLink
#
# Compactibility interface for this recipe make
#
ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))
MTB_RECIPE__EXPORT_INTERFACES:=2 3 4
MTB_RECIPE__INTERFACE_VERSION:=2
else
MTB_RECIPE__INTERFACE_VERSION:=2
MTB_RECIPE__EXPORT_INTERFACES:=1 2 3 4
endif

MTB_RECIPE__NINJA_SUPPORT:=1 2
#
# List the supported toolchains
#
ifdef CY_SUPPORTED_TOOLCHAINS
MTB_SUPPORTED_TOOLCHAINS?=$(CY_SUPPORTED_TOOLCHAINS)
else
MTB_SUPPORTED_TOOLCHAINS?=GCC_ARM IAR ARM A_Clang LLVM_ARM
endif

# For BWC with Makefiles that do anything with CY_SUPPORTED_TOOLCHAINS
CY_SUPPORTED_TOOLCHAINS:=$(MTB_SUPPORTED_TOOLCHAINS)

ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))

#
# Define the default device mode
#
VCORE_ATTRS?=

# Device has internal memory only
ifneq ($(filter SECURE,$(VCORE_ATTRS)),)
_MTB_RECIPE__START_FLASH=0x32000000
else
_MTB_RECIPE__START_FLASH=0x22000000
endif
else
# Device has external memory only
_MTB_RECIPE__START_FLASH=0
CY_START_EXTERNAL_FLASH=0x60000000
endif

_MTB_RECIPE__ECLIPSE_NEWLINE:=&\#13;&\#10;

ifeq ($(MTB_TYPE),PROJECT)
_MTB_RECIPE__IS_MULTI_CORE_APPLICATION:=true
endif

#
# Architecure specifics
#
ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))
_MTB_RECIPE__OPENOCD_CHIP_NAME:=psc3
_MTB_RECIPE__OPENOCD_DEVICE_CFG:=infineon/psc3.cfg
_MTB_RECIPE__OPENOCD_TARGET_VAR:=psc3
_MTB_RECIPE__PREBUILT_SECURE_APP:=$(MTB_TOOLS__TARGET_DIR)/TOOLCHAIN_$(TOOLCHAIN)/COMPONENT_PREBUILT_SECURE_APP/secure_region_flash.elf
ifeq (128,$(_MTB_RECIPE__DEVICE_FLASH_KB))
_MTB_RECIPE__JLINK_DEVICE_CFG:=PSC3xxE_tm
_MTB_RECIPE__JLINK_CFG_ATTACH:=PSC3xxE
else
_MTB_RECIPE__JLINK_DEVICE_CFG:=PSC3xxF_tm
_MTB_RECIPE__JLINK_CFG_ATTACH:=PSC3xxF
endif
ifeq (ram,$(APPTYPE))
_MTB_RECIPE__PREBUILT_SECURE_APP:=$(MTB_TOOLS__TARGET_DIR)/TOOLCHAIN_$(TOOLCHAIN)/COMPONENT_PREBUILT_SECURE_APP/secure_region.elf
endif
ifeq (,$(_MTB_RECIPE__IS_MULTI_CORE_APPLICATION))
ifneq ($(filter NON_SECURE,$(VCORE_ATTRS)),)
_MTB_RECIPE__ECLIPSE_LAUNCH_APP_COMMANDS:=load $(_MTB_RECIPE__PREBUILT_SECURE_APP)$(_MTB_RECIPE__ECLIPSE_NEWLINE)
endif
endif
else #ifneq (,$(_MTB_RECIPE__IS_DIE_PSC3))
_MTB_RECIPE__OPENOCD_CHIP_NAME:=cyw20829
_MTB_RECIPE__OPENOCD_DEVICE_CFG:=cyw20829.cfg
_MTB_RECIPE__JLINK_DEVICE_CFG:=CYW20829_tm
_MTB_RECIPE__OPENOCD_TARGET_VAR:=$${TARGET}
ifneq (ram,$(APPTYPE))
_MTB_RECIPE__PROG_FILE_SUFFIX:=.final
_MTB_RECIPE__PROGRAM_MAIN_APP_CMD=program $(_MTB_RECIPE__ECLIPSE_PROG_FILE) verify
_MTB_RECIPE__ECLIPSE_PROGRAM_STATIC_SECT_CMD=program $(_MTB_RECIPE__ECLIPSE_STATIC_SECTION) $(SS_START_LMA) verify
_MTB_RECIPE__VSCODE_PROGRAM_STATIC_SECT_CMD=program $(_MTB_RECIPE__VSCODE_STATIC_SECTION) $(SS_START_LMA) verify
_MTB_RECIPE__READ_STATIC_SECT=flash read_bank 0 s.bin $(SS_START_OFFSET) $(SS_SIZE)
_MTB_RECIPE__RESTORE_STATIC_SECT=program s.bin $(SS_START_LMA) verify
ifeq ($(VS_ERASE),1)
ifeq ($(SS_CONFIG),1)
# program application, program static section
_MTB_RECIPE__ECLIPSE_POST_CONNECT_COMMANDS=
_MTB_RECIPE__ECLIPSE_OTHER_RUN_COMMANDS=monitor $(_MTB_RECIPE__ECLIPSE_PROGRAM_STATIC_SECT_CMD)
_MTB_RECIPE__ECLIPSE_PROGRAM_CONFIG_CMD=$(_MTB_RECIPE__PROGRAM_MAIN_APP_CMD); $(_MTB_RECIPE__ECLIPSE_PROGRAM_STATIC_SECT_CMD)
_MTB_RECIPE__ECLIPSE_JLINK_OTHER_RUN_COMMANDS=restore $(_MTB_RECIPE__ECLIPSE_STATIC_SECTION) binary $(SS_START_LMA)$(_MTB_RECIPE__ECLIPSE_NEWLINE)monitor reset$(_MTB_RECIPE__ECLIPSE_NEWLINE)
else
# Read static section, program application and restore static section
_MTB_RECIPE__ECLIPSE_POST_CONNECT_COMMANDS=-c &quot;cmsis_flash init; $(_MTB_RECIPE__READ_STATIC_SECT)&quot;
_MTB_RECIPE__ECLIPSE_OTHER_RUN_COMMANDS=monitor $(_MTB_RECIPE__RESTORE_STATIC_SECT)
_MTB_RECIPE__ECLIPSE_PROGRAM_CONFIG_CMD=init; reset init; cmsis_flash init; $(_MTB_RECIPE__READ_STATIC_SECT); $(_MTB_RECIPE__PROGRAM_MAIN_APP_CMD); $(_MTB_RECIPE__RESTORE_STATIC_SECT)
endif #($(SS_CONFIG),1)
else #($(VS_ERASE),1)
ifeq ($(SS_CONFIG),1)
# program application, program static section
_MTB_RECIPE__ECLIPSE_POST_CONNECT_COMMANDS=
_MTB_RECIPE__ECLIPSE_OTHER_RUN_COMMANDS=monitor $(_MTB_RECIPE__ECLIPSE_PROGRAM_STATIC_SECT_CMD)
_MTB_RECIPE__ECLIPSE_PROGRAM_CONFIG_CMD=$(_MTB_RECIPE__PROGRAM_MAIN_APP_CMD); $(_MTB_RECIPE__ECLIPSE_PROGRAM_STATIC_SECT_CMD)
_MTB_RECIPE__ECLIPSE_JLINK_OTHER_RUN_COMMANDS=restore $(_MTB_RECIPE__ECLIPSE_STATIC_SECTION) binary $(SS_START_LMA)$(_MTB_RECIPE__ECLIPSE_NEWLINE)monitor reset$(_MTB_RECIPE__ECLIPSE_NEWLINE)
else
# program application only
_MTB_RECIPE__ECLIPSE_POST_CONNECT_COMMANDS=
_MTB_RECIPE__ECLIPSE_OTHER_RUN_COMMANDS=
_MTB_RECIPE__ECLIPSE_PROGRAM_CONFIG_CMD=program $(_MTB_RECIPE__ECLIPSE_PROG_FILE)
endif
endif
endif
_MTB_RECIPE__ECLIPSE_LAUNCH_APP_COMMANDS=set $$pc = &amp;$(PC_SYMBOL)$(_MTB_RECIPE__ECLIPSE_NEWLINE)set $$sp = &amp;$(SP_SYMBOL)$(_MTB_RECIPE__ECLIPSE_NEWLINE)
endif #(,$(_MTB_RECIPE__IS_DIE_PSC3))

#
# The max external memory size supported
# This is not the amount that is available on the board
#
CY_MEMORY_EXTERNAL_FLASH=0x08000000

ifeq (,$(_MTB_RECIPE__IS_DIE_PSC3))
# Map APP_SECURITY_TYPE to VCORE_ATTRS for BWC when VCORE_ATTRS has no SECURE or NON_SECURE values set. 
ifeq ($(filter SECURE NON_SECURE,$(VCORE_ATTRS)),)
ifeq ($(APP_SECURITY_TYPE),SECURE)
VCORE_ATTRS+=SECURE
else ifeq ($(APP_SECURITY_TYPE),NORMAL_NO_SECURE)
VCORE_ATTRS+=NON_SECURE
endif # ($(APP_SECURITY_TYPE),SECURE)
endif # ($(filter SECURE NON_SECURE,$(VCORE_ATTRS)),)

# DEVICE_MODE BWC
ifeq ($(DEVICE_LIFE_CYCLE_STATE),)
ifneq ($(DEVICE_MODE),)
DEVICE_LIFE_CYCLE_STATE=$(DEVICE_MODE)
endif # ($(DEVICE_MODE),)
endif # ($(DEVICE_LIFE_CYCLE_STATE),)
endif # (,$(_MTB_RECIPE__IS_DIE_PSC3))
