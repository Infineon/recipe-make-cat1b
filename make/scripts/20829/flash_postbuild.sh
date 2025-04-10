#!/bin/bash
#
# Copyright 2022-2025, Cypress Semiconductor Corporation (an Infineon company) or
# an affiliate of Cypress Semiconductor Corporation.  All rights reserved.
#
# This software, including source code, documentation and related
# materials ("Software") is owned by Cypress Semiconductor Corporation
# or one of its affiliates ("Cypress") and is protected by and subject to
# worldwide patent protection (United States and foreign),
# United States copyright laws and international treaty provisions.
# Therefore, you may use this Software only as provided in the license
# agreement accompanying the software package from which you
# obtained this Software ("EULA").
# If no EULA applies, Cypress hereby grants you a personal, non-exclusive,
# non-transferable license to copy, modify, and compile the Software
# source code solely for use in connection with Cypress's
# integrated circuit products.  Any reproduction, modification, translation,
# compilation, or representation of this Software except as specified
# above is prohibited without the express written permission of Cypress.
#
# Disclaimer: THIS SOFTWARE IS PROVIDED AS-IS, WITH NO WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, NONINFRINGEMENT, IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Cypress
# reserves the right to make changes to the Software without notice. Cypress
# does not assume any liability arising out of the application or use of the
# Software or any product or circuit described in the Software. Cypress does
# not authorize its products for use in any products where a malfunction or
# failure of the Cypress product may reasonably be expected to result in
# significant property damage, injury or death ("High Risk Product"). By
# including Cypress's product in a High Risk Product, the manufacturer
# of such system or application assumes all risk of such use and in doing
# so agrees to indemnify Cypress against all liability.
#
(set -o igncr) 2>/dev/null && set -o igncr; #keep this comment

echo_run() { echo "\$ ${@/eval/}" ; "$@" ; }

# parameters
# 1. toolchain
# 2. path to app
# 3. app name
# 4. gcc bin path
# 5. path of srec_cat

# Combined image configuration
TOOLCHAIN=$1
: ${TOOLCHAIN:=.}

APP_PATH=$2
: ${APP_PATH:=.}

APP_NAME=$3
: ${APP_NAME:=blinky}

if [ "$4" == "" ];then
    NM_TOOL=arm-none-eabi-nm
else
    NM_TOOL="$4"/arm-none-eabi-nm
fi

SREC_CAT_UTIL=$5
: ${SREC_CAT_UTIL:=srec_cat}

BOOTSTRAP_SIZE=${6}
: ${BOOTSTRAP_SIZE:=0x00002400}

FLASH_ALIGNMENT_SIZE=0x00000200
BOOTSTRAP_OFFSET_FLASH=0x00000050 # toc2=0x10, l1_desc=0x1C, sign_header=0x20 and 16byte aligned.
APPCODE_OFFSET_FLASH=$(printf "0x%x" $(($BOOTSTRAP_SIZE + $FLASH_ALIGNMENT_SIZE)))
APP_FLASH_OFFSET=$(printf "0x%x" $(($APPCODE_OFFSET_FLASH - $BOOTSTRAP_OFFSET_FLASH)))

