cmake_minimum_required (VERSION 3.10)

include(ExternalProject)

if(NOT SOS_SDK_PATH)
	set(SOS_SDK_PATH $ENV{SOS_SDK_PATH})
endif()

set(CMAKE_MODULE_PATH ${SOS_SDK_PATH}/Tools/gcc/cmake)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_MODULE_PATH}/sos-toolchain.cmake)
include(sos-sdk)

project(MySDK CXX C ASM)

ExternalProject_Add(API GIT_REPOSITORY https://github.com/StratifyLabs/API.git)
ExternalProject_Add(JsonAPI GIT_REPOSITORY https://github.com/StratifyLabs/JsonAPI.git GIT_TAG main)
ExternalProject_Add(InetAPI GIT_REPOSITORY https://github.com/StratifyLabs/InetAPI.git GIT_TAG main)
ExternalProject_Add(CryptoAPI GIT_REPOSITORY https://github.com/StratifyLabs/CryptoAPI.git GIT_TAG main)
ExternalProject_Add(ChartAPI GIT_REPOSITORY https://github.com/StratifyLabs/ChartAPI.git GIT_TAG developmentv4)
ExternalProject_Add(ReportAPI GIT_REPOSITORY https://github.com/StratifyLabs/ReportAPI.git GIT_TAG developmentv4)
ExternalProject_Add(CloudAPI GIT_REPOSITORY https://github.com/StratifyLabs/CloudAPI.git GIT_TAG developmentv4)
ExternalProject_Add(SwdAPI GIT_REPOSITORY https://github.com/StratifyLabs/SwdAPI.git GIT_TAG master)
if(SOS_IS_LINK)
	ExternalProject_Add(ServiceAPI GIT_REPOSITORY https://github.com/StratifyLabs/ServiceAPI.git GIT_TAG developmentv4)
	ExternalProject_Add(UsbAPI GIT_REPOSITORY https://github.com/StratifyLabs/UsbAPI.git GIT_TAG developmentv4)
endif()
ExternalProject_Add(SosAPI GIT_REPOSITORY https://github.com/StratifyLabs/SosAPI.git GIT_TAG main)
ExternalProject_Add(HalAPI GIT_REPOSITORY https://github.com/StratifyLabs/HalAPI.git GIT_TAG main)
ExternalProject_Add(UxAPI GIT_REPOSITORY https://github.com/StratifyLabs/UxAPI.git GIT_TAG main)
