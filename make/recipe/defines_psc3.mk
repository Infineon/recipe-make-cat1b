################################################################################
# \file defines_psc3.mk
#
# \brief
# Definitions specific for PSC3 devices.
#
################################################################################
# \copyright
# Copyright (c) 2025-2026, Infineon Technologies AG, or an affiliate of
# Infineon Technologies AG. All rights reserved.
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

# Definitions common for PSC3 devieces
_MTB_RECIPE__IS_DIE_PSC3=true

# Compatible export interfaces for PSC3 devices
MTB_RECIPE__EXPORT_INTERFACES:=2 3 4 5

#
# Define the default device mode
#
VCORE_ATTRS?=

# Device has internal memory only
ifneq ($(filter SECURE,$(VCORE_ATTRS)),)
_MTB_RECIPE__START_FLASH=0x12000000
else
_MTB_RECIPE__START_FLASH=0x02000000
endif

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


# OpenOCD defines
_MTB_RECIPE__ECLIPSE_OPENOCD_ATTACH_DO_CONTINUE:=true
_MTB_RECIPE__ECLIPSE_OPENOCD_ATTACH_OTHER_RUN_COMMANDS:=flushregs

ifneq (ram,$(APPTYPE))
_MTB_RECIPE__ECLIPSE_OPENOCD_DEBUG_OTHER_RUN_COMMANDS:=flushregs$(_MTB_RECIPE__ECLIPSE_NEWLINE)$(_MTB_RECIPE__ECLIPSE_LAUNCH_APP_COMMANDS)monitor reset init
else
_MTB_RECIPE__ECLIPSE_OPENOCD_DEBUG_OTHER_RUN_COMMANDS:=flushregs$(_MTB_RECIPE__ECLIPSE_NEWLINE)$(_MTB_RECIPE__ECLIPSE_LAUNCH_APP_COMMANDS)mon $(_MTB_RECIPE__OPENOCD_CHIP_NAME).cm33 cortex_m vector_catch reset&\#13;&\#10;set {int}0x52161000=0x34000000&\#13;&\#10;set {int}0x52160004=0x05FA0000&\#13;&\#10;monitor $(_MTB_RECIPE__OPENOCD_CHIP_NAME).cm33 arp_waitstate halted 5000&\#13;&\#10;mon $(_MTB_RECIPE__OPENOCD_CHIP_NAME).cm33 cortex_m vector_catch none
endif

_MTB_RECIPE__ECLIPSE_OPENOCD_ATTACH_POST_TARGET_COMMANDS=-c $(_MTB_RECIPE__ECLIPSE_QUOT)$(_MTB_RECIPE__OPENOCD_CHIP_NAME).$(_MTB_RECIPE__OPENOCD_DEBUG_TARGET_CORE) configure -rtos auto -rtos-wipe-on-reset-halt 1$(_MTB_RECIPE__ECLIPSE_QUOT)$(_MTB_RECIPE__ECLIPSE_NEWLINE)-c $(_MTB_RECIPE__ECLIPSE_QUOT)gdb_breakpoint_override hard$(_MTB_RECIPE__ECLIPSE_QUOT)

# JLink defines
_MTB_RECIPE__ECLIPSE_JLINK_DEBUG_GDB_SERVER_DEVICE_NAME:=$(_MTB_RECIPE__JLINK_DEVICE_CFG)
_MTB_RECIPE__ECLIPSE_JLINK_DEBUG_GDB_CLIENT_OTHER_COMMANDS:=set mem inaccessible-by-default off$(_MTB_RECIPE__ECLIPSE_NEWLINE)set remotetimeout 25
_MTB_RECIPE__ECLIPSE_JLINK_DEBUG_OTHER_RUN_COMMANDS:=$(_MTB_RECIPE__ECLIPSE_LAUNCH_APP_COMMANDS)monitor reset
_MTB_RECIPE__ECLIPSE_JLINK_DEBUG_FIRST_RESET_TYPE:=0
_MTB_RECIPE__ECLIPSE_JLINK_DEBUG_SECOND_RESET_TYPE:=0

_MTB_RECIPE__ECLIPSE_JLINK_ATTACH_FIRST_RESET_TYPE:=0
_MTB_RECIPE__ECLIPSE_JLINK_ATTACH_SECOND_RESET_TYPE:=0
_MTB_RECIPE__ECLIPSE_JLINK_ATTACH_GDB_SERVER_DEVICE_NAME:=$(_MTB_RECIPE__JLINK_CFG_ATTACH)
_MTB_RECIPE__ECLIPSE_JLINK_ATTACH_GDB_CLIENT_OTHER_COMMANDS:=$(_MTB_RECIPE__ECLIPSE_JLINK_DEBUG_GDB_CLIENT_OTHER_COMMANDS)