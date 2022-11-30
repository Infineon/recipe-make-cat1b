#!/bin/bash
(set -o igncr) 2>/dev/null && set -o igncr; #keep this comment

echo_run() { echo "\$ ${@/eval/}" ; "$@" ; }

# parameters
# 1. toolchain
# 2. path to app
# 3. app name
# 4. python command
# 5. path to script
# 6. gcc bin path

# Combined image configuration
TOOLCHAIN=$1
: ${TOOLCHAIN:=.}

APP_PATH=$2
: ${APP_PATH:=.}

APP_NAME=$3
: ${APP_NAME:=blinky}

PYTHON_COMMAND=$4
: ${PYTHON_COMMAND:=.}

SCRIPT_PATH=$5
: ${SCRIPT_PATH:=.}

if [ "$6" == "" ];then
    NM_TOOL=arm-none-eabi-nm
else
    NM_TOOL="$6"/arm-none-eabi-nm
fi

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
    if ! [ -f $SCRIPT_PATH/bin2hex.py ]; then
        echo "ERROR: $SCRIPT_PATH/bin2hex.py not found"
        exit 1
    fi
    if ! [ -f $SCRIPT_PATH/hexmerge.py ]; then
        echo "ERROR: $SCRIPT_PATH/hexmerge.py not found"
        exit 1
    fi
    if ! [ -f $SCRIPT_PATH/hex2bin.py ]; then
        echo "ERROR: $SCRIPT_PATH/hex2bin.py not found"
        exit 1
    fi
    if ! [ -x "$(command -v awk)" ]; then
        echo "ERROR: awk not found"
        exit 1
    fi
    ########################################################################################################
    BOOTSTRAP_CODE_LMA=`${NM_TOOL} ${APP_ELF} | grep "__bootstrap_code_lma__" | awk '{print $1}'`
    BOOTSTRAP_CODE_VMA=`${NM_TOOL} ${APP_ELF} | grep "__bootstrap_code_vma__" | awk '{print $1}'`
    APP_CODE_LMA=`${NM_TOOL} ${APP_ELF} | grep "__app_code_lma__" | awk '{print $1}'`
    APP_CODE_VMA=`${NM_TOOL} ${APP_ELF} | grep "__app_code_vma__" | awk '{print $1}'`

    BOOTSTRAP_CODE_LMA_INT=$(printf "%d" $((16#$BOOTSTRAP_CODE_LMA)))
    APP_CODE_LMA_INT=$(printf "%d" $((16#$APP_CODE_LMA)))
    APP_FLASH_OFFSET_INT=`expr $APP_CODE_LMA_INT - $BOOTSTRAP_CODE_LMA_INT`
    APP_FLASH_OFFSET_HEX=$(printf "0x%x" $APP_FLASH_OFFSET_INT) #0x81B8

    BOOTSTRAP_CODE_VMA_INT=$(printf "%d" $((16#$BOOTSTRAP_CODE_VMA)))
    APP_CODE_VMA_INT=$(printf "%d" $((16#$APP_CODE_VMA)))

    BOOTSTRAP_BIN=$APP_NAME-$(printf "0x%x" $BOOTSTRAP_CODE_VMA_INT)
    APP_BIN=$APP_NAME-$(printf "0x%x" $APP_CODE_VMA_INT)
    APP_FLASH_OFFSET=$APP_FLASH_OFFSET_HEX

    if ! [ -f $APP_PATH/$BOOTSTRAP_BIN.bin ]; then
        echo "ERROR: $APP_PATH/$BOOTSTRAP_BIN.bin not found"
        exit 1
    fi
    if ! [ -f $APP_PATH/$APP_BIN.bin ]; then
        echo "ERROR: $APP_PATH/$APP_BIN.bin not found"
        exit 1
    fi

    $PYTHON_COMMAND $SCRIPT_PATH/bin2hex.py $APP_PATH/$BOOTSTRAP_BIN.bin $APP_PATH/bootstrap.hex;
    $PYTHON_COMMAND $SCRIPT_PATH/bin2hex.py --offset=$APP_FLASH_OFFSET $APP_PATH/$APP_BIN.bin $APP_PATH/app.hex;
    $PYTHON_COMMAND $SCRIPT_PATH/hexmerge.py $APP_PATH/bootstrap.hex $APP_PATH/app.hex -o $APP_PATH/$APP_NAME.hex;
    $PYTHON_COMMAND $SCRIPT_PATH/hex2bin.py $APP_PATH/$APP_NAME.hex $APP_PATH/$APP_NAME.bin;

elif [ "$TOOLCHAIN" == "ARM" ]; then
    APP_EXT=_int

    APP_ELF=$APP_PATH/$APP_NAME.elf

    #APP_FLASH_OFFSET=$APP_FLASH_OFFSET_HEX
    #APP_FLASH_OFFSET=0x2FB8

    $PYTHON_COMMAND $SCRIPT_PATH/bin2hex.py $APP_PATH/$APP_NAME.bin/bootstrap $APP_PATH/$APP_NAME.bin/bootstrap.hex;
    #$SCRIPT_PATH/bin2hex.py --offset=$APP_FLASH_OFFSET $APP_PATH.bin/app $APP_PATH.bin/app.hex;
    $PYTHON_COMMAND $SCRIPT_PATH/bin2hex.py --offset=0x25B0 $APP_PATH/$APP_NAME.bin/app $APP_PATH/$APP_NAME.bin/app.hex;
    $PYTHON_COMMAND $SCRIPT_PATH/hexmerge.py $APP_PATH/$APP_NAME.bin/bootstrap.hex $APP_PATH/$APP_NAME.bin/app.hex -o $APP_PATH/$APP_NAME.bin/$APP_NAME.hex;
    $PYTHON_COMMAND $SCRIPT_PATH/hex2bin.py $APP_PATH/$APP_NAME.bin/$APP_NAME.hex $APP_PATH/$APP_NAME.bin/$APP_NAME.bin;
    cp $APP_PATH/$APP_NAME.bin/$APP_NAME.bin $APP_PATH/$APP_NAME$APP_EXT.bin;
    rm -rf $APP_PATH/$APP_NAME.bin;
    mv $APP_PATH/$APP_NAME$APP_EXT.bin $APP_PATH/$APP_NAME.bin;

else
    # GCC_ARM does not require additional steps
    echo "Skipping $TOOLCHAIN flash app postbuild step."
fi
