

if(NOT DEFINED CMSDK_SDK_PATH)
  message(FATAL_ERROR "CMSDK_SDK_PATH must be provided")
endif()

set(SOURCE_DIRECTORY ${CMSDK_SDK_PATH}/dependencies/CMakeSDK)
set(LOCAL_PATH ${CMSDK_SDK_PATH}/local)
set(BUILD_DIR cmake_link)
set(BUILD_DIR_PATH ${SOURCE_DIRECTORY}/${BUILD_DIR})

file(REMOVE_RECURSE ${BUILD_DIR_PATH})
file(MAKE_DIRECTORY ${BUILD_DIR_PATH})

message(STATUS "Running cmake in ${SOURCE_DIRECTORY} using local path: ${LOCAL_PATH}")

execute_process(
  COMMAND cmake .. -DCMSDK_LOCAL_PATH=${LOCAL_PATH}
  WORKING_DIRECTORY ${SOURCE_DIRECTORY}/${BUILD_DIR}
  RESULT_VARIABLE CMSDK_CMAKE_RESULT
)

if(${CMSDK_CMAKE_RESULT})
  message(FATAL_ERROR "Failed to run cmake for CMakeSDK project")
endif()

message(STATUS "Running build install in ${SOURCE_DIRECTORY}")

execute_process(
  COMMAND cmake --build . --target install
  WORKING_DIRECTORY ${SOURCE_DIRECTORY}/${BUILD_DIR}
  RESULT_VARIABLE CMSDK_INSTALL_RESULT
)

if(${CMSDK_INSTALL_RESULT})
  message(FATAL_ERROR "Failed to install CMakeSDK project")
endif()

file(REMOVE_RECURSE ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR})
file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR})