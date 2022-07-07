cmake_minimum_required (VERSION 3.12)

if(NOT DEFINED CMSDK_LOCAL_PATH)
	message(FATAL_ERROR "CMSDK_LOCAL_PATH must be provided")
endif()

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_MODULE_PATH}/cmsdk-toolchain.cmake)
include(cmsdk)

project(CMakeSDK CXX C)


if(CMSDK_IS_LINK)
	set(CMAKE_DEST cmake)
else()
	set(CMAKE_DEST ../cmake)
endif()

install(DIRECTORY cmake/ DESTINATION ${CMAKE_DEST})
install(DIRECTORY include/ DESTINATION include)


