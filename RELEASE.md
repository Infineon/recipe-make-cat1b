### AIROC™ CYW20829 and PSOC™ Control C3 GNU make Build System
This repo provides the build recipe make files and scripts for building and programming AIROC™ CYW20829 and PSOC™ Control C3 applications. Builds can be run either through a command-line interface (CLI) or through a supported IDE such as Eclipse or VS Code.

### What's Included?
This release of the AIROC™ CYW20829 and PSOC™ Control C3 GNU make build recipe includes complete support for building, programming, and debugging AIROC™ CYW20829 and PSOC™ Control C3 application projects. It is expected that a code example contains a top level make file for itself and references a Board Support Package (BSP) that defines specific items, like the AIROC™ CYW20829 or PSOC™ Control C3 part, for the target board. Supported functionality includes the following:

* Supported operations:
    * Build
    * Program
    * Debug
    * IDE Integration (Eclipse, VS Code, IAR, uVision)
* Supported toolchains:
    * GCC
    * IAR
    * ARM Compiler 6
    * LLVM Embedded Toolchain for Arm (Experimental)

### What Changed?
#### v2.8.0
* Moved CFLAGS, CXXFLAGS, ASFLAGS, LDFLAGS variables to be added after default flags. In case of conflict, most toolchains select the last flags as the option. This allows those variables to overwrite the default flags.
* Added support for GNU assembly syntax when using ARM toolchain.
* Improved support for LLVM Embedded Toolchain for Arm.

#### v2.7.0
* Added Ninja support. Ninja build will be enabled by default with ModusToolbox 3.4, and latest core-make. To disable Ninja build set NINJA to empty-String. (For example: "make build NINJA=").

#### v2.6.0
* PSOC™ Control C3 device support added.

#### v2.5.1
* Fixed a postbuild dependency that could cause memcalc to fail.

#### v2.5.0
* Experimental support for LLVM Embedded Toolchain for Arm.
* Optimization for speed changed to optimization for size for the IAR toolchain.
* The feature of setting the default location of the ARM and IAR toolchains has been deprecated.
* Added support for Infineon EdgeProtectTool.
* Added task in VS Code export's tasks.json in multicore application to only build the current project.
* Added option for Eclipse export to only build the current project in multicore application.
* Added launch configurations for Eclipse and VS Code to only program/debug a single project in multi-core application.
* Added a "last_config" build configuration directory that contains the hex file and elf file from last build.
* VS Code and Eclipse launch configurations now use "last_config" directory. Launch configurations no longer have to be re-generated when switching between "Debug" and "Release".

#### v2.3.1
* Minor bug fixes.

#### v2.3.0
* Updated programming flow to support loading of additional images required for some code examples.

#### v2.2.1
* Added support for BSP_PROGRAM_INTERFACE to select debug interface. Valid values are "KitProg3" and "JLink". Default value is "KitProg3".
* Eclipse and VS Code export will now only generate the launch configurations for the selected programming interface.

#### v2.0.0
* Major version update. Significant changes to support ModusToolbox 3.0
* Dropped compatibility with core-make version 1.X and ModusToolbox tools version 2.X

#### v1.0.0
* Initial release

### Product/Asset Specific Instructions
Builds require that the ModusToolbox tools be installed on your machine. This comes with the ModusToolbox install. On Windows machines, it is recommended that CLI builds be executed using the Cygwin.bat located in ModusToolBox/tools_x.y/modus-shell install directory. This guarantees a consistent shell environment for your builds.

To list the build options, run the "help" target by typing "make help" in CLI. For a verbose documentation on a specific subject type "make help CY_HELP={variable/target}", where "variable" or "target" is one of the listed make variables or targets.

### Supported Software and Tools
This version of the AIROC™ CYW20829 and PSOC™ Control C3 build system was validated for compatibility with the following Software and Tools:

| Software and Tools                        | Version |
| :---                                      | :----:  |
| ModusToolbox Software Environment         | 3.5     |
| GCC Compiler                              | 11.3    |
| IAR Compiler                              | 9.3     |
| ARM Compiler                              | 6.16    |

Minimum required ModusToolbox Software Environment: v3.4

### More information
* [Infineon GitHub](https://github.com/Infineon)
* [ModusToolbox](https://www.infineon.com/cms/en/design-support/tools/sdk/modustoolbox-software)

---
(c) 2022-2025, Cypress Semiconductor Corporation (an Infineon company) or an affiliate of Cypress Semiconductor Corporation. All rights reserved.
