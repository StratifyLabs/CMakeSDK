cmake_minimum_required (VERSION 3.12)

if(DEFINED ENV{CMAKE_SDK_PATH})
	set(CMAKE_SDK_PATH $ENV{CMAKE_SDK_PATH})
endif()

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_MODULE_PATH}/cmake-sdk-toolchain.cmake)
include(cmake-sdk)

project(CMakeSDK CXX C)


if(SOS_IS_LINK)
	set(CMAKE_DEST cmake)
else()
	set(CMAKE_DEST ../cmake)
endif()

install(DIRECTORY cmake/ DESTINATION ${CMAKE_DEST})
install(DIRECTORY include/ DESTINATION include)


