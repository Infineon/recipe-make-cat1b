################################################################################
# \file defines.mk
#
# \brief
# Defines, needed for the AIROC(TM) CYW20829 and PSC3 build recipe.
#
################################################################################
# \copyright
# Copyright (c) 2018-2026, Infineon Technologies AG, or an affiliate of
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

ifeq ($(WHICHFILE),true)
$(info Processing $(lastword $(MAKEFILE_LIST)))
endif

include $(MTB_TOOLS__RECIPE_DIR)/make/recipe/defines_common.mk

################################################################################
# General
################################################################################
_MTB_RECIPE__PROGRAM_INTERFACE_SUPPORTED:=KitProg3 JLink

# Compatibility interface for this recipe make
MTB_RECIPE__INTERFACE_VERSION:=2

MTB_RECIPE__NINJA_SUPPORT:=1 2

# The supported toolchains list
ifdef CY_SUPPORTED_TOOLCHAINS
MTB_SUPPORTED_TOOLCHAINS?=$(CY_SUPPORTED_TOOLCHAINS)
else
MTB_SUPPORTED_TOOLCHAINS?=GCC_ARM IAR ARM A_Clang LLVM_ARM
endif

# For BWC with Makefiles that do anything with CY_SUPPORTED_TOOLCHAINS
CY_SUPPORTED_TOOLCHAINS:=$(MTB_SUPPORTED_TOOLCHAINS)

ifeq ($(MTB_TYPE),PROJECT)
_MTB_RECIPE__IS_MULTI_CORE_APPLICATION:=true
endif

_MTB_RECIPE__ECLIPSE_NEWLINE:=&\#13;&\#10;

################################################################################
# Include device specific defines
################################################################################
ifeq (CYW20829,$(_MTB_RECIPE__DEVICE_DIE))
include $(MTB_TOOLS__RECIPE_DIR)/make/recipe/defines_cyw20829.mk
else
include $(MTB_TOOLS__RECIPE_DIR)/make/recipe/defines_psc3.mk
endif
