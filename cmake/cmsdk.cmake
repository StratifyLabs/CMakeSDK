include(${CMAKE_CURRENT_LIST_DIR}/sdk/cmsdk-variables.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/sdk/cmsdk-internal.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/sdk/cmsdk2-internal.cmake)

cmsdk_internal_startup()
cmsdk2_internal_startup()

function(cmsdk_pull PROJECT_PATH)
  execute_process(COMMAND ${CMSDK_SDK_GIT_EXEC} pull WORKING_DIRECTORY ${PROJECT_PATH} OUTPUT_VARIABLE OUTPUT RESULT_VARIABLE RESULT)
  message(STATUS "git pull " ${PROJECT_PATH} "\n" ${OUTPUT})
  if(RESULT)
    message(WARNING " Failed to pull " ${PROJECT_PATH})
  endif()
endfunction()

function(cmsdk_git_clone_or_pull_branch BASE_DIRECTORY NAME REPOSITORY BRANCH)
  message(STATUS "Checking existence of ${BASE_DIRECTORY}/${NAME}")
  if(NOT EXISTS ${BASE_DIRECTORY}/${NAME})
    message(STATUS "Need to clone for the first call to cmake")
    execute_process(
      COMMAND git clone --branch ${BRANCH} ${REPOSITORY}
      WORKING_DIRECTORY ${BASE_DIRECTORY}
    )
  endif()
  add_custom_target(cmsdk_pull_${NAME}
    COMMAND git pull
    WORKING_DIRECTORY ${BASE_DIRECTORY}/${NAME})
  add_custom_target(cmsdk_checkout_${NAME}
    COMMAND git checkout ${BRANCH}
    WORKING_DIRECTORY ${BASE_DIRECTORY}/${NAME}
    DEPENDS cmsdk_pull_${NAME})
  if(CMSDK_PULL_TARGET)
    add_dependencies(${CMSDK_PULL_TARGET} cmsdk_checkout_${NAME})
  endif()
endfunction()

function(cmsdk2_git_clone_or_pull_branch)
  set(OPTIONS "")
  set(PREFIX ARGS)
  set(ONE_VALUE_ARGS WORKING_DIRECTORY NAME REPOSITORY BRANCH)
  set(MULTI_VALUE_ARGS "")
  cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")
  foreach(VALUE ${ONE_VALUE_ARGS})
    if(NOT ARGS_${VALUE})
      message(FATAL_ERROR "cmsdk2_git_clone_or_pull_branch requires ${VALUE}")
    endif()
  endforeach()
  cmsdk_git_clone_or_pull_branch(${ARGS_WORKING_DIRECTORY} ${ARGS_NAME} ${ARGS_REPOSITORY} ${ARGS_BRANCH})
endfunction()

function(cmsdk_add_subdirectory INPUT_LIST DIRECTORY)
  add_subdirectory(${DIRECTORY})
  set(INPUT_SOURCES ${${INPUT_LIST}})
  set(TEMP_SOURCES "")
  foreach(entry ${SOURCES})
    list(APPEND TEMP_SOURCES ${DIRECTORY}/${entry})
  endforeach()
  list(APPEND TEMP_SOURCES ${INPUT_SOURCES})
  set(${INPUT_LIST} ${TEMP_SOURCES} PARENT_SCOPE)
endfunction()

function(cmsdk_add_out_of_source_directory INPUT_LIST DIRECTORY BINARY_DIRECTORY)
  add_subdirectory(${DIRECTORY} ${BINARY_DIRECTORY})
  set(INPUT_SOURCES ${${INPUT_LIST}})
  set(TEMP_SOURCES "")
  foreach(entry ${SOURCES})
    list(APPEND TEMP_SOURCES ${DIRECTORY}/${entry})
  endforeach()
  list(APPEND TEMP_SOURCES ${INPUT_SOURCES})
  set(${INPUT_LIST} ${TEMP_SOURCES} PARENT_SCOPE)
endfunction()

function(cmsdk_git_status PROJECT_PATH)
  message(STATUS "GIT STATUS OF " ${PROJECT_PATH})
  execute_process(COMMAND ${CMSDK_SDK_GIT_EXEC} status WORKING_DIRECTORY ${PROJECT_PATH} RESULT_VARIABLE RESULT)
endfunction()