if [ "$TOOLCHAIN" == "IAR" ]; then

    APP_ELF=$APP_PATH/$APP_NAME.elf

    ######################################### Validate Input Parameters ####################################
    if ! [ -x $NM_TOOL ]; then
        echo "ERROR: $NM_TOOL not found"
        exit 1
    fi
    if ! [ -f $APP_ELF ]; then
        echo "ERROR: $APP_ELF not found"
        exit 1
    fi
    if ! [ -f $SREC_CAT_UTIL ]; then
        echo "ERROR: $SREC_CAT_UTIL not found"
        exit 1
    fi
    if ! [ -x "$(command -v awk)" ]; then
        echo "ERROR: awk not found"
        exit 1
    fi
    ########################################################################################################
    BOOTSTRAP_CODE_VMA=`${NM_TOOL} ${APP_ELF} | grep "__bootstrap_code_vma__" | awk '{print $1}'`
    APP_CODE_VMA=`${NM_TOOL} ${APP_ELF} | grep "__app_code_vma__" | awk '{print $1}'`

    BOOTSTRAP_CODE_VMA_INT=$(printf "%d" $((16#$BOOTSTRAP_CODE_VMA)))
    APP_CODE_VMA_INT=$(printf "%d" $((16#$APP_CODE_VMA)))

    BOOTSTRAP_BIN=$APP_NAME-$(printf "0x%x" $BOOTSTRAP_CODE_VMA_INT)
    APP_BIN=$APP_NAME-$(printf "0x%x" $APP_CODE_VMA_INT)

    if ! [ -f $APP_PATH/$BOOTSTRAP_BIN.bin ]; then
        echo "ERROR: $APP_PATH/$BOOTSTRAP_BIN.bin not found"
        exit 1
    fi
    if ! [ -f $APP_PATH/$APP_BIN.bin ]; then
        echo "ERROR: $APP_PATH/$APP_BIN.bin not found"
        exit 1
    fi

    $SREC_CAT_UTIL $APP_PATH/$BOOTSTRAP_BIN.bin -Binary -o $APP_PATH/bootstrap.hex -Intel -Output_Block_Size=16;
    $SREC_CAT_UTIL $APP_PATH/$APP_BIN.bin -Binary -offset $APP_FLASH_OFFSET -o $APP_PATH/app.hex -Intel -Output_Block_Size=16;
    $SREC_CAT_UTIL $APP_PATH/bootstrap.hex -Intel $APP_PATH/app.hex -Intel -o $APP_PATH/$APP_NAME.hex -Intel -Output_Block_Size=16;
    $SREC_CAT_UTIL $APP_PATH/$APP_NAME.hex -Intel -o $APP_PATH/$APP_NAME.bin -Binary;

elif [ "$TOOLCHAIN" == "ARM" ]; then
    APP_EXT=_int

    APP_ELF=$APP_PATH/$APP_NAME.elf

    #APP_FLASH_OFFSET=$APP_FLASH_OFFSET_HEX
    #APP_FLASH_OFFSET=0x2FB8

    $SREC_CAT_UTIL $APP_PATH/$APP_NAME.bin/bootstrap -Binary -o $APP_PATH/$APP_NAME.bin/bootstrap.hex -Intel -Output_Block_Size=16;
    #$SCRIPT_PATH/bin2hex.py --offset=$APP_FLASH_OFFSET $APP_PATH.bin/app $APP_PATH.bin/app.hex;
    $SREC_CAT_UTIL $APP_PATH/$APP_NAME.bin/app -Binary -offset $APP_FLASH_OFFSET -o $APP_PATH/$APP_NAME.bin/app.hex -Intel -Output_Block_Size=16;
    $SREC_CAT_UTIL $APP_PATH/$APP_NAME.bin/bootstrap.hex -Intel $APP_PATH/$APP_NAME.bin/app.hex -Intel -o $APP_PATH/$APP_NAME.bin/$APP_NAME.hex -Intel -Output_Block_Size=16;
    $SREC_CAT_UTIL $APP_PATH/$APP_NAME.bin/$APP_NAME.hex -Intel -o $APP_PATH/$APP_NAME.bin/$APP_NAME.bin -Binary;
    cp $APP_PATH/$APP_NAME.bin/$APP_NAME.bin $APP_PATH/$APP_NAME$APP_EXT.bin;
    rm -rf $APP_PATH/$APP_NAME.bin;
    mv $APP_PATH/$APP_NAME$APP_EXT.bin $APP_PATH/$APP_NAME.bin;

else
    # GCC_ARM does not require additional steps
    echo "Skipping $TOOLCHAIN flash app postbuild step."
fi
