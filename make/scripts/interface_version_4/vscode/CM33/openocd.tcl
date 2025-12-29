&&_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER&&
source [find interface/kitprog3.cfg]
&&_MTB_RECIPE__VSCODE_OPENOCD_PROBE_SERIAL_CMD&&
transport select &&_MTB_RECIPE__PROBE_INTERFACE&&
source [find target/&&_MTB_RECIPE__OPEN_OCD_FILE&&]
&&_MTB_RECIPE__OPENOCD_CHIP&&.cm33 configure -rtos auto -rtos-wipe-on-reset-halt 1
gdb_breakpoint_override hard
CDLiveWatchSetup//PSC3 Only//
if {$::ENABLE_ACQUIRE} {//PSC3 Only//
    init//PSC3 Only//
    reset init//PSC3 Only//
}//PSC3 Only//

proc CDLiveWatchSetup {} {//PSC3 Only//
}//PSC3 Only//