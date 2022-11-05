function(cmsdk2_add_sources)
  cmsdk2_internal_parse_arguments(
    INTERNAL_FUNCTION_NAME cmsdk2_add_sources
    ARGUMENTS ${ARGV}
    REQUIRED TARGET DIRECTORY
    ONE_VALUE TARGET DIRECTORY BINARY_DIRECTORY VISIBILITY SOURCES_NAME)

  if(ARGS_VISIBILITY)
    set(VISIBILITY ${ARGS_VISIBILITY})
  else()
    set(VISIBILITY PRIVATE)
  endif()
  if(ARGS_SOURCES_NAME)
    set(SOURCES_NAME ${ARGS_SOURCES_NAME})
  else()
    set(SOURCES_NAME SOURCES)
  endif()
  if(ARGS_BINARY_DIRECTORY)
    add_subdirectory(${ARGS_DIRECTORY} ${ARGS_BINARY_DIRECTORY})
  else()
    add_subdirectory(${ARGS_DIRECTORY})
  endif()
  #SOURCES comes from the CMakeLists.txt file in ${ARGS_DIRECTORY}
  list(TRANSFORM ${SOURCES_NAME} PREPEND ${ARGS_DIRECTORY}/)
  list(APPEND ${ARGS_LIST} ${SOURCES})
  target_sources(${ARGS_TARGET}
    ${VISIBILITY}
    ${SOURCES})
endfunction()

function(cmsdk2_copy_target)
  cmsdk2_internal_parse_arguments(
    INTERNAL_FUNCTION_NAME cmsdk2_copy_target
    ARGUMENTS ${ARGV}
    REQUIRED SOURCE DESTINATION
    ONE_VALUE SOURCE
    MULTI_VALUE DESTINATION)

  foreach(DEST ${ARGS_DESTINATION})
    cmsdk_copy_target(${ARGS_SOURCE} ${DEST})
    get_target_property(TARGET_DEPENDENCIES ${DEST} CMSDK_PROPERTY_DEPENDENCIES)
    get_target_property(CONFIG ${DEST} CMSDK_PROPERTY_CONFIG)
    get_target_property(ARCH ${DEST} CMSDK_PROPERTY_ARCH)
    if(TARGET_DEPENDENCIES)
      foreach(DEPENDENCY ${TARGET_DEPENDENCIES})
        message(STATUS "  ${DEST} -> ${DEPENDENCY}_${CONFIG}_${ARCH}")
        target_link_libraries(${DEST}
          PUBLIC
          ${DEPENDENCY}_${CONFIG}_${ARCH})
      endforeach()
    endif()
  endforeach()
endfunction()

function(cmsdk2_add_test)
  cmsdk2_internal_parse_arguments(
    INTERNAL_FUNCTION_NAME cmsdk2_add_test
    ARGUMENTS ${ARGV}
    REQUIRED TARGET
    ONE_VALUE TARGET)

  cmsdk2_internal_get_target_components(${ARGS_TARGET})
  string(COMPARE EQUAL ${OPTION} "" OPTION_IS_EMPTY)
  if(OPTION)
    set(EXEC_NAME ${NAME}_${OPTION})
    set(DIR_NAME build_${OPTION})
  else()
    set(EXEC_NAME ${NAME})
    set(DIR_NAME build)
  endif()
  set(EXEC_NAME ${EXEC_NAME}_${CONFIG})
  set(TARGET_NAME ${EXEC_NAME}_${ARCH})
  get_target_property(TARGET_BINARY_DIR ${ARGS_TARGET} RUNTIME_OUTPUT_DIRECTORY)
  message(STATUS "add test -> ${TARGET_NAME}")
  add_test(NAME ${NAME}_${CONFIG}
    COMMAND "${TARGET_BINARY_DIR}/${TARGET_NAME}" --api)
  set_tests_properties(
    ${NAME}_${CONFIG}
    PROPERTIES
    PASS_REGULAR_EXPRESSION "___finalResultPass___")
endfunction()

function(cmsdk2_get_arm_arch)
  cmsdk2_internal_parse_arguments(
    INTERNAL_FUNCTION_NAME cmsdk2_get_arm_arch
    ARGUMENTS ${ARGV}
    REQUIRED ARCHITECTURE
    ONE_VALUE ARCHITECTURE FLOAT_OPTIONS FLOAT_DIRECTORY INSTALL_DIRECTORY)

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

function(cmsdk2_check_version)
  cmsdk2_internal_parse_arguments(
    INTERNAL_FUNCTION_NAME cmsdk2_check_version
    ARGUMENTS ${ARGV}
    REQUIRED NAME MINIMUM_VERSION
    ONE_VALUE NAME VERSION MINIMUM_VERSION MAXIMUM_VERSION)

  if(NOT ARGS_VERSION)
    message(STATUS "Dependency ${ARGS_NAME} version variable is empty")
    message(FATAL_ERROR "${ARGS_NAME} version must be at least ${ARGS_MINIMUM_VERSION}")
  else()
    if(ARGS_MAXIMUM_VERSION)
      message(STATUS "  Check ${ARGS_NAME} Version ${ARGS_MINIMUM_VERSION} < ${ARGS_VERSION} < ${ARGS_MAXIMUM_VERSION}")
      if(ARGS_MAXIMUM_VERSION)
        if(${ARGS_VERSION} VERSION_GREATER ${ARGS_MAXIMUM_VERSION})
          message(FATAL_ERROR "Dependency ${ARGS_NAME} version ${ARGS_VERSION} is greater than maximum version ${ARGS_MAXIMUM_VERSION}")
        endif()
      endif()
    else()
      message(STATUS "  Check ${ARGS_NAME} Version ${ARGS_MINIMUM_VERSION} < ${ARGS_VERSION}")
      if(${ARGS_VERSION} VERSION_LESS ${ARGS_MINIMUM_VERSION})
        message(FATAL_ERROR "Dependency ${ARGS_NAME} version ${ARGS_VERSION} is less than minimum version ${ARGS_MINIMUM_VERSION}")
      endif()
    endif()

  endif()

endfunction()

function(cmsdk2_minimum_required MINIMUM_VERSION)
  cmsdk2_check_version(
    NAME CMSDK
    VERSION ${CMSDK_VERSION}
    MINIMUM_VERSION ${MINIMUM_VERSION})
endfunction()

include(${CMAKE_CURRENT_LIST_DIR}/cmsdk2-app.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmsdk2-lib.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmsdk2-bsp.cmake)
