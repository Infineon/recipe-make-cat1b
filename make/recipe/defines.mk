################################################################################
# \file defines.mk
#
# \brief
# Defines, needed for the Player build recipe.
#
################################################################################
# \copyright
# Copyright 2018-2024 Cypress Semiconductor Corporation
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


################################################################################
# General
################################################################################
_MTB_RECIPE__PROGRAM_INTERFACE_SUPPORTED:=KitProg3 JLink
#
# Compactibility interface for this recipe make
#
MTB_RECIPE__INTERFACE_VERSION:=2

#
# List the supported toolchains
#
CY_SUPPORTED_TOOLCHAINS=GCC_ARM IAR ARM A_Clang

# only has external memory
_MTB_RECIPE__START_FLASH=0
CY_START_EXTERNAL_FLASH=0x60000000

_MTB_RECIPE__ECLIPSE_NEWLINE:=&\#13;&\#10;

#
# Architecure specifics
#
_MTB_RECIPE__OPENOCD_CHIP_NAME:=cyw20829
_MTB_RECIPE__OPENOCD_DEVICE_CFG:=cyw20829.cfg
_MTB_RECIPE__JLINK_DEVICE_CFG:=CYW20829_tm
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

#
# The max external memory size supported
# This is not the amount that is available on the board
#
CY_MEMORY_EXTERNAL_FLASH=0x08000000
