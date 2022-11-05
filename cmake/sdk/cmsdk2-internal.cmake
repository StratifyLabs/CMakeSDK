macro(cmsdk2_internal_startup)
  set(CMSDK_VERSION 2.1.4 CACHE INTERNAL "Set CMSDK Version")
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
  set(ONE_VALUE_ARGS NAME OPTION CONFIG ARCH RESULT RESULT_NO_ARCH BUILD_FOLDER BUILD_FOLDER_NO_ARCH SUFFIX)
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

  set(BUILD_OUTPUT_NAME_NO_ARCH ${BUILD_OUTPUT_NAME}_${ARGS_CONFIG})
  set(BUILD_OUTPUT_NAME ${BUILD_OUTPUT_NAME_NO_ARCH}_${ARGS_ARCH})
  set(TARGET_CONFIG_NAME ${TARGET_NAME}_${ARGS_CONFIG})
  set(TARGET_NAME ${TARGET_CONFIG_NAME}_${ARGS_ARCH})
  if(ARGS_SUFFIX)
    set(TARGET_NAME ${TARGET_NAME}${ARGS_SUFFIX})
  endif()

  if(ARGS_RESULT_NO_ARCH)
    set(${ARGS_RESULT_NO_ARCH} ${TARGET_CONFIG_NAME}${ARGS_SUFFIX} PARENT_SCOPE)
  endif()

  set(${ARGS_RESULT} ${TARGET_NAME} PARENT_SCOPE)
  if(ARGS_BUILD_FOLDER_NO_ARCH)
    set(${ARGS_BUILD_FOLDER_NO_ARCH} ${BUILD_OUTPUT_NAME_NO_ARCH} PARENT_SCOPE)
  endif()
  if(ARGS_BUILD_FOLDER)
    set(${ARGS_BUILD_FOLDER} ${BUILD_OUTPUT_NAME} PARENT_SCOPE)
  endif()

endfunction()

macro(cmsdk2_internal_get_target_components TARGET)
  get_target_property(NAME ${TARGET} CMSDK_PROPERTY_NAME)
  get_target_property(OPTION ${TARGET} CMSDK_PROPERTY_OPTION)
  get_target_property(CONFIG ${TARGET} CMSDK_PROPERTY_CONFIG)
  get_target_property(ARCH ${TARGET} CMSDK_PROPERTY_ARCH)
  get_target_property(TARGET_BUILD_FOLDER ${TARGET} CMSDK_PROPERTY_BUILD_FOLDER)
  get_target_property(SUFFIX ${TARGET} CMSDK_PROPERTY_SUFFIX)
endmacro()

macro(cmsdk2_internal_parse_arguments)
  cmake_parse_arguments(
    INPUT_ARGS
    ""
    INTERNAL_FUNCTION_NAME
    "OPTIONS;REQUIRED;ONE_VALUE;MULTI_VALUE;ARGUMENTS"
    ${ARGV})

  if(NOT INPUT_ARGS_ARGUMENTS)
    message(FATAL_ERROR "cmsdk2_internal_parse_arguments requires ARGUMENTS")
  endif()
    if(NOT INPUT_ARGS_REQUIRED)
    message(FATAL_ERROR "cmsdk2_internal_parse_arguments requires REQUIRED")
  endif()

  if(INPUT_ARGS_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "cmsdk2_internal_parse_arguments has unparsed arguments ${INPUT_ARGS_UNPARSED_ARGUMENTS}")
  endif()

  cmake_parse_arguments(
    ARGS
    "${INPUT_ARGS_OPTIONS}"
    "${INPUT_ARGS_ONE_VALUE}"
    "${INPUT_ARGS_MULTI_VALUE}"
    ${INPUT_ARGS_ARGUMENTS})

  foreach(VALUE ${INPUT_ARGS_REQUIRED})
    if(NOT ARGS_${VALUE})
      message(FATAL_ERROR "${INPUT_ARGS_INTERNAL_FUNCTION_NAME} requires ${VALUE}")
    endif()
  endforeach()

  if(ARGS_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "${INPUT_ARGS_INTERNAL_FUNCTION_NAME} has unparsed arguments ${ARGS_UNPARSED_ARGUMENTS}")
  endif()
endmacro()


