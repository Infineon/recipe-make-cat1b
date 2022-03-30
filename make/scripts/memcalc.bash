#!/bin/bash
(set -o igncr) 2>/dev/null && set -o igncr; # this comment is required
set -$-ue${DEBUG+xv}

#######################################################################################################################
# This script processes the memory consumption of an application and prints it out to the console.
#
# usage:
#	memcalc.bash <READELFFILE> <AVAILABLESRAM> <STARTSRAM> <TOTAL_XIP> <START_XIP>
#
#######################################################################################################################

READELFFILE=$1              # file location of readelf output
AVAILABLESRAM=$2            # Max available external SRAM
STARTSRAM=$3                # Start of internal SRAM
AVAILABLEXIP=$4           # Max available external flash
STARTXIP=$5               # Start of exteral flash

ENDXIP=$((STARTXIP + AVAILABLEXIP))
ENDSRAM=$((STARTSRAM + AVAILABLESRAM))

# Gather the numbers
memcalc() {
    local externalFlash=0
    local internalSram=0

    printf "   ---------------------------------------------------- \n"
    printf "  | %-20s |  %-10s   |  %-10s | \n" 'Section Name' 'Address' 'Size'
    printf "   ---------------------------------------------------- \n"

    while IFS=$' \t\n\r' read -r line; do
        local lineArray=($line)
        local numElem=${#lineArray[@]}

        # Only look at potentially valid lines
        if [[ $numElem -ge 6 ]]; then
            # Section headers
            if [[ ${lineArray[0]} == "["* ]]; then
                local sectionElement=NULL
                local addrElement=00000000
                local sizeElement=000000
                for (( idx = 0 ; idx <= $numElem-4 ; idx = $idx+1 ));
                do
                    if [[ ${lineArray[$idx]} == *"]" ]]; then
                        sectionElement=${lineArray[$idx+1]}
                    fi
                    # Look for regions with SHF_ALLOC = A
                    if [[ ${#lineArray[idx]} -eq 8 ]] && [[ ${#lineArray[idx+1]} -eq 6 ]] && [[ ${#lineArray[idx+2]} -ge 6 ]] && [[ ${#lineArray[idx+2]} -le 7 ]]\
                       && [[ ${lineArray[$idx+4]} == *"A"* ]] ; then
                        addrElement=${lineArray[$idx]}
                        sizeElement=${lineArray[$idx+2]}
                    fi
                done
                heapCheckArray+=($sectionElement)

                # Only consider non-zero size sections
                if [[ $((16#$sizeElement)) != "0" ]]; then
                    printf "  | %-20s |  0x%-10s |  %-10s | \n" $sectionElement $addrElement $((16#$sizeElement))
                    # Use the section headers for SRAM tally
                    if [[ "0x$addrElement" -ge "$STARTSRAM" ]] && [[ "0x$addrElement" -lt "$ENDSRAM" ]]; then
                        internalSram=$((internalSram+$((16#$sizeElement))))
                    fi
                fi
            # Program headers
            elif [[ ${lineArray[1]} == "0x"* ]] && [[ ${lineArray[2]} == "0x"* ]] && [[ ${lineArray[3]} == "0x"* ]] && [[ ${lineArray[4]} == "0x"* ]]\
                && [[ ${lineArray[3]} -ge "$STARTXIP" ]] && [[ ${lineArray[3]} -lt "$ENDXIP" ]]; then
                # Use the program headers for Flash tally
                externalFlash=$((externalFlash+${lineArray[4]}))
            fi
        fi
    done < "$READELFFILE"

    # Check if the SRAM data includes a section for the heap
    # Note: echo | grep can potentially take a while. Do it before printing total numbers
    if echo ${heapCheckArray[@]} | grep -iqF heap; then
        sramIncludesHeap=1
    else
        sramIncludesHeap=0
    fi

    printf "   ---------------------------------------------------- \n\n"
    printf "  %-41s %-10s \n\n" 'Total External Flash (Utilized)' $externalFlash
    printf "  %-41s %-10s \n" 'Total Internal SRAM (Available)' $AVAILABLESRAM
    if [[ $sramIncludesHeap -eq 1 ]]; then
        printf "  %-41s %-10s \n" 'Total Internal SRAM (Utilized with heap)' $internalSram
    else
        printf "  %-41s %-10s \n" 'Total Internal SRAM (Utilized)' $internalSram
    fi
}

memcalc
