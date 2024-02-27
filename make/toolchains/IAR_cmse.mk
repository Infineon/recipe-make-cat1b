############################################################################### 
# \file ARM_cmse.mk
#
# \brief
# ARM_v8 cmse Compiler toolchain configuration.
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

include $(MTB_TOOLS__RECIPE_DIR)/make/toolchains/cmse.mk

ifeq ($(WHICHFILE),true)
$(info Processing $(lastword $(MAKEFILE_LIST)))
endif

ifneq ($(filter TRUSTZONE_SECURE,$(VCORE_ATTRS)),)
MTB_TOOLCHAIN_IAR__CFLAGS+=--cmse
MTB_TOOLCHAIN_IAR__CXXFLAGS+=--cmse
ifneq ($(filter $(_MTB_RECIPE__TRUSTZONE_VENEER),$(wildcard $(_MTB_RECIPE__TRUSTZONE_VENEER))),)
MTB_TOOLCHAIN_IAR__LDFLAGS+=--import_cmse_lib_in$(_MTB_RECIPE__TRUSTZONE_VENEER)
endif
MTB_TOOLCHAIN_IAR__LDFLAGS+=--import_cmse_lib_out $(_MTB_RECIPE__TRUSTZONE_VENEER).tmp
endif

ifneq ($(filter TRUSTZONE_NON_SECURE,$(VCORE_ATTRS)),)
MTB_TOOLCHAIN_IAR__LDFLAGS+=$(_MTB_RECIPE__TRUSTZONE_VENEER)
endif
