&&CY_OPENOCD_QSPI_FLASHLOADER&&
source [find interface/kitprog3.cfg]
transport select swd
source [find target/&&CY_OPEN_OCD_FILE&&]
${TARGET}.cm33 configure -rtos auto -rtos-wipe-on-reset-halt 1
gdb_breakpoint_override hard