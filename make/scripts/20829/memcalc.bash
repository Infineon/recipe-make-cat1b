#!/bin/bash
#
# Copyright 2020-2025, Cypress Semiconductor Corporation (an Infineon company) or
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
(set -o igncr) 2>/dev/null && set -o igncr; # this comment is required
set -$-ue${DEBUG+xv}

#######################################################################################################################
# This script processes the memory consumption of an application and prints it out to the console.
#
# usage:
#	memcalc.bash <READELFFILE> <TOTAL_XIP> <START_XIP>
#
#######################################################################################################################

READELFFILE=$1              # file location of readelf output
AVAILABLEXIP=$2           # Max available external flash
STARTXIP=$3               # Start of exteral flash

ENDXIP=$((STARTXIP + AVAILABLEXIP))

# Gather the numbers
memcalc() {
    local externalFlash=0

    printf "   ---------------------------------------------------- \n"
    printf "  | %-20s |  %-10s   |  %-10s | \n" 'Section Name' 'Address' 'Size'
    printf "   ---------------------------------------------------- \n"

    while IFS=$' \t\n\r' read -r line; do
        local lineArray
        read -r -a lineArray <<<"$line"
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
                    if [[ ${lineArray[$idx]} == *"]" ]] && [[ $sectionElement == NULL ]]; then
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

                fi
            # Program headers
            elif [[ ${lineArray[1]} == "0x"* ]] && [[ ${lineArray[2]} == "0x"* ]] && [[ ${lineArray[3]} == "0x"* ]] && [[ ${lineArray[4]} == "0x"* ]]\
                && [[ ${lineArray[3]} -ge "$STARTXIP" ]] && [[ ${lineArray[3]} -lt "$ENDXIP" ]] && [[ ${lineArray[0]} != "EXIDX" ]]; then
                # Use the program headers for Flash tally
                externalFlash=$((externalFlash+${lineArray[4]}))
            fi
        fi
    done < "$READELFFILE"

    printf "   ---------------------------------------------------- \n\n"
    printf "  %-41s %-10s \n\n" 'Total External Flash (Utilized)' $externalFlash
}

memcalc
