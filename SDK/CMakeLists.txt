cmake_minimum_required (VERSION 3.12)

if(NOT SOS_SDK_PATH)
	set(SOS_SDK_PATH $ENV{SOS_SDK_PATH})
endif()

set(CMAKE_MODULE_PATH ${SOS_SDK_PATH}/Tools/gcc/cmake)
set(CMAKE_TOOLCHAIN_FILE ${SOS_SDK_PATH}/Tools/gcc/cmake/sos-toolchain.cmake)

message("MODULE PATHS: ${CMAKE_MODULE_PATH}")

include(sos-sdk)

project(SDK)

set(IS_SDK TRUE CACHE INTERNAL "Build SDK projects")


macro(sdk_add_subdirectory NAME)
	add_subdirectory(../${NAME} ${NAME})
	#	include(${CMAKE_CURRENT_SOURCE_DIR}/../${NAME}/library/${NAME}.cmake)
endmacro()

include(CTest)
add_subdirectory(../API API)
include(${CMAKE_CURRENT_SOURCE_DIR}/../API/libraries/API.cmake)

sdk_add_subdirectory(StratifyOS)

sdk_add_subdirectory(InetAPI)
sdk_add_subdirectory(CryptoAPI)
sdk_add_subdirectory(JsonAPI)
sdk_add_subdirectory(ChartAPI)
sdk_add_subdirectory(ReportAPI)
sdk_add_subdirectory(CloudAPI)
sdk_add_subdirectory(SwdAPI)
if(SOS_IS_LINK)
	sdk_add_subdirectory(ServiceAPI)
	sdk_add_subdirectory(UsbAPI)
endif()
sdk_add_subdirectory(SosAPI)
sdk_add_subdirectory(HalAPI)
sdk_add_subdirectory(UxAPI)
if(SOS_IS_ARM)
	sdk_add_subdirectory(ToolboxAPI)
endif()



