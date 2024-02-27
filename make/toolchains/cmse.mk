############################################################################### 
# \file cmse.mk
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

ifeq ($(WHICHFILE),true)
$(info Processing $(lastword $(MAKEFILE_LIST)))
endif

ifeq ($(TRUSTZONE_VENEER),)
# default to a directory that don't contains $(CONFIG) subdirectory. The secure and non-secure project may have different $(CONFIG) settings.
_MTB_RECIPE__TRUSTZONE_VENEER:=../shared/trustzone/mtb_secure_veneer.o
else
_MTB_RECIPE__TRUSTZONE_VENEER=$(TRUSTZONE_VENEER)
endif

# The veneer files need to be copy back from the temp file back into the none temp version.
ifneq ($(filter TRUSTZONE_SECURE,$(VCORE_ATTRS)),)
_mtb_cmse_post_build_copy:$(_MTB_RECIPE__TARG_FILE)
	$(MTB__NOISE)mv -f $(_MTB_RECIPE__TRUSTZONE_VENEER).tmp $(_MTB_RECIPE__TRUSTZONE_VENEER)

recipe_postbuild:_mtb_cmse_post_build_copy

$(_MTB_RECIPE__TARG_FILE):_mtb_cmse_mkdir

_mtb_cmse_mkdir:
	$(MTB__NOISE)mkdir -p $(dir $(_MTB_RECIPE__TRUSTZONE_VENEER))

.PHONY:_mtb_cmse_post_build_copy _mtb_cmse_mkdir
endif
