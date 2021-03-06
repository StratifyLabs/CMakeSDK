# CMakeSDK

The CMakeSDK project is a collection of cmake files for primarily for building Stratify OS applications, static libraries and OS packages. The SDK also supports building applications and static libraries on Linux, Windows, and MacOS.

## Compiling or Cross Compiling

To compile for the native machine, the SDK looks at the name of the build folder. If the folder ends in `_link` (long story as to why that is used) then the SDK will use the native toolchain. To cross-compile for StratifyOS, the build folder should end in `_arm`. My typical approach is to use `cmake_link` and `cmake_arm`. The Stratify OS tools use the prefix `build_` for depositing elf and binary files. So it is discouraged to have the build folder start with `build_`.

## Modern CMake

The SDK is set up to use a modern CMake approach where targets are creating using `add_executable()` or `add_library()` and the targets are modified using:

- `target_sources()`
- `target_compile_options()`
- `target_include_directories()`
- `target_link_libraries()`
- And a few others that are well documented by CMake.

To use the SDK, you should be familiar with the above functions and how the `PUBLIC`, `PRIVATE` and `INTERFACE` options are used with these functions.

## Target Naming Convention

This SDK creates a naming convention for managing builds for different options, configurations and architectures. 

The naming convetion looks like this:

```
${NAME}_${OPTION}_${CONFIGURATION}_${ARCHITECTURE}
```

- `NAME` is specified by you
- `OPTION` is optional and is also specified by you
- `CONFIGURATION` is typically `release`, `debug`, or `coverage`
- ARM `ARCHITECTURE` values are:
  - `v7m`: Cortex M3 (soft float)
  - `v7em`: Cortex M4 (soft float)
  - `v7em_f4sh`: Cortex M4 (hard float)
  - `v7em_f5sh`: Cortex M7 (hard float single precision)
  - `v7em_f5dh`: Cortex M7 (hard float double precision)
- Link `ARCHITECTURE` values are always `link`

The SDK includes various functions to help manage creating multiple target matrices that  largely use the same sources and options and need to be compiled across these options, configurations and architectures.

## Install or Use Super project

You can either use `make install` (or `ninja install`) and copy the static libs and cmake export files to the compiler folder, or you can use the super-project approach.

The SDK uses CMake module exports such that targets can easily be shared using either approach.


## Libraries, Applications and OS Packages

Every project should start with the following header:

```
cmake_minimum_required (VERSION 3.12)

if(NOT SOS_SDK_PATH)
	set(SOS_SDK_PATH $ENV{SOS_SDK_PATH})
endif()

set(CMAKE_MODULE_PATH ${SOS_SDK_PATH}/cmake)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_MODULE_PATH}/sos-toolchain.cmake)

include(sos-sdk)
project(my_project CXX C ASM)
```

The environment variable `SOS_SDK_PATH` should point to the Stratify Labs SDK folder that contains a folder called `Tools` and an appropriate GCC cross-compiler. For native compiling, the compiler will be found whatever is available on the `$PATH`.


### Libraries (Desktop or Stratify OS)

Two functions are provided to manage creating libraries:

- `sos_sdk_library_target()`
- `sos_sdk_library_add_arch_targets()`
- `sos_sdk_exclude_arch_from_all()`


To create a library:

```
# form a target name with the name, option, config, and arch
# SOS_ARCH is prefined based on the build folder name
sos_sdk_library_target(RELEASE ${PROJECT_NAME} option release ${SOS_ARCH})

# RELEASE_TARGET and RELEASE_OPTIONS are created by sos_sdk_library_target()

add_library(${RELEASE_TARGET} STATIC)

target_sources(${RELEASE_TARGET}
	PUBLIC
	PRIVATE
	${PRIVATE_SOURCES}
	)

# Now to create DEBUG we make a copy of the above options
sos_sdk_library_target(DEBUG ${PROJECT_NAME} option debug ${SOS_ARCH})
add_library(${DEBUG_TARGET} STATIC)
sos_sdk_copy_target(${RELEASE_TARGET} ${DEBUG_TARGET})

# at this point you can differntiate the builds
target_compile_options(${RELEASE_TARGET}
	PUBLIC
	PRIVATE
	-Os
	)

target_compile_options(${DEBUG_TARGET}
	PUBLIC
	PRIVATE
	-O1
	)

# LIBRARIES will be expanded to ${NAME}_${CONFIG}_${ARCH} to link
# to the appropriate target
set(LIBRARIES mbedtls jansson)

# last thing is to create copies for each architecture: v7m, v7em, etc
# this function will also add some final settings to make everything work
sos_sdk_library_add_arch_targets("${DEBUG_OPTIONS}" ${SOS_ARCH} "${LIBRARIES}")
sos_sdk_library_add_arch_targets("${RELEASE_OPTIONS}" ${SOS_ARCH} "${LIBRARIES}")

# if the library should only target a single arch, you can use (only v7em_f5dh will build with all)
set(SKIP_ARCHES v7m v7em v7em_f4sh v7em_f5sh)
sos_sdk_exclude_arch_from_all(${PROJECT_NAME}_debug "${SKIP_ARCHES}")
sos_sdk_exclude_arch_from_all(${PROJECT_NAME}_release "${SKIP_ARCHES}")
```

### Applications (Desktop or Stratify OS)

Applications follow the same basic template as libraries using these functions:

- `sos_sdk_app_target()`
- `sos_sdk_app_add_arch_targets()`


