macro(cmsdk2_internal_startup)
  define_property(TARGET PROPERTY CMSDK_PROPERTY_NAME
    BRIEF_DOCS "The base name for the build"
    FULL_DOCS "The base name for the build before the config/arch/etc is added to the target"
    )

  define_property(TARGET PROPERTY CMSDK_PROPERTY_OPTION
    BRIEF_DOCS "The build option name"
    FULL_DOCS "Each build can have an option that causes a -D<option> to get passed to the compiler"
    )

  define_property(TARGET PROPERTY CMSDK_PROPERTY_ARCH
    BRIEF_DOCS "The build architecture"
    FULL_DOCS "Each build can have an associated architecture value (like v7m for cortex-m3)"
    )

  define_property(TARGET PROPERTY CMSDK_PROPERTY_CONFIG
    BRIEF_DOCS "The build configuration: release or debug"
    FULL_DOCS "The build configuration is usually release or debug"
    )

  define_property(TARGET PROPERTY CMSDK_PROPERTY_BUILD_FOLDER
    BRIEF_DOCS "The name of the build folder used for the target"
    FULL_DOCS "The name of the build folder used for the target"
    )
endmacro()

function(cmsdk2_internal_is_arch_enabled)
  set(OPTIONS "")
  set(PREFIX ARGS)
  set(ONE_VALUE_ARGS ARCH RESULT)
  set(MULTI_VALUE_ARGS "")
  cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")

  SET(ARCH_ENABLED OFF)
  cmsdk_internal_arm_arch(${ARGS_ARCH})

  if(CMSDK_ARCH_ARM_ALL)
    set(ARCH_ENABLED ON)
  else()
    if((IS_V7M) AND (CMSDK_ARCH_ARM_V7M))
      set(ARCH_ENABLED ON)
    endif()
    if((IS_V7EM) AND (CMSDK_ARCH_ARM_V7EM))
      set(ARCH_ENABLED ON)
    endif()
    if((IS_V7EM_F4SH) AND (CMSDK_ARCH_ARM_V7EM_F4SH))
      set(ARCH_ENABLED ON)
    endif()
    if((IS_V7EM_F5SH) AND (CMSDK_ARCH_ARM_V7EM_F5SH))
      set(ARCH_ENABLED ON)
    endif()
    if((IS_V7EM_F5DH) AND (CMSDK_ARCH_ARM_V7EM_F5DH))
      set(ARCH_ENABLED ON)
    endif()
  endif()
  set(${ARGS_RESULT} ${ARCH_ENABLED})
endfunction()

function(cmsdk2_internal_build_target_name)
  set(OPTIONS "")
  set(PREFIX ARGS)
  set(ONE_VALUE_ARGS NAME OPTION CONFIG ARCH RESULT BUILD_FOLDER)
  set(MULTI_VALUE_ARGS "")
  cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")

  set(REQUIRED_ARGS NAME CONFIG ARCH RESULT)
  foreach(VALUE ${REQUIRED_ARGS})
    if(NOT ARGS_${VALUE})
      message(FATAL_ERROR "cmsdk2_internal_build_target_name requires ${VALUE}")
    endif()
  endforeach()

  string(COMPARE EQUAL "${ARGS_OPTION}" "" OPTION_MISSING)

  if(ARGS_OPTION)
    set(BUILD_OUTPUT_NAME build_${ARGS_OPTION})
    set(TARGET_NAME ${ARGS_NAME}_${ARGS_OPTION})
  else()
    set(BUILD_OUTPUT_NAME build)
    set(TARGET_NAME ${ARGS_NAME})
  endif()

  set(BUILD_OUTPUT_NAME ${BUILD_OUTPUT_NAME}_${ARGS_CONFIG}_${ARGS_ARCH})
  set(TARGET_NAME ${TARGET_NAME}_${ARGS_CONFIG}_${ARGS_ARCH})

  set(${ARGS_RESULT} ${TARGET_NAME} PARENT_SCOPE)
  if(ARGS_BUILD_FOLDER)
    set(${ARGS_BUILD_FOLDER} ${BUILD_OUTPUT_NAME} PARENT_SCOPE)
  endif()

endfunction()

function(cmsdk2_internal_get_arm_arch)
  set(OPTIONS "")
  set(PREFIX ARGS)
  set(ONE_VALUE_ARGS ARCHITECTURE FLOAT_OPTIONS FLOAT_DIRECTORY INSTALL_DIRECTORY)
  set(MULTI_VALUE_ARGS "")
  cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")

  set(REQUIRED_ARGS ARCHITECTURE)
  foreach(VALUE ${REQUIRED_ARGS})
    if(NOT ARGS_${VALUE})
      message(FATAL_ERROR "cmsdk2_internal_get_arm_arch requires ${VALUE}")
    endif()
  endforeach()

  cmsdk_internal_arm_arch(${ARGS_ARCHITECTURE})

  if(ARGS_FLOAT_OPTIONS)
    set(${ARGS_FLOAT_OPTIONS} ${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS} PARENT_SCOPE)
  endif()

  if(ARGS_FLOAT_DIRECTORY)
    set(${ARGS_FLOAT_DIRECTORY} ${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR} PARENT_SCOPE)
  endif()

  if(ARGS_INSTALL_DIRECTORY)
    set(${ARGS_INSTALL_DIRECTORY} ${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR} PARENT_SCOPE)
  endif()

endfunction()
