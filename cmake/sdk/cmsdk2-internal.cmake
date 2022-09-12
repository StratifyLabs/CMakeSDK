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

  set(REQUIRED_ARGS NAME CONFIG ARCH RESULT BUILD_FOLDER)
  foreach(VALUE ${REQUIRED_ARGS})
    if(NOT ARGS_${VALUE})
      message(FATAL_ERROR "cmsdk2_update_target_for_architecture requires ${VALUE}")
    endif()
  endforeach()

  set(TMP_TARGET ${ARGS_NAME})
  set(TMP_INSTALL ${ARGS_NAME})
  set(TMP_NO_CONFIG ${ARGS_NAME})
  set(TMP_NO_NAME "")

  string(COMPARE EQUAL "${ARGS_OPTION}" "" OPTION_MISSING)

  if(NOT OPTION_MISSING)
    set(TMP_OPTION ${ARGS_OPTION})
    set(TMP_TARGET ${TMP_TARGET}_${TMP_OPTION})
    set(TMP_NO_CONFIG ${TMP_NO_CONFIG}_${TMP_OPTION})
    set(TMP_INSTALL ${TMP_INSTALL}_${TMP_OPTION})
    set(TMP_NO_NAME ${OPTION_NAME}_)
  else()
    set(TMP_OPTION "OPTION_EMPTY")
  endif()

  if(NOT CONFIG_NAME STREQUAL "__none__")
    set(TMP_CONFIG ${ARGS_CONFIG})
  else()
    set(TMP_CONFIG "release")
  endif()

  set(TMP_INSTALL ${TMP_INSTALL}_${TMP_CONFIG})

  set(TMP_TARGET ${TMP_TARGET}_${TMP_CONFIG})
  set(TMP_NO_NAME ${TMP_NO_NAME}${TMP_CONFIG})

  set(${ARGS_RESULT} ${TMP_TARGET}_${ARGS_ARCH} PARENT_SCOPE)
  set(${ARGS_BUILD_FOLDER} build_${TMP_NO_NAME}_${ARGS_ARCH} PARENT_SCOPE)

endfunction()