function(cmsdk_clone REPO_URL WORKSPACE_PATH)
  execute_process(COMMAND ${CMSDK_SDK_GIT_EXEC} clone ${REPO_URL} WORKING_DIRECTORY ${WORKSPACE_PATH} OUTPUT_VARIABLE OUTPUT RESULT_VARIABLE RESULT)
  message(STATUS "git clone " ${REPO_URL} to ${WORKSPACE_PATH} "\n" ${OUTPUT})
  if(RESULT)
    message(FATAL_ERROR " Failed to clone " ${PROJECT_PATH})
  endif()
endfunction()

function(cmsdk_clone_or_pull PROJECT_PATH REPO_URL WORKSPACE_PATH)
  #if ${PROJECT_PATH} directory doesn't exist -- clone from the URL
  if(EXISTS ${PROJECT_PATH}/.git)
    message(STATUS ${PROJECT_PATH} " already exists: pulling")
    cmsdk_pull(${PROJECT_PATH})
  else()
    file(REMOVE_RECURSE ${PROJECT_PATH})
    message(STATUS ${PROJECT_PATH} " does not exist: cloning")
    cmsdk_clone(${REPO_URL} ${WORKSPACE_PATH})
  endif()
endfunction()

function(cmsdk_checkout PROJECT_PATH GIT_PATH)
  execute_process(COMMAND ${CMSDK_SDK_GIT_EXEC} checkout ${GIT_PATH} WORKING_DIRECTORY ${PROJECT_PATH} OUTPUT_VARIABLE OUTPUT RESULT_VARIABLE RESULT)
  message(STATUS "git checkout " ${GIT_PATH} " in " ${PROJECT_PATH} "\n" ${OUTPUT})
  if(RESULT)
    message(FATAL_ERROR " Failed to checkout " ${PROJECT_PATH} ${GIT_PATH})
  endif()
endfunction()

function(cmsdk_copy_target SOURCE_TARGET DEST_TARGET)
  cmsdk_internal_shared_properties()
  foreach(PROPERTY ${CMSDK_SHARED_PROPERTIES})
    string(REPLACE "<CONFIG>" "${CMAKE_BUILD_TYPE}" prop ${PROPERTY})
    get_property(PROPERTY_VALUE TARGET ${SOURCE_TARGET} PROPERTY ${PROPERTY} SET)
    if(PROPERTY_VALUE)
      get_target_property(PROPERTY_VALUE ${SOURCE_TARGET} ${PROPERTY})
      set_property(TARGET ${DEST_TARGET} PROPERTY ${PROPERTY} ${PROPERTY_VALUE})
    endif()
  endforeach(PROPERTY)
endfunction()

function(cmsdk_add_test NAME OPTION CONFIG)
  string(COMPARE EQUAL ${OPTION} "" OPTION_IS_EMPTY)
  if(OPTION_IS_EMPTY)
    set(EXEC_NAME ${NAME})
    set(DIR_NAME build)
  else()
    set(EXEC_NAME ${NAME}_${OPTION})
    set(DIR_NAME build_${OPTION})
  endif()
  set(EXEC_NAME ${EXEC_NAME}_${CONFIG})
  set(TARGET_NAME ${EXEC_NAME}_link.elf)
  get_target_property(TARGET_BINARY_DIR ${TARGET_NAME} RUNTIME_OUTPUT_DIRECTORY)
  message(STATUS "CMSDK - Add test ${TARGET_BINARY_DIR}/${TARGET_NAME}")
  add_test(NAME ${NAME}_${CONFIG}
    COMMAND "${TARGET_BINARY_DIR}/${TARGET_NAME}" --api)
  set_tests_properties(
    ${NAME}_${CONFIG}
    PROPERTIES
    PASS_REGULAR_EXPRESSION "___finalResultPass___")
endfunction()

function(cmsdk_exclude_arch_from_all TARGET ARCH_LIST)
  foreach(ARCH ${ARCH_LIST})
    set_target_properties(${TARGET}_${ARCH}
      PROPERTIES EXCLUDE_FROM_ALL ON)
  endforeach()
endfunction()

macro(cmsdk_include_target TARGET CONFIG_LIST)
  if(CMSDK_IS_ARM)
    set(ARCH_LIST ${CMSDK_ARCH} ${CMSDK_ARCH_LIST})
  else()
    set(ARCH_LIST link)
  endif()
  foreach(CONFIG ${CONFIG_LIST})
    foreach(ARCH ${ARCH_LIST})
      include(${TARGET}_${CONFIG}_${ARCH})
    endforeach(ARCH)
  endforeach(CONFIG)
endmacro()

include(${CMAKE_CURRENT_LIST_DIR}/sdk/cmsdk-app.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/sdk/cmsdk-bsp.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/sdk/cmsdk-lib.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/sdk/cmsdk2.cmake)




