################################################################################
# \file defines.mk
#
# \brief
# Defines, needed for the Player build recipe.
#
################################################################################
# \copyright
# Copyright 2018-2023 Cypress Semiconductor Corporation
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

#
# Architecure specifics
#
_MTB_RECIPE__OPENOCD_CHIP_NAME=cyw20829
_MTB_RECIPE__OPENOCD_DEVICE_CFG=cyw20829.cfg
_MTB_RECIPE__JLINK_DEVICE_CFG=CYW20829_tm

#
# The max external memory size supported
# This is not the amount that is available on the board
#
CY_MEMORY_EXTERNAL_FLASH=0x08000000