```
set(RAM_SIZE 16384)
# sos_sdk_app_target create RELEASE_TARGET and RELEASE_OPTIONS variables
sos_sdk_app_target(RELEASE ${PROJECT_NAME} option release ${SOS_ARCH})

add_executable(${RELEASE_TARGET})

# use cmake target_* functions to configure
target_sources(${RELEASE_TARGET}
	PUBLIC
	PRIVATE
	${PRIVATE_SOURCES}
	)

set_property(TARGET ${RELEASE_TARGET} PROPERTY CXX_STANDARD 17)

set(LIBRARIES FsAPI ThreadAPI)

# finalize and copy to all targets
sos_sdk_app_add_arch_targets("${RELEASE_OPTIONS}" "${LIBRARIES}" ${RAM_SIZE})
```

### OS Packages

Again, the same basic approach is taken.

> This is basically the Stratify Toolbox `CMakeLists.txt` file.

```

# each library provides a ${library}.cmake install the the cmake/targets
# folder so that cmake will recognize the installed targets
# if you are using the super-project approach, you don't need
# to include anything
include(StratifyOS)
include(lwip)
include(fatfs)
include(sgfx)
include(mbedtls)
include(StratifyOS_stm32h750xx_debug_v7em_f5dh)
include(StratifyOS_stm32h750xx_release_v7em_f5dh)

# This is a shortcut for pulling in a source only subdirectory
sos_sdk_add_subdirectory(KERNEL_SOURCELIST ${CMAKE_CURRENT_SOURCE_DIR}/src)

# creates BOOT_RELEASE_TARGET and BOOT_RELEASE_OPTIONS
sos_sdk_bsp_target(BOOT_RELEASE ${SOS_NAME} boot release v7em_f5dh)

add_executable(${BOOT_RELEASE_TARGET})
target_sources(${BOOT_RELEASE_TARGET}
	PRIVATE
	${KERNEL_SOURCELIST}
	)

target_include_directories(${BOOT_RELEASE_TARGET}
	PRIVATE
	${CMAKE_CURRENT_SOURCE_DIR}/src
	${CMAKE_CURRENT_SOURCE_DIR}/src/atwinc1500
	${SOS_SDK_PATH}/arm-none-eabi/include/mcu/arch/stm32/cmsis
	${SOS_SDK_PATH}/arm-none-eabi/include
	)

target_compile_definitions(${BOOT_RELEASE_TARGET}
	PRIVATE
	MCU_ARCH_STM32
	${DEFINITIONS}
	)
target_compile_options(${BOOT_RELEASE_TARGET} PUBLIC -Os)


sos_sdk_bsp_target(RAM_DEBUG ${SOS_NAME} ram debug v7em_f5dh)
sos_sdk_bsp_target(BOOT_DEBUG ${SOS_NAME} boot debug v7em_f5dh)
sos_sdk_bsp_target(FLASH_DEBUG ${SOS_NAME} flash debug v7em_f5dh)

add_executable(${RAM_DEBUG_TARGET})
add_executable(${FLASH_DEBUG_TARGET})
sos_sdk_copy_target(${BOOT_RELEASE_TARGET} ${RAM_DEBUG_TARGET})
sos_sdk_copy_target(${BOOT_RELEASE_TARGET} ${FLASH_DEBUG_TARGET})

target_sources(${BOOT_RELEASE_TARGET}
	PRIVATE
	${CMAKE_CURRENT_SOURCE_DIR}/ldscript/stm32h750xbram-rom.ld
	)

set_target_properties(${BOOT_RELEASE_TARGET}
	PROPERTIES
	LINK_FLAGS
	"-u symbols_table -T${CMAKE_CURRENT_SOURCE_DIR}/ldscript/stm32h750xb-rom.ld"
	)

target_compile_definitions(${BOOT_RELEASE_TARGET}
	PRIVATE
	_IS_BOOT=1
	_IS_FLASH=0
	_IS_RAM=0
	)

target_sources(${FLASH_DEBUG_TARGET}
	PRIVATE
	${CMAKE_CURRENT_SOURCE_DIR}/ldscript/stm32h750xb-external.ld
	)

set_target_properties(${FLASH_DEBUG_TARGET}
	PROPERTIES
	LINK_FLAGS
	"-u symbols_table -T${CMAKE_CURRENT_SOURCE_DIR}/ldscript/stm32h750xb-external.ld"
	)

target_compile_definitions(${FLASH_DEBUG_TARGET}
	PRIVATE
	_IS_BOOT=0
	_IS_FLASH=1
	_IS_RAM=0
	)

target_sources(${FLASH_DEBUG_TARGET}
	PRIVATE
	${CMAKE_CURRENT_SOURCE_DIR}/ldscript/stm32h750xbram-rom.ld
	)

set_target_properties(${RAM_DEBUG_TARGET}
	PROPERTIES
	LINK_FLAGS
	"-u symbols_table -T${CMAKE_CURRENT_SOURCE_DIR}/ldscript/stm32h750xbram-rom.ld"
	)

target_compile_definitions(${RAM_DEBUG_TARGET}
	PRIVATE
	_IS_BOOT=0
	_IS_FLASH=0
	_IS_RAM=1
	)

set(LIBRARIES fatfs sgfx mbedtls_kernel lwip)

sos_sdk_bsp("${BOOT_RELEASE_OPTIONS}" ${HARDWARE_ID} 0x08000000 StratifyOS_stm32h750xx "${LIBRARIES}")
sos_sdk_bsp("${RAM_DEBUG_OPTIONS}" ${HARDWARE_ID} 0x24000000 StratifyOS_stm32h750xx "${LIBRARIES}")
sos_sdk_bsp("${FLASH_DEBUG_OPTIONS}" ${HARDWARE_ID} 0x90000000 StratifyOS_stm32h750xx "${LIBRARIES}")
```
