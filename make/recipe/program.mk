################################################################################
# \file program.mk
#
# \brief
# This make file is called recursively and is used to build the
# resoures file system. It is expected to be run from the example directory.
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

include $(MTB_TOOLS__RECIPE_DIR)/make/recipe/program_common.mk

_MTB_RECIPE__GDB_ARGS=$(MTB_TOOLS__RECIPE_DIR)/make/scripts/gdbinit

_MTB_RECIPE__OPENOCD_DEBUG_PREFIX=$(_MTB_RECIPE__OPENOCD_CHIP_NAME).cm33 configure -rtos auto -rtos-wipe-on-reset-halt 1; gdb_breakpoint_override hard;

ifeq ($(TOOLCHAIN),A_Clang)
_MTB_RECIPE__OPENOCD_PROGRAM_IMG=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).bin $(TOOLCHAIN_VECT_BASE_CM33)
else
_MTB_RECIPE__OPENOCD_SYMBOL_IMG=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).$(MTB_RECIPE__SUFFIX_TARGET)
ifeq ($(APPTYPE),ram)
_MTB_RECIPE__OPENOCD_PROGRAM_IMG=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).bin
else
_MTB_RECIPE__OPENOCD_PROGRAM_IMG=$(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(APPNAME).final.bin 0x60000000
endif #ifeq ($(APPTYPE),ram)
endif #($(TOOLCHAIN),A_Clang)

# Multi-core application programming: always use combined HEX image
ifneq ($(_MTB_RECIPE__APP_HEX_FILE),)
_MTB_RECIPE__OPENOCD_PROGRAM_IMG=$(_MTB_RECIPE__APP_HEX_FILE)
endif

# Use custom HEX image when PROG_FILE was provided by the user
ifneq ($(PROG_FILE),)
_MTB_RECIPE__OPENOCD_PROGRAM_IMG=$(PROG_FILE)
endif

ifeq ($(APPTYPE),ram)
ifeq ($(filter erase,$(MAKECMDGOALS)),erase)
$(call mtb__error, Unable to proceed. program and erase is not supported for APPTYPE=$(APPTYPE))
endif
_MTB_RECIPE_APP_LOAD_ADDR=0x20004200
_MTB_RECIPE_APP_SP=$(_MTB_RECIPE_APP_LOAD_ADDR)
_MTB_RECIPE_APP_PC=$(shell printf "0x%x" $$(($(_MTB_RECIPE_APP_LOAD_ADDR) + 0x04)))
_MTB_RECIPE_OPENOCD_PREPARE_APP=init; reset init; load_image $(_MTB_RECIPE__OPENOCD_PROGRAM_IMG) $(_MTB_RECIPE_APP_LOAD_ADDR); reg sp [mrw $(_MTB_RECIPE_APP_SP)]; reg pc [mrw $(_MTB_RECIPE_APP_PC)];
_MTB_RECIPE_OPENOCD_DEBUG=$(_MTB_RECIPE__OPENOCD_DEBUG_PREFIX) $(_MTB_RECIPE_OPENOCD_PREPARE_APP)
_MTB_RECIPE_OPENOCD_PROGRAM=$(_MTB_RECIPE_OPENOCD_PREPARE_APP) resume; exit;

else #($(APPTYPE),ram)
_MTB_RECIPE_OPENOCD_ERASE=init; reset init; erase_all; exit;
_MTB_RECIPE_OPENOCD_DEBUG=$(_MTB_RECIPE__OPENOCD_DEBUG_PREFIX) init; reset init;
ifeq ($(VS_ERASE),1)
ifeq ($(SS_CONFIG),1)
# program application, program static section
_MTB_RECIPE_OPENOCD_PROGRAM=program $(_MTB_RECIPE__OPENOCD_PROGRAM_IMG) verify; program $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(SS_BIN_FILE) $(SS_START_LMA) verify reset exit;
_MTB_RECIPE__OPENOCD_ADDITIONAL_IMG=LoadFile $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(SS_BIN_FILE) $(SS_START_LMA) reset
else
# Read static section, program application and restore static section
_MTB_RECIPE_OPENOCD_PROGRAM=init; reset init; cmsis_flash init; flash read_bank 0 s.bin $(SS_START_OFFSET) $(SS_SIZE); program $(_MTB_RECIPE__OPENOCD_PROGRAM_IMG) verify; program s.bin $(SS_START_LMA) verify reset exit;
endif #($(SS_CONFIG),1)
else #($(VS_ERASE),1)
ifeq ($(SS_CONFIG),1)
# program application, program static section
_MTB_RECIPE_OPENOCD_PROGRAM=program $(_MTB_RECIPE__OPENOCD_PROGRAM_IMG) verify; program $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(SS_BIN_FILE) $(SS_START_LMA) verify reset exit;
_MTB_RECIPE__OPENOCD_ADDITIONAL_IMG=LoadFile $(MTB_TOOLS__OUTPUT_CONFIG_DIR)/$(SS_BIN_FILE) $(SS_START_LMA) reset
else
# program application only
ifeq ($(ERASE_OPTION),skip)
_MTB_RECIPE_OPENOCD_PROGRAM=init; reset init; flash write_image $(_MTB_RECIPE__OPENOCD_PROGRAM_IMG); verify_image $(_MTB_RECIPE__OPENOCD_PROGRAM_IMG); reset run; shutdown;
else ifeq ($(ERASE_OPTION),chip)
_MTB_RECIPE_JLINK_CMDFILE_ERASE=Erase
_MTB_RECIPE_OPENOCD_PROGRAM=init; reset init; erase_all; flash write_image $(_MTB_RECIPE__OPENOCD_PROGRAM_IMG); verify_image $(_MTB_RECIPE__OPENOCD_PROGRAM_IMG); reset run; shutdown;
else #($(ERASE_OPTION),skip)
_MTB_RECIPE_OPENOCD_PROGRAM=program $(_MTB_RECIPE__OPENOCD_PROGRAM_IMG) verify reset exit;
endif #($(ERASE_OPTION),skip)
endif #($(SS_CONFIG),1)
endif #($(VS_ERASE),1)
endif #($(APPTYPE),ram)

_MTB_RECIPE__OPENOCD_ERASE_ARGS=$(_MTB_RECIPE__OPENOCD_SCRIPTS) $(_MTB_RECIPE__OPENOCD_QSPI) -c \
					"$(_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER); $(_MTB_RECIPE__OPENOCD_INTERFACE) $(_MTB_RECIPE__OPENOCD_TARGET) $(_MTB_RECIPE_OPENOCD_CUSTOM_COMMAND) $(_MTB_RECIPE_OPENOCD_ERASE)"
_MTB_RECIPE__OPENOCD_PROGRAM_ARGS=$(_MTB_RECIPE__OPENOCD_SCRIPTS) $(_MTB_RECIPE__OPENOCD_QSPI) -c \
					"$(_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER); $(_MTB_RECIPE__OPENOCD_INTERFACE) $(_MTB_RECIPE__OPENOCD_TARGET) $(_MTB_RECIPE_OPENOCD_CUSTOM_COMMAND) $(_MTB_RECIPE_OPENOCD_PROGRAM)"
_MTB_RECIPE__OPENOCD_DEBUG_ARGS=$(_MTB_RECIPE__OPENOCD_SCRIPTS) $(_MTB_RECIPE__OPENOCD_QSPI) -c \
					"$(_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER); $(_MTB_RECIPE__OPENOCD_INTERFACE) $(_MTB_RECIPE__OPENOCD_TARGET) $(_MTB_RECIPE_OPENOCD_CUSTOM_COMMAND) $(_MTB_RECIPE_OPENOCD_DEBUG)"


_MTB_RECIPE__JLINK_DEVICE_CFG_PROGRAM=$(_MTB_RECIPE__JLINK_DEVICE_CFG)
_MTB_RECIPE__JLINK_DEBUG_ARGS=-if swd -device $(_MTB_RECIPE__JLINK_DEVICE_CFG) -endian little -speed auto -port 2334 -swoport 2335 -telnetport 2336 -vd -ir -localhostonly 1 -singlerun -strict -timeout 0 -nogui