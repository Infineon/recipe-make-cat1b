&&_MTB_RECIPE__OPENOCD_QSPI_FLASHLOADER&&
source [find interface/kitprog3.cfg]
&&_MTB_RECIPE__VSCODE_OPENOCD_PROBE_SERIAL_CMD&&
transport select &&_MTB_RECIPE__PROBE_INTERFACE&&
source [find target/&&_MTB_RECIPE__OPEN_OCD_FILE&&]
&&_MTB_RECIPE__OPENOCD_TARGET_VAR&&.cm33 configure -rtos auto -rtos-wipe-on-reset-halt 1
gdb_breakpoint_override hard