# CMakeSDK

The `CMakeSDK` project is a collection of cmake files for primarily for building applications, static libraries for Windows, MacOS, Linux and Stratify OS. It also supports OS packages for Stratify OS.

## Compiling or Cross Compiling

To compile for the native machine, the SDK looks at the name of the build folder. If the folder ends in `_link` (long story as to why that is used) then the SDK will use the native toolchain. To cross-compile for StratifyOS, the build folder should end in `_arm`. My typical approach is to use `cmake_link` and `cmake_arm`. The Stratify OS tools use the prefix `build_` for directories containing elf and binary files. So don't use `build_link` or `build_arm`.

## Modern CMake

The SDK is set up to use a modern `cmake` approach where targets are creating using `add_executable()` or `add_library()` and the targets are modified using:

- `target_sources()`
- `target_compile_options()`
- `target_include_directories()`
- `target_link_libraries()`
- And a few others (well documented by `cmake`).

To use the SDK, you should be familiar with the above functions and how the `PUBLIC`, `PRIVATE` and `INTERFACE` options are used with these functions.

## Target Naming Convention

This SDK creates a naming convention for managing builds for different options, configurations and architectures. 

The naming convetion looks like this:

```
${NAME}_${OPTION}_${CONFIGURATION}_${ARCHITECTURE}
```

- `NAME` is specified by you
- `OPTION` is optional and is also specified by you
- `CONFIGURATION` is typically `release` or `debug`
- ARM cross-compiling `ARCHITECTURE` values are:
  - `v7m`: Cortex M3 (soft float)
  - `v7em`: Cortex M4 (soft float)
  - `v7em_f4sh`: Cortex M4 (hard float)
  - `v7em_f5sh`: Cortex M7 (hard float single precision)
  - `v7em_f5dh`: Cortex M7 (hard float double precision)
- Link `ARCHITECTURE` values are always `link` and build using the host architecture

The SDK includes various functions to create target matrices that use the same source files and are compiled across these options, configurations and architectures.

## The Super project

Most projects that use the `CMakeSDK` using the super project approach. There is one top level project that imports the SDK and then adds projects as needed. The [cli project](https://github.com/StratifyLabs/cli) is a simple example. The [gui project](https://github.com/StratifyLabs/gui) is an advanced example.

For examples of how to create projects that run on Stratify OS:

- [Nucleo 144 Boards](https://github.com/StratifyLabs/StratifyOS-Nucleo144)
- [STM32H735G-DK](https://github.com/StratifyLabs/STM32H735G-DK)
