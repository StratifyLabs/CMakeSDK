
message(STATUS "Checking Binary dir ${CMAKE_BINARY_DIR}")

if(CMAKE_BINARY_DIR MATCHES ".*_link")
  set(CMSDK_TOOLCHAIN_BUILD_CONFIG link CACHE INTERNAL "sos build config is link")
elseif(CMAKE_BINARY_DIR MATCHES ".*_arm")
  set(CMSDK_TOOLCHAIN_BUILD_CONFIG arm CACHE INTERNAL "sos build config is arm")
elseif(CMAKE_BINARY_DIR MATCHES ".*_rpi32")
  set(CMSDK_TOOLCHAIN_BUILD_CONFIG rpi32 CACHE INTERNAL "sos build config is rpi32")
elseif(CMAKE_BINARY_DIR MATCHES ".*_rpi64")
  set(CMSDK_TOOLCHAIN_BUILD_CONFIG rpi64 CACHE INTERNAL "sos build config is rpi64")
else()
  message(FATAL_ERROR "No Configuration available build in *_link or *_arm directory")
endif()

string(COMPARE EQUAL ${CMSDK_TOOLCHAIN_BUILD_CONFIG} arm IS_ARM)
string(COMPARE EQUAL ${CMSDK_TOOLCHAIN_BUILD_CONFIG} rpi32 IS_RPI32)
string(COMPARE EQUAL ${CMSDK_TOOLCHAIN_BUILD_CONFIG} rpi64 IS_RPI64)
message(STATUS "Toolchain SDK PATH: ${CMSDK_LOCAL_PATH} ARM:${IS_ARM} RPI32:${IS_RPI32} RPI64:${IS_RPI64}")

if(IS_ARM)
  message(STATUS "Load ARM Cortex M toolchain")
  include(${CMAKE_CURRENT_LIST_DIR}/toolchains/sos-gcc-toolchain.cmake)
elseif(IS_RPI32)
  message(STATUS "Load RPI32 Linux toolchain")
  include(${CMAKE_CURRENT_LIST_DIR}/toolchains/rpi32-linux-gcc-toolchain.cmake)
elseif(IS_RPI64)
  message(STATUS "Load RPI64 Linux toolchain")
  include(${CMAKE_CURRENT_LIST_DIR}/toolchains/rpi64-linux-gcc-toolchain.cmake)
else()
  message(STATUS "Load Host (link) toolchain")
  include(${CMAKE_CURRENT_LIST_DIR}/toolchains/link-toolchain.cmake)
endif()




