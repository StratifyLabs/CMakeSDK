
set(BUILD_DIR cmake_link)
set(SDK_DIRECTORY ${CMSDK_LOCAL_PATH}/..)
set(CMAKESDK_DIRECTORY ${SDK_DIRECTORY}/dependencies/CMakeSDK)


execute_process(
  COMMAND cmake .. -DCMSDK_LOCAL_PATH=${CMSDK_LOCAL_PATH}
  WORKING_DIRECTORY ${CMAKESDK_DIRECTORY}/${BUILD_DIR}
  RESULT_VARIABLE CMSDK_CMAKE_RESULT
)

if(${CMSDK_CMAKE_RESULT})
  message(FATAL_ERROR "Failed to run cmake for CMakeSDK project")
endif()

execute_process(
  COMMAND cmake --build . --target install
  WORKING_DIRECTORY ${CMAKESDK_DIRECTORY}/${BUILD_DIR}
  RESULT_VARIABLE CMSDK_INSTALL_RESULT
)

if(${CMSDK_INSTALL_RESULT})
  message(FATAL_ERROR "Failed to install CMakeSDK project")
endif()

file(REMOVE_RECURSE ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR})
file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR})

if(IS_BUILD_AND_TEST)
  message(STATUS "Build and run API Tests")

  execute_process(
    COMMAND cmake -DSDK_IS_TEST=ON ..
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR}
    RESULT_VARIABLE CMSDK_RESULT
  )

  if(${CMSDK_RESULT})
    message(FATAL_ERROR "Failed to run CMake")
  endif()

  execute_process(
    COMMAND cmake --build . --target all -- -j8
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR}
    RESULT_VARIABLE BUILD_SDK_RESULT
  )

  if(${BUILD_SDK_RESULT})
    message(FATAL_ERROR "Failed to build")
  endif()

  execute_process(
    COMMAND cmake --build . --target API_test -- -j8
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR}
    RESULT_VARIABLE BUILD_API_TEST_RESULT
  )

  if(${BUILD_API_TEST_RESULT})
    message(FATAL_ERROR "Failed to build API test")
  endif()

  execute_process(
    COMMAND ctest -VV
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR}
    RESULT_VARIABLE TEST_OUTPUT_RESULT
  )

  if(NOT ${TEST_OUTPUT_RESULT} EQUAL "0")
    message(FATAL_ERROR "Test failed to complete successfully")
  endif()

endif()